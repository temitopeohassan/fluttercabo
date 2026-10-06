import 'dart:io';

import 'package:cabo_driver/app.dart';
import 'package:cabo_driver/routes.dart';
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

      await tester.pumpWidget(CaboDriverApp(initialRoute: screen.route));
      // Let route transitions finish and the splash timer fire.
      await tester.pump(const Duration(seconds: 3));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('splash advances to the welcome carousel', (tester) async {
    await tester.pumpWidget(const CaboDriverApp());
    expect(find.text('DRIVER'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('going online from home switches to the online map', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const CaboDriverApp(initialRoute: '/home'));
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('GO ONLINE'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text("You're online"), findsOneWidget);
    expect(find.text('Finding trips for you'), findsOneWidget);
  });
}
