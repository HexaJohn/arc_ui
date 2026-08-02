import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/navigation_widgets.dart';
import 'package:arc_ui/src/arc/sidebar_list.dart';
import 'package:flutter/material.dart';

class MaterialNavigationFactory extends NavigationFactory {
  @override
  String get styleName => 'Material Design';

  /// No drawer: `NavigationDrawer` needs a `Scaffold` and a menu affordance to
  /// open it, and an extended `NavigationRail` covers the same expanded-width
  /// case without imposing an app bar on the caller.
  @override
  Set<ArcNavPresentation> get supportedPresentations => {
    ArcNavPresentation.bottomTabs,
    ArcNavPresentation.rail,
    ArcNavPresentation.sidebar,
  };

  /// Material ships no width adaptation of its own — there is no
  /// `NavigationBar.adaptive` and no breakpoint constant anywhere in
  /// `src/material` — so these are the Material 3 window size classes,
  /// applied here.
  @override
  ArcNavPresentation resolvePresentation({
    required double width,
    required ArcNavSource source,
  }) {
    // A data source of arbitrary length can never be a tab strip.
    if (!source.isSectioned) {
      return width < 600 ? ArcNavPresentation.rail : ArcNavPresentation.sidebar;
    }
    if (width < 600) return ArcNavPresentation.bottomTabs;
    if (width < 840) return ArcNavPresentation.rail;
    return ArcNavPresentation.sidebar;
  }

  @override
  Widget createNavigation(ArcNavigationSpec spec) {
    switch (spec.presentation) {
      case ArcNavPresentation.bottomTabs:
        return _MaterialBottomTabs(spec: spec);
      case ArcNavPresentation.rail:
      case ArcNavPresentation.sidebar:
        return _MaterialRail(
          spec: spec,
          extended: spec.presentation == ArcNavPresentation.sidebar,
        );
      case ArcNavPresentation.topTabs:
      case ArcNavPresentation.drawer:
        // Unreachable: the shell checks supportedPresentations first.
        return _MaterialRail(spec: spec, extended: true);
    }
  }
}

class _MaterialBottomTabs extends StatelessWidget {
  const _MaterialBottomTabs({required this.spec});

  final ArcNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    final split = splitForBottomTabs(spec);

    return Scaffold(
      body: spec.body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: split.stripSelectedIndex,
        onDestinationSelected: (tapped) {
          if (split.hasOverflow && tapped == split.moreIndex) {
            _showMore(context, spec, split);
            return;
          }
          spec.onDestinationSelected(split.visible[tapped].index);
        },
        destinations: [
          for (final entry in split.visible)
            NavigationDestination(
              icon: entry.destination.icon ?? kArcFallbackNavIcon,
              selectedIcon: entry.destination.selectedIcon,
              label: entry.destination.label,
            ),
          if (split.hasOverflow)
            const NavigationDestination(
              icon: kArcMoreNavIcon,
              label: 'More',
            ),
        ],
      ),
    );
  }
}

void _showMore(BuildContext context, ArcNavigationSpec spec, ArcTabSplit split) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final entry in split.overflow)
            ListTile(
              leading: entry.destination.icon,
              title: Text(entry.destination.label),
              selected: entry.index == spec.selectedIndex,
              onTap: () {
                Navigator.of(sheetContext).pop();
                spec.onDestinationSelected(entry.index);
              },
            ),
        ],
      ),
    ),
  );
}

class _MaterialRail extends StatelessWidget {
  const _MaterialRail({required this.spec, required this.extended});

  final ArcNavigationSpec spec;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    // NavigationRail is not a Scaffold slot — Material's own docs say to place
    // it beside the body in a Row, so that is what this does.
    return Scaffold(
      body: Row(
        children: [
          _railFor(context),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: spec.body),
        ],
      ),
    );
  }

  Widget _railFor(BuildContext context) {
    final groups = groupDestinations(spec.source);
    final hasGroups = groups.any((g) => g.title != null);

    // NavigationRail has no notion of sections. When the destinations are
    // grouped and there is room to show it, fall back to a plain grouped list
    // rather than silently dropping the structure.
    if (extended && hasGroups) {
      return ArcSidebarList(spec: spec, width: 240);
    }

    final width = extended ? _extendedWidth : _collapsedWidth;

    // The leading widget sits beside the rail rather than inside its `leading`
    // slot. A search field contains a Row with an Expanded child, and the
    // IntrinsicHeight needed to make the rail scrollable asks its subtree for
    // an intrinsic width — a query flex children cannot answer, which throws
    // "non-zero flex but incoming width constraints are unbounded". Keeping it
    // outside the IntrinsicHeight sidesteps that entirely.
    return SizedBox(
      width: width,
      child: Column(
        children: [
          if (spec.leading != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: spec.leading,
            ),
          Expanded(
            child: SingleChildScrollView(
              child: IntrinsicHeight(
                child: NavigationRail(
                  extended: extended,
                  minWidth: _collapsedWidth,
                  minExtendedWidth: _extendedWidth,
                  selectedIndex: spec.selectedIndex,
                  onDestinationSelected: spec.onDestinationSelected,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final destination in flattenToParent(spec.source))
                      NavigationRailDestination(
                        icon: destination.icon ?? kArcFallbackNavIcon,
                        selectedIcon: destination.selectedIcon,
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _collapsedWidth = 80;
  static const double _extendedWidth = 256;
}
