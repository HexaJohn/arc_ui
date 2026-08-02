import 'package:arc_ui/arc_ui.dart';
import 'package:example/views/window_bench.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors main.dart's tree without the macOS window setup, which needs a real
/// platform channel.
Widget _app({Brightness brightness = Brightness.dark}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData.from(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    ),
  ),
  home: ArcTheme(
    child: WindowBench(brightness: brightness, onBrightnessChanged: (_) {}),
  ),
);

void main() {
  testWidgets('the bench builds', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Catches the whole missing-ancestor family: MaterialApp.home supplies no
    // Material, so DropdownButton, Slider and ListTile all assert without a
    // Scaffold above them.
    expect(tester.takeException(), isNull);
    expect(find.text('Window bench'), findsOneWidget);
  });

  testWidgets('every style renders in the bench', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    for (final style in WindowStyleRegistry.availableStyles) {
      // Liquid Glass needs Impeller, which the headless binding has none of.
      if (style == UIStyle.liquid) continue;

      await tester.tap(find.byType(DropdownButton<UIStyle>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_label(style)).last);
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '${_label(style)} threw in the bench',
      );
    }
  });

  group('survives being resized small', () {
    // Sizes chosen around the real failure points: 700 is just under the
    // inspector-docking threshold, 400 is narrower than the docked inspector
    // itself, and 320 squeezes the content pane hard enough that a ListTile
    // leading widget would otherwise consume the whole tile.
    for (final width in [1000.0, 700.0, 520.0, 400.0, 320.0]) {
      testWidgets('at ${width.toInt()}px', (tester) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'the bench threw at ${width}px',
        );
      });
    }

    testWidgets('survives the sidebar collapse animation', (tester) async {
      // The static sweep above only samples settled layouts. Collapsing moves
      // the content inset from zero to the panel's full width, and the frames
      // in between are where a leading widget stops fitting its tile — so the
      // animation has to be stepped through rather than settled past.
      for (final width in [1000.0, 640.0, 480.0]) {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app());
        await tester.pumpAndSettle();

        final toggle = find.byType(ArcIcon);
        if (toggle.evaluate().isEmpty) continue;

        for (var i = 0; i < 2; i++) {
          await tester.tap(toggle.last, warnIfMissed: false);
          // Step the slide rather than settling it, so intermediate insets
          // are actually laid out.
          for (var frame = 0; frame < 10; frame++) {
            await tester.pump(const Duration(milliseconds: 30));
            expect(
              tester.takeException(),
              isNull,
              reason: 'threw mid-animation at ${width}px',
            );
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('narrow layouts still expose the controls', (tester) async {
      tester.view.physicalSize = const Size(500, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();

      // Undocked, the inspector must still be reachable rather than simply
      // gone.
      expect(find.text('Window bench'), findsNothing);
      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Window bench'), findsOneWidget);
    });
  });

  testWidgets('both brightnesses build', (tester) async {
    tester.view.physicalSize = const Size(1800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final brightness in Brightness.values) {
      await tester.pumpWidget(_app(brightness: brightness));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$brightness threw');
    }
  });
}

String _label(UIStyle style) => switch (style) {
  UIStyle.material => 'Material',
  UIStyle.cupertino => 'Cupertino (iOS)',
  UIStyle.fluent => 'Fluent (Windows)',
  UIStyle.macos => 'macOS',
  UIStyle.liquid => 'Liquid Glass',
  UIStyle.windows11 => 'Windows 11',
  UIStyle.custom => 'Custom',
};
