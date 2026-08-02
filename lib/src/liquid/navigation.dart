import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/navigation_widgets.dart';
import 'package:arc_ui/src/ios/navigation.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidNavigationFactory extends NavigationFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Set<ArcNavPresentation> get supportedPresentations => {
    ArcNavPresentation.bottomTabs,
    ArcNavPresentation.topTabs,
    ArcNavPresentation.sidebar,
  };

  /// Same shape as Cupertino — Liquid Glass is a material, not a different
  /// information architecture.
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
        return _LiquidBottomTabs(spec: spec);
      case ArcNavPresentation.topTabs:
        // The top strip is already a floating capsule, which is exactly the
        // shape glass wants; reusing the Cupertino one keeps them in step.
        return CupertinoTopTabs(spec: spec);
      case ArcNavPresentation.sidebar:
      case ArcNavPresentation.rail:
      case ArcNavPresentation.drawer:
        return CupertinoSidebarNav(spec: spec);
    }
  }
}

/// A glass tab bar floating over full-bleed content.
///
/// The body deliberately extends behind the bar rather than being laid out
/// above it: glass only reads as glass when there is something moving behind
/// it, which is the same reason the Liquid Glass scaffold floats its app bar.
class _LiquidBottomTabs extends StatelessWidget {
  const _LiquidBottomTabs({required this.spec});

  final ArcNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    final split = splitForBottomTabs(spec);

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(child: spec.body),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: LiquidGlass(
              settings: kArcLiquidGlassSettings,
              shape: const LiquidRoundedRectangle(
                borderRadius: Radius.circular(28),
              ),
              glassContainsChild: false,
              child: CupertinoTabBar(
                backgroundColor: const Color(0x00000000),
                border: null,
                currentIndex: split.stripSelectedIndex,
                onTap: (tapped) {
                  if (split.hasOverflow && tapped == split.moreIndex) {
                    showLiquidMoreSheet(context, spec, split);
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
            ),
          ),
        ],
      ),
    );
  }
}

/// Overflow sheet for the glass tab bar.
void showLiquidMoreSheet(
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
