import 'package:arc_ui/src/arc/window.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidWindowFactory extends WindowFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  /// Same as Cupertino: no menu bar concept exists.
  @override
  ArcMenuPresentation resolveMenuPresentation({required double width}) =>
      ArcMenuPresentation.none;

  /// The floating bottom search bar is the iOS 26 pattern, and it is the whole
  /// reason this is custom.
  ///
  /// Flutter ships nothing for it. `CupertinoSliverNavigationBar.search` is
  /// top-anchored only — `NavigationBarBottomMode` refers to the nav bar's own
  /// bottom edge, not the screen's — and its metrics are documented in the SDK
  /// as eyeballed against iOS 17.5, so it will never track iOS 26. On wide
  /// layouts the sidebar's leading slot is still the better home.
  @override
  ArcSearchPlacement resolveSearchPlacement({required double width}) =>
      width < 768
      ? ArcSearchPlacement.floatingBottom
      : ArcSearchPlacement.navigationLeading;

  @override
  Widget createWindow(ArcWindowSpec spec) {
    final search = CupertinoSearchTextField(
      controller: spec.searchController,
      placeholder: spec.searchPlaceholder,
      onChanged: spec.onSearchChanged,
      backgroundColor: const Color(0x00000000),
      borderRadius: BorderRadius.circular(24),
    );

    final navigation = spec.buildNavigation(
      leading: spec.searchPlacement == ArcSearchPlacement.navigationLeading
          ? search
          : null,
    );

    if (spec.searchPlacement != ArcSearchPlacement.floatingBottom) {
      return navigation;
    }

    return Stack(
      children: [
        Positioned.fill(child: navigation),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: ArcLiquidSearchBar(child: search),
          ),
        ),
      ],
    );
  }
}

/// A glass capsule holding a search field, floating over the content.
///
/// Built from scratch because Cupertino has no bottom-anchored search of any
/// kind; the glass is what makes it read as floating rather than as a docked
/// bar, so the field itself is transparent and the capsule supplies the fill.
class ArcLiquidSearchBar extends StatelessWidget {
  const ArcLiquidSearchBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      settings: kArcLiquidGlassSettings,
      shape: const LiquidRoundedRectangle(borderRadius: Radius.circular(28)),
      glassContainsChild: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: child,
      ),
    );
  }
}
