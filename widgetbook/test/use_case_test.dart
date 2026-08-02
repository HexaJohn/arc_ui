import 'package:arc_ui/arc_ui.dart';
import 'package:arc_widgetbook/addons/ui_style_addon.dart';
import 'package:arc_widgetbook/helpers/liquid_glass_guard.dart';
import 'package:arc_widgetbook/helpers/style_matrix.dart';
import 'package:arc_widgetbook/helpers/value_harness.dart';
import 'package:arc_widgetbook/main.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart' show MacosTheme;

/// Renders [child] the way [UIStyleAddon] does inside Widgetbook, so these
/// tests fail if the addon stops providing a theme some factory depends on.
class _AddonHarness extends StatelessWidget {
  const _AddonHarness({required this.style, required this.child});

  final UIStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final addon = UIStyleAddon();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        fluent.FluentLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
        DefaultCupertinoLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      home: Material(
        child: Builder(
          builder: (context) => addon.buildUseCase(context, child, style),
        ),
      ),
    );
  }
}

void main() {
  group('ArcButton', () {
    for (final style in UIStyleAddon.implementedStyles) {
      for (final type in ButtonType.values) {
        testWidgets('renders as ${uiStyleLabel(style)} / ${type.name}', (
          tester,
        ) async {
          var pressed = 0;

          await tester.pumpWidget(
            _AddonHarness(
              style: style,
              child: Center(
                child: LiquidGlassGuard(
                  style: style,
                  builder: (context) => ArcButton(
                    text: 'Button',
                    onPressed: () => pressed++,
                    style: style,
                    type: type,
                  ),
                ),
              ),
            ),
          );

          // The test binding has no Impeller, so Liquid Glass is expected to
          // fall back rather than render a button. Asserting on the fallback
          // keeps these cases meaningful instead of skipped.
          if (style == UIStyle.liquid && !isLiquidGlassSupported) {
            expect(find.text('Needs Impeller'), findsOneWidget);
            expect(tester.takeException(), isNull);
            return;
          }

          expect(find.text('Button'), findsOneWidget);

          await tester.tap(find.text('Button'));
          // settle rather than pump: fluent_ui's buttons leave a press
          // animation timer pending, which trips the test binding's
          // outstanding-timer check.
          await tester.pumpAndSettle();
          expect(pressed, 1);
        });
      }
    }
  });

  group('ArcAppBar', () {
    for (final style in UIStyleAddon.implementedStyles) {
      testWidgets('renders as ${uiStyleLabel(style)}', (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _AddonHarness(
            style: style,
            child: LiquidGlassGuard(
              style: style,
              builder: (context) => ArcAppBar(
                style: style,
                title: const Text('Title'),
                actions: const [Icon(Icons.add, size: 18)],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        if (style == UIStyle.liquid && !isLiquidGlassSupported) {
          expect(find.text('Needs Impeller'), findsOneWidget);
          return;
        }
        expect(find.text('Title'), findsOneWidget);
        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    }
  });

  group('ArcScaffold', () {
    for (final style in UIStyleAddon.implementedStyles) {
      testWidgets('renders as ${uiStyleLabel(style)}', (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _AddonHarness(
            style: style,
            child: LiquidGlassGuard(
              style: style,
              builder: (context) => ArcScaffold(
                style: style,
                appBar: ArcAppBar(style: style, title: const Text('Title')),
                body: const Center(child: Text('Body')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        if (style == UIStyle.liquid && !isLiquidGlassSupported) {
          expect(find.text('Needs Impeller'), findsOneWidget);
          return;
        }
        expect(find.text('Body'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
      });
    }
  });

  group('form controls', () {
    for (final style in UIStyleAddon.implementedStyles) {
      testWidgets('render as ${uiStyleLabel(style)}', (tester) async {
        await tester.pumpWidget(
          _AddonHarness(
            style: style,
            child: LiquidGlassGuard(
              style: style,
              builder: (context) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ArcCheckbox(style: style, value: true, onChanged: (_) {}),
                  ArcSwitch(style: style, value: true, onChanged: (_) {}),
                  SizedBox(
                    width: 200,
                    child: ArcSlider(
                      style: style,
                      value: 0.5,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        if (style == UIStyle.liquid && !isLiquidGlassSupported) {
          expect(find.text('Needs Impeller'), findsOneWidget);
          return;
        }
        // Nothing should have fallen through to the unsupported-style text.
        expect(find.text('(Unsupported Style)'), findsNothing);
      });
    }
  });

  testWidgets('ArcCheckbox toggles through the value harness', (tester) async {
    await tester.pumpWidget(
      _AddonHarness(
        style: UIStyle.material,
        child: Center(
          child: ValueHarness<bool?>(
            initialValue: false,
            builder: (context, value, onChanged) => ArcCheckbox(
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
  });

  test('every registry covers the same styles', () {
    expect(
      ButtonStyleRegistry.availableStyles.toSet(),
      UIStyleAddon.implementedStyles.toSet(),
    );
    expect(
      ScaffoldStyleRegistry.availableStyles.toSet(),
      UIStyleAddon.implementedStyles.toSet(),
    );
    expect(
      AppBarStyleRegistry.availableStyles.toSet(),
      UIStyleAddon.implementedStyles.toSet(),
    );
  });

  testWidgets('the Style Matrix survives a backend without Impeller', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _AddonHarness(
        style: UIStyle.material,
        child: StyleMatrix(
          rows: const ['only'],
          builder: (context, style, rowIndex) =>
              ArcButton(text: 'Button', onPressed: () {}, style: style),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text('Button'),
      findsNWidgets(
        isLiquidGlassSupported
            ? UIStyleAddon.implementedStyles.length
            : UIStyleAddon.implementedStyles.length - 1,
      ),
    );
  });

  testWidgets('the app boots with the generated directories', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ArcWidgetbook());
    await tester.pumpAndSettle();

    expect(find.text('Components'), findsOneWidget);
    expect(find.text('ArcButton'), findsOneWidget);
    expect(find.text('ArcScaffold'), findsOneWidget);
  });

  testWidgets('ArcStyleScope exposes the selected style', (tester) async {
    late UIStyle observed;

    await tester.pumpWidget(
      _AddonHarness(
        style: UIStyle.fluent,
        child: Builder(
          builder: (context) {
            observed = ArcStyleScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(observed, UIStyle.fluent);
  });

  testWidgets('UIStyleAddon mirrors the ambient brightness', (tester) async {
    late Brightness macosBrightness;
    late Brightness fluentBrightness;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Material(
          child: Builder(
            builder: (context) => UIStyleAddon().buildUseCase(
              context,
              Builder(
                builder: (context) {
                  macosBrightness = MacosTheme.of(context).brightness;
                  fluentBrightness = fluent.FluentTheme.of(context).brightness;
                  return const SizedBox();
                },
              ),
              UIStyle.macos,
            ),
          ),
        ),
      ),
    );

    expect(macosBrightness, Brightness.dark);
    expect(fluentBrightness, Brightness.dark);
  });
}
