import 'dart:io';

import 'package:cabo_host/app.dart';
import 'package:cabo_host/routes.dart';
import 'package:cabo_host/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Loads the real app fonts so text measures the same as on a device,
/// which makes the overflow checks meaningful.
Future<void> loadFonts() async {
  Future<ByteData> read(String name) async => ByteData.sublistView(await File('assets/fonts/$name').readAsBytes());

  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    poppins.addFont(read('Poppins-$w.ttf'));
  }
  await poppins.load();
}

/// The trip status each live-trip screen expects.
const tripStatusFor = {
  '/navigate-pickup': 'accepted',
  '/cancel-trip': 'accepted',
  '/arrived-pickup': 'arrived',
  '/verify-rider': 'arrived',
  '/trip-in-progress': 'in_progress',
  '/end-trip': 'in_progress',
  '/emergency': 'in_progress',
  '/collect-payment': 'completed',
  '/trip-summary': 'completed',
  '/rate-rider': 'completed',
};

Future<void> settle(WidgetTester tester, [int pumps = 6]) async {
  for (var i = 0; i < pumps; i++) {
    await tester.pump(const Duration(milliseconds: 700));
  }
}

Future<(FakeApi, AppState)> open(WidgetTester tester, String route, {FakeApi? api}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  api ??= FakeApi(tripStatus: tripStatusFor[route]);
  final state = api.state();
  if (api.tripStatus != null) {
    // The trip in hand, as the app holds it after accepting or completing.
    state.trip = unwrap(await state.api.get('/driver/trips/1')) as Json;
    if (api.tripStatus == 'completed') state.cashToCollect = state.trip!.integer('fare_total');
  }
  await tester.pumpWidget(CaboHostApp(initialRoute: route, state: state));
  await settle(tester);
  addTearDown(state.dispose);
  return (api, state);
}

/// Removes the app so its timers stop before the test ends.
Future<void> close(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(loadFonts);

  test('every screen has a unique route and id', () {
    expect(screens.map((s) => s.route).toSet(), hasLength(screens.length));
    expect(screens.map((s) => s.id).toSet(), hasLength(screens.length));
  });

  for (final screen in screens) {
    testWidgets('${screen.id} ${screen.title} renders live data without errors', (tester) async {
      await open(tester, screen.route);
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Something went wrong'), findsNothing);
      await close(tester);
    });
  }

  testWidgets('splash opens the welcome screen when signed out', (tester) async {
    await open(tester, '/', api: FakeApi(signedIn: false));
    expect(find.text('Get started'), findsNothing); // first page shows "Next"
    expect(find.text('Next'), findsOneWidget);
    await close(tester);
  });

  testWidgets('splash restores a saved session and opens home for an approved host', (tester) async {
    final (api, _) = await open(tester, '/');
    expect(api.calls, contains('GET /driver/me'));
    expect(find.text('GO ONLINE'), findsOneWidget);
    await close(tester);
  });

  testWidgets('signing in asks the API for a code and shows the demo code', (tester) async {
    final (api, _) = await open(tester, '/sign-in', api: FakeApi(signedIn: false));
    await tester.enterText(find.byType(TextField).first, '0801 234 5679');
    await tester.ensureVisible(find.byType(ActionButton));
    await tester.tap(find.byType(ActionButton));
    await settle(tester, 4);
    expect(api.bodies['POST /driver/auth/otp'], {'identifier': '+2348012345679'});
    expect(find.textContaining('123456'), findsWidgets);
    await close(tester);
  });

  testWidgets('going online sends the host position and shows live requests', (tester) async {
    final (api, state) = await open(tester, '/home');
    expect(state.isOnline, isFalse);
    await tester.tap(find.text('GO ONLINE'));
    await settle(tester, 4);
    expect(api.bodies['POST /driver/status'], containsPair('online', true));
    expect(api.bodies['POST /driver/status'], containsPair('lat', isNotNull));
    expect(state.isOnline, isTrue);
    expect(api.calls, contains('GET /driver/trips/available'));
    expect(state.requests, isNotEmpty);
    expect(find.byIcon(Icons.notifications_active_rounded), findsWidgets);
    await close(tester);
  });

  testWidgets('accepting a request opens navigation to the pickup', (tester) async {
    final api = FakeApi();
    final request = ((api.fixtures['GET /driver/trips/available'] as Map)['data'] as List).first as Map<String, dynamic>;
    api.overrides['POST /driver/trips/*/accept'] = {
      'data': {...request, 'status': 'accepted'},
    };
    final state = api.state()..offer = request;
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    addTearDown(state.dispose);
    await tester.pumpWidget(CaboHostApp(initialRoute: '/incoming-request', state: state));
    await settle(tester, 3);
    await tester.tap(find.text('Accept'));
    await settle(tester, 3);
    expect(api.calls, contains('POST /driver/trips/${request['id']}/accept'));
    expect(state.trip?['status'], 'accepted');
    expect(find.text("I've arrived"), findsOneWidget);
    await close(tester);
  });

  testWidgets('the trip starts only with the rider PIN', (tester) async {
    final api = FakeApi(tripStatus: 'arrived');
    api.overrides['POST /driver/trips/*/start'] = {
      'data': {'status': 'in_progress'},
    };
    final (_, state) = await open(tester, '/verify-rider', api: api);
    for (final digit in ['4', '8', '2', '1']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.tap(find.text('Start trip'));
    await settle(tester, 3);
    expect(api.bodies['POST /driver/trips/${state.trip!['id']}/start'], {'pin': '4821'});
    expect(state.trip?['status'], 'in_progress');
    await close(tester);
  });

  testWidgets('earnings come from the API', (tester) async {
    final (api, _) = await open(tester, '/earnings');
    expect(api.calls, contains('GET /driver/earnings'));
    expect(find.text('Payouts'), findsOneWidget);
    await close(tester);
  });
}
