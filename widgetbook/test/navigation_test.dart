import 'package:arc_ui/arc_ui.dart';
import 'package:arc_widgetbook/addons/ui_style_addon.dart';
import 'package:arc_widgetbook/helpers/liquid_glass_guard.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Wraps a use case the way UIStyleAddon does inside Widgetbook.
class _Harness extends StatefulWidget {
  const _Harness({
    required this.style,
    required this.source,
    this.presentation,
    this.preserveStacks = true,
  });

  final UIStyle style;
  final ArcNavSource source;
  final ArcNavPresentation? presentation;
  final bool preserveStacks;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  int selected = 0;

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
          builder: (context) => addon.buildUseCase(
            context,
            Center(
              child: SizedBox(
                width: 1200,
                height: 900,
                child: LiquidGlassGuard(
                  style: widget.style,
                  builder: (context) => ArcNavigation(
                    style: widget.style,
                    source: widget.source,
                    presentation: widget.presentation,
                    preserveStacks: widget.preserveStacks,
                    selectedIndex: selected,
                    onDestinationSelected: (i) => setState(() => selected = i),
                    bodyBuilder: (context, destination, index) =>
                        Center(child: Text('page:${destination.label}')),
                  ),
                ),
              ),
            ),
            widget.style,
          ),
        ),
      ),
    );
  }
}

ArcNavSource _sections(int n) => ArcNavSource.sections([
  for (var i = 0; i < n; i++)
    ArcDestination(label: 'D$i', icon: const Icon(Icons.circle_outlined)),
]);

void main() {
  group('renders in every style', () {
    for (final style in UIStyleAddon.implementedStyles) {
      testWidgets(uiStyleLabel(style), (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _Harness(style: style, source: _sections(4)),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        if (style == UIStyle.liquid && !isLiquidGlassSupported) {
          expect(find.text('Needs Impeller'), findsOneWidget);
          return;
        }
        expect(find.text('page:D0'), findsWidgets);
      });
    }
  });

  testWidgets('macOS refuses bottom tabs and falls back to sidebar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _Harness(
        style: UIStyle.macos,
        source: _sections(4),
        // Explicitly ask for something macOS cannot draw.
        presentation: ArcNavPresentation.bottomTabs,
      ),
    );
    await tester.pumpAndSettle();

    // Falls back rather than throwing: the same destination set must stay
    // legal in every style.
    expect(tester.takeException(), isNull);
    expect(find.text('page:D0'), findsWidgets);
  });

  testWidgets('selection survives a switch when stacks are preserved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _Harness(
        style: UIStyle.material,
        source: _sections(3),
        presentation: ArcNavPresentation.bottomTabs,
      ),
    );
    await tester.pumpAndSettle();

    // Every section stays mounted, just offstage — that is precisely what
    // makes returning to a section restore where you were, so the assertion
    // has to look past the offstage boundary.
    expect(find.text('page:D0'), findsOneWidget);
    expect(find.text('page:D2', skipOffstage: false), findsOneWidget);
    expect(find.text('page:D2'), findsNothing);

    await tester.tap(find.text('D2'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('page:D2'), findsOneWidget);
  });

  testWidgets('only the selected section is built when not preserving', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _Harness(
        style: UIStyle.material,
        source: _sections(3),
        presentation: ArcNavPresentation.bottomTabs,
        preserveStacks: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('page:D0'), findsOneWidget);
    // Not merely offstage — never built at all.
    expect(find.text('page:D2', skipOffstage: false), findsNothing);
  });

  group('bottom tab overflow', () {
    test('no split below the cap', () {
      final spec = ArcNavigationSpec(
        source: _sections(4),
        presentation: ArcNavPresentation.bottomTabs,
        selectedIndex: 2,
        onDestinationSelected: (_) {},
        maxBottomTabs: 5,
        body: const SizedBox(),
        bodyBuilder: (_, _, _) => const SizedBox(),
      );

      final split = splitForBottomTabs(spec);
      expect(split.hasOverflow, isFalse);
      expect(split.visible, hasLength(4));
      expect(split.stripSelectedIndex, 2);
    });

    test('caps at maxBottomTabs with More in the last slot', () {
      final spec = ArcNavigationSpec(
        source: _sections(9),
        presentation: ArcNavPresentation.bottomTabs,
        selectedIndex: 1,
        onDestinationSelected: (_) {},
        maxBottomTabs: 5,
        body: const SizedBox(),
        bodyBuilder: (_, _, _) => const SizedBox(),
      );

      final split = splitForBottomTabs(spec);
      expect(split.hasOverflow, isTrue);
      // Four real tabs plus More makes five.
      expect(split.visible, hasLength(4));
      expect(split.overflow, hasLength(5));
      expect(split.moreIndex, 4);
      expect(split.stripSelectedIndex, 1);
      expect(split.selectionIsHidden, isFalse);
      // Overflow entries keep their true destination indices.
      expect(split.overflow.first.index, 4);
      expect(split.overflow.last.index, 8);
    });

    test('a hidden selection highlights More instead', () {
      final spec = ArcNavigationSpec(
        source: _sections(9),
        presentation: ArcNavPresentation.bottomTabs,
        selectedIndex: 7,
        onDestinationSelected: (_) {},
        maxBottomTabs: 5,
        body: const SizedBox(),
        bodyBuilder: (_, _, _) => const SizedBox(),
      );

      final split = splitForBottomTabs(spec);
      expect(split.selectionIsHidden, isTrue);
      expect(split.stripSelectedIndex, split.moreIndex);
    });
  });

  test('data sources never resolve to a tab strip', () {
    final data = ArcNavSource.data(
      count: 500,
      builder: (i) => ArcDestination(label: 'row $i'),
    );

    for (final style in UIStyleAddon.implementedStyles) {
      final factory = NavigationStyleRegistry.getFactory(style)!;
      for (final width in [320.0, 700.0, 1400.0]) {
        final resolved = factory.resolvePresentation(
          width: width,
          source: data,
        );
        expect(
          kFlatPresentations.contains(resolved) &&
              resolved == ArcNavPresentation.bottomTabs,
          isFalse,
          reason:
              '${uiStyleLabel(style)} put a 500-row data source in a tab strip '
              'at ${width}px',
        );
      }
    }
  });

  test('every resolved presentation is one the style supports', () {
    final sections = _sections(5);

    for (final style in UIStyleAddon.implementedStyles) {
      final factory = NavigationStyleRegistry.getFactory(style)!;
      for (final width in [320.0, 600.0, 641.0, 840.0, 1008.0, 1600.0]) {
        final resolved = factory.resolvePresentation(
          width: width,
          source: sections,
        );
        expect(
          factory.supportedPresentations,
          contains(resolved),
          reason:
              '${uiStyleLabel(style)} resolved ${resolved.name} at ${width}px '
              'but does not declare it as supported',
        );
      }
    }
  });

  test('macOS supports exactly one presentation', () {
    expect(
      NavigationStyleRegistry.getFactory(UIStyle.macos)!.supportedPresentations,
      {ArcNavPresentation.sidebar},
    );
  });

  test('flatten to parent keeps index alignment', () {
    final source = ArcNavSource.sections([
      const ArcDestination(label: 'A', children: [ArcDestination(label: 'A1')]),
      const ArcDestination(label: 'B'),
    ]);

    final flat = flattenToParent(source);
    // Children are dropped, never promoted, so position still equals index.
    expect(flat.map((d) => d.label), ['A', 'B']);
  });
}
