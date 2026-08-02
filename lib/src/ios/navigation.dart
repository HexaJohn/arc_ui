import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/navigation_widgets.dart';
import 'package:arc_ui/src/arc/sidebar_list.dart';
import 'package:flutter/cupertino.dart';

class CupertinoNavigationFactory extends NavigationFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Set<ArcNavPresentation> get supportedPresentations => {
    ArcNavPresentation.bottomTabs,
    ArcNavPresentation.topTabs,
    ArcNavPresentation.sidebar,
  };

  /// Cupertino has no width adaptation at all — `CupertinoTabBar` lays out an
  /// unconditional `Row` of `Expanded` children at every size, so an iPad gets
  /// the same phone tab bar stretched across the window. The iPad-shaped top
  /// strip and the sidebar are built here rather than adapted from Flutter,
  /// because Flutter ships neither.
  @override
  ArcNavPresentation resolvePresentation({
    required double width,
    required ArcNavSource source,
  }) {
    if (!source.isSectioned) return ArcNavPresentation.sidebar;
    return width < 768
        ? ArcNavPresentation.bottomTabs
        : ArcNavPresentation.topTabs;
  }

  @override
  Widget createNavigation(ArcNavigationSpec spec) {
    switch (spec.presentation) {
      case ArcNavPresentation.bottomTabs:
        return CupertinoBottomTabs(spec: spec);
      case ArcNavPresentation.topTabs:
        return CupertinoTopTabs(spec: spec);
      case ArcNavPresentation.sidebar:
      case ArcNavPresentation.rail:
      case ArcNavPresentation.drawer:
        return CupertinoSidebarNav(spec: spec);
    }
  }
}

/// Cupertino ships no sidebar control, so this is a plain grouped list on a
/// resolved system background.
class CupertinoSidebarNav extends StatelessWidget {
  const CupertinoSidebarNav({super.key, required this.spec});

  final ArcNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Row(
        children: [
          ArcSidebarList(
            spec: spec,
            width: 240,
            // Resolved here rather than in the factory: CupertinoDynamicColor
            // needs a BuildContext, and factories deliberately receive data
            // only.
            backgroundColor: CupertinoColors.systemGroupedBackground
                .resolveFrom(context),
          ),
          Expanded(child: spec.body),
        ],
      ),
    );
  }
}

/// Bottom tab bar, with the 5-item cap that `CupertinoTabBar` itself does not
/// enforce. UIKit collapses the tail into a "More" tab; Flutter has no such
/// behaviour anywhere in `src/cupertino`, so it is implemented here.
class CupertinoBottomTabs extends StatelessWidget {
  const CupertinoBottomTabs({super.key, required this.spec});

  final ArcNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    final split = splitForBottomTabs(spec);

    return CupertinoPageScaffold(
      child: Column(
        children: [
          Expanded(child: spec.body),
          CupertinoTabBar(
            currentIndex: split.stripSelectedIndex,
            onTap: (tapped) {
              if (split.hasOverflow && tapped == split.moreIndex) {
                _showMoreSheet(context, spec, split);
                return;
              }
              spec.onDestinationSelected(split.visible[tapped].index);
            },
            items: [
              for (final entry in split.visible)
                BottomNavigationBarItem(
                  icon: entry.destination.icon ?? kArcFallbackNavIcon,
                  activeIcon: entry.destination.selectedIcon,
                  label: entry.destination.label,
                ),
              if (split.hasOverflow)
                const BottomNavigationBarItem(
                  icon: kArcMoreNavIcon,
                  label: 'More',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showMoreSheet(
  BuildContext context,
  ArcNavigationSpec spec,
  ArcTabSplit split,
) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (popupContext) => CupertinoActionSheet(
      actions: [
        for (final entry in split.overflow)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.of(popupContext).pop();
              spec.onDestinationSelected(entry.index);
            },
            child: Text(entry.destination.label),
          ),
      ],
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(popupContext).pop(),
        child: const Text('Cancel'),
      ),
    ),
  );
}

/// The iPad-shaped top strip. Flutter has no Cupertino top tab bar, so this is
/// built from `CupertinoSlidingSegmentedControl`, which is the closest native
/// affordance and matches how iPadOS presents a small set of sections.
class CupertinoTopTabs extends StatelessWidget {
  const CupertinoTopTabs({super.key, required this.spec});

  final ArcNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    final destinations = flattenToParent(spec.source);

    return CupertinoPageScaffold(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: spec.selectedIndex,
                  onValueChanged: (value) {
                    if (value != null) spec.onDestinationSelected(value);
                  },
                  children: {
                    for (var i = 0; i < destinations.length; i++)
                      i: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(destinations[i].label),
                      ),
                  },
                ),
              ),
            ),
            Expanded(child: spec.body),
          ],
        ),
      ),
    );
  }
}
