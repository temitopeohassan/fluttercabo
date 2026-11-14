import 'dart:io';

import 'package:cabo_guest/app.dart';
import 'package:cabo_guest/routes.dart';
import 'package:cabo_guest/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Loads the real app fonts so text measures the same as on a device,
/// which makes the overflow checks meaningful.
Future<void> loadFonts() async {
  Future<ByteData> read(String name) async =>
      ByteData.sublistView(await File('assets/fonts/$name').readAsBytes());

  final poppins = FontLoader('Poppins');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    poppins.addFont(read('Poppins-$w.ttf'));
  }
  await poppins.load();
  final symbols = FontLoader('NotoSansSymbols')
    ..addFont(read('NotoSansSymbols-Subset.ttf'));
  await symbols.load();
}

/// The trip status each live-trip screen expects.
const tripStatusFor = {
  '/finding-driver': 'requested',
  '/driver-on-way': 'accepted',
  '/chat': 'accepted',
  '/trip-in-progress': 'in_progress',
  '/share-trip': 'in_progress',
  '/add-stop': 'in_progress',
  '/cancel-ride': 'accepted',
  '/sos': 'in_progress',
};

Future<FakeApi> open(WidgetTester tester, String route, {FakeApi? api}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  api ??= FakeApi(tripStatus: tripStatusFor[route]);
  final state = api.state();
  if (api.tripStatus != null) await state.findActiveTrip();
  await tester.pumpWidget(CaboGuestApp(initialRoute: route, state: state));
  // Let responses arrive, route transitions finish and the splash timer fire.
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 700));
  }
  addTearDown(state.dispose);
  return api;
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
    testWidgets(
      '${screen.id} ${screen.title} renders live data without errors',
      (tester) async {
        await open(tester, screen.route);
        expect(tester.takeException(), isNull);
        expect(find.textContaining('Something went wrong'), findsNothing);
        await close(tester);
      },
    );
  }

  testWidgets('splash opens the welcome screen when signed out', (
    tester,
  ) async {
    await open(tester, '/', api: FakeApi(signedIn: false));
    expect(find.text('Get Started'), findsOneWidget);
    await close(tester);
  });

  testWidgets('splash restores a saved session and opens home', (tester) async {
    final api = await open(tester, '/');
    expect(api.calls, contains('GET /rider/me'));
    expect(find.textContaining('Oliver'), findsWidgets);
    await close(tester);
  });

  testWidgets('home shows the signed-in guest and live attractions', (
    tester,
  ) async {
    final api = await open(tester, '/home');
    expect(find.textContaining('Oliver'), findsWidgets);
    expect(api.calls, contains('GET /attractions'));
    await close(tester);
  });

  testWidgets('destinations are limited to tourism locations from the API', (
    tester,
  ) async {
    final api = await open(tester, '/where-to');
    expect(api.calls, contains('GET /places'));
    final allowed = [
      for (final p
          in (api.fixtures['GET /places?kind=attraction'] as Map)['data']
              as List)
        p['name'],
    ];
    final other = [
      for (final p in (api.fixtures['GET /places'] as Map)['data'] as List)
        if (p['kind'] == 'airport' || p['kind'] == 'meeting_point') p['name'],
    ];
    expect(allowed, isNotEmpty);
    expect(other, isNotEmpty);
    expect(find.text(allowed.first as String), findsWidgets);
    for (final name in other) {
      expect(
        find.text(name as String),
        findsNothing,
        reason: '$name is not a tourism location',
      );
    }

    // Choosing one moves on to confirming the pickup, then to live fares.
    await tester.tap(find.text(allowed.first as String).first);
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(find.text('Confirm pickup'), findsWidgets);
    await close(tester);
  });

  testWidgets('wallet shows the balance from the API', (tester) async {
    final api = await open(tester, '/wallet');
    expect(api.calls, contains('GET /rider/wallet'));
    expect(find.text('Cabo Wallet'), findsOneWidget);
    await close(tester);
  });

  testWidgets('signing in asks the API for a code', (tester) async {
    final api = await open(tester, '/email', api: FakeApi(signedIn: false));
    await tester.enterText(find.byType(TextField).first, 'guest@example.com');
    await tester.tap(find.byType(ActionButton));
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 700));
    }
    expect(api.bodies['POST /rider/auth/otp'], {
      'identifier': 'guest@example.com',
    });
    expect(
      find.textContaining('123456'),
      findsWidgets,
      reason: 'the demo code is shown on the code screen',
    );
    await close(tester);
  });
}
