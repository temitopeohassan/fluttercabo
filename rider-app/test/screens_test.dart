import 'dart:io';

import 'package:cabo_rider/app.dart';
import 'package:cabo_rider/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  setUpAll(loadFonts);

  test('every screen has a unique route and id', () {
    expect(screens.map((s) => s.route).toSet(), hasLength(screens.length));
    expect(screens.map((s) => s.id).toSet(), hasLength(screens.length));
  });

  for (final screen in screens) {
    testWidgets('${screen.id} ${screen.title} renders without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(CaboRiderApp(initialRoute: screen.route));
      // Let route transitions finish and the splash timer fire.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('splash advances to the welcome screen', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CaboRiderApp());
    expect(find.text('RIDE'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('ride hailing tile on home opens Where to', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CaboRiderApp(initialRoute: '/home'));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Ride\nHailing'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Where to?'), findsOneWidget);
  });
}
