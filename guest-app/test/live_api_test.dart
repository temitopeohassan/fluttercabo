// Runs the main guest journeys against a real Cabo backend. Skipped unless a
// backend is named:
//
//   flutter test test/live_api_test.dart --dart-define=LIVE_API=http://127.0.0.1:8000/api/v1
//
// The backend must be in demo sign-in mode (CABO_DEMO_OTP set) and seeded.
@TestOn('vm')
library;

import 'package:cabo_guest/api/api_client.dart';
import 'package:cabo_guest/api/location.dart';
import 'package:cabo_guest/api/token_store.dart';
import 'package:cabo_guest/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

const liveApi = String.fromEnvironment('LIVE_API');

void main() {
  test(
    'guest signs in, books a ride to a tourism location and cancels it',
    skip: liveApi.isEmpty ? 'set --dart-define=LIVE_API=<url> to run' : null,
    () async {
      final state = AppState(
        api: ApiClient(baseUrl: liveApi),
        tokens: MemoryTokenStore(),
        location: const FixedLocationService(),
      );
      addTearDown(state.dispose);

      expect(await state.start(), '/welcome');
      await state.requestOtp('oliver.hughes@example.co.uk');
      expect(state.demoCode, isNotNull, reason: 'backend is not in demo sign-in mode');
      await state.verifyOtp(state.demoCode!);
      expect(state.signedIn, isTrue);
      expect(state.firstName, 'Oliver');

      final active = await state.findActiveTrip();
      if (active != null) await state.cancelTrip('Test clean-up');

      final destinations = await state.destinations();
      expect(destinations, isNotEmpty);
      expect(destinations.every((d) => d.str('kind') == 'attraction'), isTrue);

      state.setPickup(await state.currentPlace());
      state.setDropoff(destinations.first);
      await state.loadEstimates();
      expect(state.estimates, isNotEmpty);
      expect(state.estimate!.integer('fare_total'), greaterThan(0));

      final trip = await state.requestRide();
      expect(trip.str('status'), 'requested');
      expect(AppState.tripRoute(trip), '/finding-driver');
      await state.cancelTrip('Plans changed');

      // Anywhere that is not a tourism location is refused.
      state.setDropoff({'name': 'Ikeja City Mall', 'address': 'Ikeja City Mall', 'lat': 6.6142, 'lng': 3.3581});
      await expectLater(state.loadEstimates(), throwsA(isA<ApiException>()));

      final wallet = unwrap(await state.api.get('/rider/wallet')) as Json;
      expect(wallet.integer('balance'), greaterThanOrEqualTo(0));
      await state.signOut();
      expect(state.signedIn, isFalse);
    },
  );
}
