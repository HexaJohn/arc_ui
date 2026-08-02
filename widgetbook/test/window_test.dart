import 'package:arc_ui/arc_ui.dart';
import 'package:arc_widgetbook/addons/ui_style_addon.dart';
import 'package:arc_widgetbook/helpers/liquid_glass_guard.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Harness extends StatefulWidget {
  const _Harness({
    required this.style,
    this.menus = const <ArcMenu>[],
  });

  final UIStyle style;
  final List<ArcMenu> menus;

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
                height: 800,
                child: LiquidGlassGuard(
                  style: widget.style,
                  builder: (context) => ArcWindow(
                    style: widget.style,
                    menus: widget.menus,
                    showSearch: true,
                    navigation: ArcNavSource.sections(const [
                      ArcDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
                      ArcDestination(label: 'Sent', icon: Icon(Icons.send)),
                    ]),
                    selectedIndex: selected,
                    onDestinationSelected: (i) =>
                        setState(() => selected = i),
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

void main() {
  group('renders in every style', () {
    for (final style in UIStyleAddon.implementedStyles) {
      testWidgets(uiStyleLabel(style), (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          _Harness(
            style: style,
            menus: ArcMenus.standard(appName: 'Arc', onNew: () {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        if (style == UIStyle.liquid && !isLiquidGlassSupported) {
          expect(find.text('Needs Impeller'), findsOneWidget);
          return;
        }
        expect(find.text('page:Inbox'), findsWidgets);
      });
    }
  });

  group('menu pruning', () {
    test('platform-provided items are dropped off macOS', () {
      // The test binding reports the host platform; off macOS every provided
      // item must be filtered, because constructing Flutter's
      // PlatformProvidedMenuItem there throws in debug.
      final pruned = pruneMenus([ArcMenus.window()]);

      if (arcHasSystemMenuBar) {
        expect(pruned, hasLength(1));
      } else {
        // The Window menu is entirely platform-provided, so it vanishes rather
        // than surviving as an empty label.
        expect(pruned, isEmpty);
      }
    });

    test('the Edit menu survives everywhere', () {
      // Nothing in Edit is platform-provided — macOS supplies no editing
      // commands at all — so it is hand-built and always present.
      final pruned = pruneMenus([ArcMenus.edit()]);
      expect(pruned, hasLength(1));
      expect(pruned.single.label, 'Edit');
    });

    test('standard() always yields a usable bar', () {
      final menus = pruneMenus(
        ArcMenus.standard(appName: 'Arc', onNew: () {}, onSave: () {}),
      );
      expect(menus.map((m) => m.label), contains('Edit'));
      expect(menus.map((m) => m.label), contains('File'));
      for (final menu in menus) {
        expect(menu.entries, isNotEmpty, reason: '${menu.label} is empty');
      }
    });

    test('File omits commands with no callback', () {
      final file = ArcMenus.file(onNew: () {});
      expect(file.entries, hasLength(1));
      expect((file.entries.single as ArcMenuItem).label, 'New');
    });

    test('Edit items dispatch intents, not callbacks', () {
      final edit = ArcMenus.edit();
      final items = edit.entries
          .whereType<ArcMenuGroup>()
          .expand((g) => g.members)
          .cast<ArcMenuItem>();

      expect(items, isNotEmpty);
      for (final item in items) {
        expect(item.intent, isNotNull, reason: '${item.label} has no intent');
        expect(item.onSelected, isNull);
        expect(item.enabled, isTrue);
      }
    });
  });

  group('sidebar responds to window focus', () {
    Widget panel({required bool isActive}) => MaterialApp(
      home: Material(
        child: ArcWindowFocus(
          isActive: isActive,
          child: const ArcFloatingSidebarSurface(child: SizedBox(width: 240)),
        ),
      ),
    );

    testWidgets('tints when the window is not focused', (tester) async {
      // The panel is meant to disappear into an active window and separate
      // itself from an inactive one. AppKit's own inactive state flattens the
      // material instead, which erases the panel exactly when it should show,
      // so the distinction is drawn in Flutter and asserted here.
      Future<Color?> tintFor({required bool isActive}) async {
        await tester.pumpWidget(panel(isActive: isActive));
        await tester.pumpAndSettle();
        final boxes = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((box) => box.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.border != null)
            .toList();
        return boxes.single.color;
      }

      final active = await tintFor(isActive: true);
      final inactive = await tintFor(isActive: false);

      expect(active!.a, lessThan(inactive!.a));
    });

    test('the default style tints only when inactive', () {
      const style = ArcFloatingSidebarStyle();
      expect(style.tintOpacity, 0);
      expect(style.inactiveTintOpacity, greaterThan(0));
    });

    testWidgets('fades its contents when the window is not focused', (
      tester,
    ) async {
      Future<double> opacityFor({required bool isActive}) async {
        await tester.pumpWidget(panel(isActive: isActive));
        await tester.pumpAndSettle();
        return tester
            .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
            .opacity;
      }

      expect(await opacityFor(isActive: true), 1.0);
      expect(await opacityFor(isActive: false), lessThan(1.0));
    });

    testWidgets('a flat list reserves no chevron column', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<double> labelLeftFor(List<ArcDestination> destinations) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: ArcTheme(
                child: ArcNavigation(
                  style: UIStyle.macos,
                  presentation: ArcNavPresentation.sidebar,
                  source: ArcNavSource.sections(destinations),
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  bodyBuilder: (context, destination, index) =>
                      const SizedBox(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getTopLeft(find.text('Inbox')).dx;
      }

      final flat = await labelLeftFor(const [
        ArcDestination(label: 'Inbox'),
        ArcDestination(label: 'Sent'),
      ]);
      final nested = await labelLeftFor(const [
        ArcDestination(label: 'Inbox'),
        ArcDestination(
          label: 'Sent',
          children: [ArcDestination(label: 'Older')],
        ),
      ]);

      // A list where nothing expands should not be indented for an affordance
      // that never appears.
      expect(flat, lessThan(nested));
    });

    test('the inactive fade is visible but not a blackout', () {
      const style = ArcFloatingSidebarStyle();
      expect(style.inactiveContentOpacity, inExclusiveRange(0.3, 1.0));
    });

    test('panel width clamps to its bounds', () {
      const style = ArcFloatingSidebarStyle();
      expect(style.width, inInclusiveRange(style.minWidth, style.maxWidth));
      expect(style.minWidth, lessThan(style.maxWidth));
    });
  });

  group('sidebar source list', () {
    Widget list(List<ArcDestination> destinations) => MaterialApp(
      home: Material(
        child: ArcTheme(
          child: ArcNavigation(
            style: UIStyle.macos,
            presentation: ArcNavPresentation.sidebar,
            source: ArcNavSource.sections(destinations),
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bodyBuilder: (context, destination, index) => const SizedBox(),
          ),
        ),
      ),
    );

    testWidgets('renders badges', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        list(const [
          ArcDestination(label: 'Inbox', badge: '124'),
          ArcDestination(label: 'Sent'),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('124'), findsOneWidget);
    });

    testWidgets('nests deeper than one level', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        list(const [
          ArcDestination(
            label: 'All Inboxes',
            children: [
              ArcDestination(
                label: 'Exchange',
                children: [ArcDestination(label: 'Focused')],
              ),
            ],
          ),
        ]),
      );
      await tester.pumpAndSettle();

      // Mail nests accounts under All Inboxes and folders under those, so a
      // single level of disclosure is not enough.
      expect(find.text('Focused'), findsOneWidget);

      final root = tester.getTopLeft(find.text('All Inboxes')).dx;
      final child = tester.getTopLeft(find.text('Exchange')).dx;
      final grandchild = tester.getTopLeft(find.text('Focused')).dx;
      expect(child, greaterThan(root));
      expect(grandchild, greaterThan(child));
    });

    testWidgets('a child is selectable in its own right', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      var reportedIndex = -1;
      var reportedChild = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: ArcTheme(
              child: ArcNavigation(
                style: UIStyle.macos,
                presentation: ArcNavPresentation.sidebar,
                source: ArcNavSource.sections(const [
                  ArcDestination(
                    label: 'All Inboxes',
                    children: [ArcDestination(label: 'Work')],
                  ),
                  ArcDestination(label: 'Sent'),
                ]),
                selectedIndex: 0,
                onDestinationSelected: (i) => reportedIndex = i,
                onChildSelected: (parent, child) {
                  reportedIndex = parent;
                  reportedChild = child;
                },
                bodyBuilder: (context, destination, index) => const SizedBox(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      Color? highlightOf(String label) {
        final box = tester.widget<Container>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(Container),
              )
              .first,
        );
        return (box.decoration as BoxDecoration?)?.color;
      }

      // The parent starts selected.
      expect(highlightOf('All Inboxes'), isNotNull);
      expect(highlightOf('Work'), isNull);

      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      // The child now carries the highlight, and the top-level index still
      // goes out so a caller driving a tab strip from the same state stays
      // correct.
      expect(highlightOf('Work'), isNotNull);
      expect(highlightOf('All Inboxes'), isNull);
      expect(reportedIndex, 0);
      expect(reportedChild, 0);
    });

    testWidgets('an explicit icon colour survives selection', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const flagColor = Color(0xFFF09A34);
      await tester.pumpWidget(
        list(const [
          ArcDestination(
            label: 'Orange',
            icon: ArcIcon(ArcIcons.flag, color: flagColor),
          ),
        ]),
      );
      await tester.pumpAndSettle();

      // Row 0 is selected. A coloured flag must stay its own colour rather
      // than being tinted with the accent like a plain glyph.
      final icon = tester.widget<Icon>(find.byType(Icon).first);
      expect(icon.color, flagColor);
    });
  });

  group('system preferences', () {
    Widget list({
      ArcSidebarItemSize? themeSize,
      ArcSidebarItemSize prefSize = ArcSidebarItemSize.medium,
      TextScaler scaler = TextScaler.noScaling,
    }) => MaterialApp(
      home: Material(
        child: ArcSystemPreferences(
          sidebarItemSize: prefSize,
          child: ArcWindowTheme(
            sidebarItemSize: themeSize,
            child: MediaQuery(
              data: MediaQueryData(textScaler: scaler),
              child: ArcTheme(
                child: ArcNavigation(
                  style: UIStyle.macos,
                  presentation: ArcNavPresentation.sidebar,
                  source: ArcNavSource.sections(const [
                    ArcDestination(label: 'Inbox', icon: ArcIcon(ArcIcons.inbox)),
                  ]),
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  bodyBuilder: (context, destination, index) =>
                      const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Future<double> iconSizeIn(WidgetTester tester, Widget app) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      // Measured, not read off the widget: ArcIcon leaves `size` null and
      // takes it from the ambient IconTheme the row installs. Height rather
      // than width, since the icon sits in a fixed-width slot.
      return tester
          .getSize(
            find
                .descendant(
                  of: find.byType(ArcSidebarList),
                  matching: find.byType(Icon),
                )
                .first,
          )
          .height;
    }

    testWidgets('row density follows the system preference', (tester) async {
      final small = await iconSizeIn(
        tester,
        list(prefSize: ArcSidebarItemSize.small),
      );
      final large = await iconSizeIn(
        tester,
        list(prefSize: ArcSidebarItemSize.large),
      );
      expect(large, greaterThan(small));
    });

    testWidgets('an explicit theme size overrides the preference', (
      tester,
    ) async {
      final viaPref = await iconSizeIn(
        tester,
        list(prefSize: ArcSidebarItemSize.large),
      );
      final viaTheme = await iconSizeIn(
        tester,
        list(
          prefSize: ArcSidebarItemSize.large,
          themeSize: ArcSidebarItemSize.small,
        ),
      );
      expect(viaTheme, lessThan(viaPref));
    });

    testWidgets('icons grow with the text scale', (tester) async {
      // Flutter scales a Text by itself; leaving icons and slots fixed would
      // make a larger text size overflow the row instead of growing it.
      final normal = await iconSizeIn(tester, list());
      final scaled = await iconSizeIn(
        tester,
        list(scaler: const TextScaler.linear(1.5)),
      );
      expect(scaled, greaterThan(normal));
    });

    testWidgets('icon growth is clamped', (tester) async {
      // Accessibility scales run far past what a fixed-width sidebar absorbs.
      final huge = await iconSizeIn(
        tester,
        list(scaler: const TextScaler.linear(4)),
      );
      expect(huge, lessThan(ArcSidebarItemSize.medium.iconSize * 2));
    });
  });

  group('inline menu bar', () {
    Widget bar() => MaterialApp(
      home: Material(
        child: Column(
          children: [
            ArcInlineMenuBar(
              menus: ArcMenus.standard(appName: 'Arc Mail', onNew: () {}),
            ),
          ],
        ),
      ),
    );

    testWidgets('spans the full width and starts at the leading edge', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      // MenuBar shrink-wraps, so dropped into a Column it centres — a Windows
      // menu bar belongs against the leading edge.
      expect(tester.getSize(find.byType(ArcInlineMenuBar)).width, 1200);
      expect(tester.getTopLeft(find.text('File')).dx, lessThan(100));
    });

    testWidgets('omits menus it cannot draw in-window', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      // The application menu is entirely platform-provided items, which an
      // in-window bar cannot render — it would open onto nothing.
      expect(find.text('Arc Mail'), findsNothing);
      expect(find.text('File'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });
  });

  group('collapsible sidebar', () {
    Widget nav({required bool collapsible}) => MaterialApp(
      home: Material(
        child: ArcTheme(
          child: ArcWindowTheme(
            floatingSidebar: ArcFloatingSidebarStyle(collapsible: collapsible),
            child: ArcNavigation(
              style: UIStyle.macos,
              presentation: ArcNavPresentation.sidebar,
              source: ArcNavSource.sections(const [
                ArcDestination(label: 'Inbox'),
                ArcDestination(label: 'Sent'),
              ]),
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              bodyBuilder: (context, destination, index) => const SizedBox(),
            ),
          ),
        ),
      ),
    );

    testWidgets('the toggle appears only when collapsible', (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(nav(collapsible: false));
      await tester.pumpAndSettle();
      final withoutToggle = tester.widgetList(find.byType(ArcIcon)).length;

      await tester.pumpWidget(nav(collapsible: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.widgetList(find.byType(ArcIcon)).length,
        greaterThan(withoutToggle),
      );
    });

    testWidgets('collapsing slides the panel away and keeps a way back', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(nav(collapsible: true));
      await tester.pumpAndSettle();

      final openLeft = tester.getTopLeft(find.text('Inbox')).dx;

      await tester.tap(find.byType(ArcIcon).last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Slid off to the side rather than merely hidden, and the control
      // survives so the panel can be brought back.
      expect(tester.getTopLeft(find.text('Inbox')).dx, lessThan(openLeft));
      expect(find.byType(ArcIcon), findsWidgets);

      await tester.tap(find.byType(ArcIcon).last, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Inbox')).dx, closeTo(openLeft, 0.5));
    });

    test('collapsible is on by default', () {
      expect(const ArcFloatingSidebarStyle().collapsible, isTrue);
    });
  });

  group('search placeholder reaches the field', () {
    for (final placement in [
      ArcSearchPlacement.navigationLeading,
      ArcSearchPlacement.windowTrailing,
    ]) {
      testWidgets('${placement.name} shows the caller\'s text', (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: ArcTheme(
                child: ArcWindow(
                  style: UIStyle.macos,
                  showSearch: true,
                  searchPlacement: placement,
                  searchPlaceholder: 'Search mail',
                  navigation: ArcNavSource.sections(const [
                    ArcDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
                    ArcDestination(label: 'Sent', icon: Icon(Icons.send)),
                  ]),
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  bodyBuilder: (context, destination, index) =>
                      const SizedBox(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The default is 'Search'; seeing it would mean the caller's value was
        // dropped somewhere between ArcWindow and the field.
        expect(find.text('Search mail'), findsOneWidget);
        expect(find.text('Search'), findsNothing);
      });
    }

    testWidgets('the titlebar field is larger than the sidebar one', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      Future<double> heightFor(ArcSearchPlacement placement) async {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey(placement),
            home: Material(
              child: ArcTheme(
                child: ArcWindow(
                  style: UIStyle.macos,
                  showSearch: true,
                  searchPlacement: placement,
                  navigation: ArcNavSource.sections(const [
                    ArcDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
                    ArcDestination(label: 'Sent', icon: Icon(Icons.send)),
                  ]),
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  bodyBuilder: (context, destination, index) =>
                      const SizedBox(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        return tester
            .widget<ArcSearchPill>(find.byType(ArcSearchPill))
            .height;
      }

      final sidebar = await heightFor(ArcSearchPlacement.navigationLeading);
      final titlebar = await heightFor(ArcSearchPlacement.windowTrailing);
      expect(titlebar, greaterThan(sidebar));
    });
  });

  group('native menu bar survives remounting', () {
    // The failure this guards: PlatformMenuBar takes a process-wide lock keyed
    // on its BuildContext and frees it in dispose. A hot restart builds the
    // new tree before the old one is disposed, so the lock stays held by a
    // dead context and every later build throws "More than one active
    // PlatformMenuBar detected". Driving setMenus imperatively takes no lock.
    testWidgets('two instances can coexist', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Expanded(
                child: ArcNativeMenuBar(
                  menus: ArcMenus.standard(appName: 'A', onNew: () {}),
                  child: const Text('a'),
                ),
              ),
              Expanded(
                child: ArcNativeMenuBar(
                  menus: ArcMenus.standard(appName: 'B', onNew: () {}),
                  child: const Text('b'),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('remounting does not throw', (tester) async {
      Widget bar(String name) => MaterialApp(
        home: ArcNativeMenuBar(
          menus: ArcMenus.standard(appName: name, onNew: () {}),
          child: Text(name),
        ),
      );

      for (final name in ['first', 'second', 'third']) {
        await tester.pumpWidget(bar(name));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$name threw');
      }
    });

    test('the signature changes only when the menu structure does', () {
      final a = ArcMenus.standard(appName: 'Arc', onNew: () {});
      final b = ArcMenus.standard(appName: 'Arc', onNew: () {});
      // Fresh instances each build; without a structural fingerprint the menu
      // would be re-serialised across the channel on every rebuild.
      expect(ArcNativeMenuBar.signature(a), ArcNativeMenuBar.signature(b));

      final c = ArcMenus.standard(appName: 'Arc', onNew: () {}, onSave: () {});
      expect(
        ArcNativeMenuBar.signature(c),
        isNot(ArcNativeMenuBar.signature(a)),
      );
    });
  });

  group('chrome resolution', () {
    test('iOS and Liquid Glass never show a menu bar', () {
      for (final style in [UIStyle.cupertino, UIStyle.liquid]) {
        final factory = WindowStyleRegistry.getFactory(style)!;
        for (final width in [320.0, 900.0, 1600.0]) {
          expect(
            factory.resolveMenuPresentation(width: width),
            ArcMenuPresentation.none,
            reason: '${uiStyleLabel(style)} offered a menu bar at ${width}px',
          );
        }
      }
    });

    test('native is only chosen where a system menu bar exists', () {
      for (final style in WindowStyleRegistry.availableStyles) {
        final factory = WindowStyleRegistry.getFactory(style)!;
        for (final width in [320.0, 900.0, 1600.0]) {
          final resolved = factory.resolveMenuPresentation(width: width);
          if (resolved == ArcMenuPresentation.native) {
            // Choosing native without a system menu bar would render nothing
            // at all, silently — PlatformMenuBar swallows the failure.
            expect(arcHasSystemMenuBar, isTrue);
          }
        }
      }
    });

    test('Liquid Glass floats search at the bottom on narrow layouts', () {
      final factory = WindowStyleRegistry.getFactory(UIStyle.liquid)!;
      expect(
        factory.resolveSearchPlacement(width: 400),
        ArcSearchPlacement.floatingBottom,
      );
      expect(
        factory.resolveSearchPlacement(width: 1400),
        ArcSearchPlacement.navigationLeading,
      );
    });

    test('every style places search somewhere when asked', () {
      for (final style in WindowStyleRegistry.availableStyles) {
        final factory = WindowStyleRegistry.getFactory(style)!;
        for (final width in [320.0, 900.0, 1600.0]) {
          expect(
            factory.resolveSearchPlacement(width: width),
            isNot(ArcSearchPlacement.none),
            reason: '${uiStyleLabel(style)} dropped search at ${width}px',
          );
        }
      }
    });

    test('window registry covers the same styles as the others', () {
      expect(
        WindowStyleRegistry.availableStyles.toSet(),
        UIStyleAddon.implementedStyles.toSet(),
      );
    });
  });

  testWidgets('search text reaches onSearchChanged', (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final seen = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ArcWindow(
            style: UIStyle.material,
            showSearch: true,
            onSearchChanged: seen.add,
            navigation: ArcNavSource.sections(const [
              ArcDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
              ArcDestination(label: 'Sent', icon: Icon(Icons.send)),
            ]),
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bodyBuilder: (context, destination, index) => const SizedBox(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'hello');
    await tester.pumpAndSettle();

    expect(seen, contains('hello'));
  });
}
