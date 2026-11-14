// Runs a whole ride against a real Cabo backend, from both sides. Skipped
// unless a backend is named:
//
//   flutter test test/live_api_test.dart --dart-define=LIVE_API=http://127.0.0.1:8000/api/v1
//
// The backend must be in demo sign-in mode (CABO_DEMO_OTP set) and seeded.
@TestOn('vm')
library;

import 'package:cabo_host/api/api_client.dart';
import 'package:cabo_host/api/location.dart';
import 'package:cabo_host/api/token_store.dart';
import 'package:cabo_host/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

const liveApi = String.fromEnvironment('LIVE_API');

void main() {
  test(
    'host goes online, accepts a guest request and completes the trip',
    skip: liveApi.isEmpty ? 'set --dart-define=LIVE_API=<url> to run' : null,
    () async {
      // The guest side, to create the request and read the trip PIN.
      final guest = ApiClient(baseUrl: liveApi);
      final otp = await guest.post('/rider/auth/otp', {'identifier': 'amara.okafor@example.com'}) as Json;
      guest.token = (await guest.post('/rider/auth/verify', {
        'identifier': 'amara.okafor@example.com',
        'code': otp.str('debug_code'),
      }) as Json).str('token');
      for (final t in (await guest.get('/rider/trips') as Json).list('data')) {
        if (const {'requested', 'accepted', 'arrived'}.contains(t.str('status'))) {
          await guest.post('/rider/trips/${t.integer('id')}/cancel', {'reason': 'Test clean-up'});
        }
      }

      final state = AppState(
        api: ApiClient(baseUrl: liveApi),
        tokens: MemoryTokenStore(),
        location: const FixedLocationService(),
      );
      addTearDown(state.dispose);
      expect(await state.start(), '/welcome');
      await state.requestOtp('+2348012345679');
      expect(state.demoCode, isNotNull, reason: 'backend is not in demo sign-in mode');
      expect(await state.verifyOtp(state.demoCode!), '/home');
      expect(state.approved, isTrue);
      expect(await state.loadCurrentTrip(), isNull, reason: 'the host already has a trip in hand');

      await state.goOnline();
      expect(state.isOnline, isTrue);

      final place = asJsonList(unwrap(await guest.get('/places', query: {'kind': 'attraction'}))).first;
      final requested = unwrap(
        await guest.post('/rider/trips', {
          'pickup_lat': 6.4268,
          'pickup_lng': 3.4290,
          'pickup_address': 'Eko Hotel & Suites, Victoria Island',
          'dropoff_lat': place.number('lat'),
          'dropoff_lng': place.number('lng'),
          'dropoff_address': place.str('name'),
          'ride_type': 'comfort',
          'payment_method': 'cash',
        }),
      ) as Json;

      await state.loadRequests();
      final offer = state.requests.firstWhere((r) => r.integer('id') == requested.integer('id'));
      expect(offer['pin'], isNull, reason: 'the PIN must never reach the host');

      await state.accept(offer);
      expect(AppState.tripRoute(state.trip), '/navigate-pickup');
      await state.tripAction('arrive');
      expect(AppState.tripRoute(state.trip), '/arrived-pickup');

      await expectLater(state.tripAction('start', {'pin': '0000'}), throwsA(isA<ApiException>()));
      final pin = (unwrap(await guest.get('/rider/trips/${requested.integer('id')}')) as Json).str('pin');
      await state.tripAction('start', {'pin': pin});
      expect(AppState.tripRoute(state.trip), '/trip-in-progress');

      await state.tripAction('complete');
      expect(state.trip!.str('status'), 'completed');
      expect(state.cashToCollect, state.trip!.integer('fare_total'));
      await state.tripAction('collect-cash');
      expect(state.cashToCollect, 0);
      await state.tripAction('rating', {'rating': 5, 'feedback': 'Polite'});
      expect(state.trip!.integer('rider_rating'), 5);

      final earnings = unwrap(await state.api.get('/driver/earnings', query: {'period': 'today'})) as Json;
      expect(earnings.integer('trips'), greaterThan(0));
      final performance = unwrap(await state.api.get('/driver/performance')) as Json;
      expect(performance.integer('completed_trips'), greaterThan(0));

      await state.goOffline();
      await state.signOut();
      expect(state.signedIn, isFalse);
    },
  );
}
