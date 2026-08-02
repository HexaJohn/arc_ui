import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/navigation_widgets.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentNavigationFactory extends NavigationFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  /// No bottom tabs. `BottomNavigation` exists but is completely disconnected
  /// from `NavigationView` — it takes its own incompatible
  /// `BottomNavigationItem` list, `PaneDisplayMode` has no bottom value, and
  /// Fluent's own `auto` never selects one. Offering it would mean abandoning
  /// the native shell.
  @override
  Set<ArcNavPresentation> get supportedPresentations => {
    ArcNavPresentation.topTabs,
    ArcNavPresentation.rail,
    ArcNavPresentation.sidebar,
    ArcNavPresentation.drawer,
  };

  /// Fluent's own breakpoints, verbatim from `NavigationView`'s LayoutBuilder:
  /// an expanded pane at 1008px or greater, an icon-only compact pane from
  /// 641 to 1007, and a minimal hamburger pane below that.
  @override
  ArcNavPresentation resolvePresentation({
    required double width,
    required ArcNavSource source,
  }) {
    if (width >= 1008) return ArcNavPresentation.sidebar;
    if (width > 640) return ArcNavPresentation.rail;
    return ArcNavPresentation.drawer;
  }

  @override
  Widget createNavigation(ArcNavigationSpec spec) => _FluentNav(spec: spec);
}

PaneDisplayMode _modeFor(ArcNavPresentation presentation) {
  switch (presentation) {
    case ArcNavPresentation.topTabs:
      return PaneDisplayMode.top;
    case ArcNavPresentation.rail:
      return PaneDisplayMode.compact;
    case ArcNavPresentation.sidebar:
      return PaneDisplayMode.open;
    case ArcNavPresentation.drawer:
      return PaneDisplayMode.minimal;
    case ArcNavPresentation.bottomTabs:
      return PaneDisplayMode.minimal;
  }
}

class _FluentNav extends StatelessWidget {
  const _FluentNav({required this.spec});

  final ArcNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      pane: NavigationPane(
        selected: spec.selectedIndex,
        onChanged: spec.onDestinationSelected,
        displayMode: _modeFor(spec.presentation),
        // The pane has a purpose-built search slot; using it rather than
        // prepending an item means compact mode swaps in a search icon that
        // expands the pane, which is the real Fluent behaviour.
        autoSuggestBox: spec.leading,
        autoSuggestBoxReplacement: spec.leading == null
            ? null
            : const Icon(FluentIcons.search),
        items: _items(),
      ),
    );
  }

  List<NavigationPaneItem> _items() {
    final groups = groupDestinations(spec.source);
    final out = <NavigationPaneItem>[];

    for (final group in groups) {
      // Headers are safe to interleave: NavigationPane.selected indexes
      // `effectiveItems`, which filters to PaneItem and so skips headers
      // entirely. One PaneItem per destination therefore keeps Fluent's index
      // space identical to the shell's. Headers also render as an empty
      // SizedBox in compact mode, so a rail drops them cleanly.
      if (group.title != null) {
        out.add(PaneItemHeader(header: Text(group.title!)));
      }
      for (final entry in group.items) {
        final destination = entry.destination;
        out.add(
          PaneItem(
            icon: destination.icon ?? kArcFallbackNavIcon,
            title: Text(destination.label),
            // NavigationView owns page construction — it asserts pane XOR
            // content and renders PaneItem.body itself — so unlike the other
            // four styles this one builds bodies rather than taking spec.body.
            // A consequence is that Fluent always keeps every page alive in
            // its PageView, so preserveStacks: false is not honoured here.
            body: Builder(
              builder: (context) =>
                  spec.bodyBuilder(context, destination, entry.index),
            ),
          ),
        );
      }
    }

    return out;
  }
}
