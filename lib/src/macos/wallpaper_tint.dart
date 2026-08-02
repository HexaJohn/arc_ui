import 'package:arc_ui/src/macos/floating_surface.dart' show arcSupportsVibrancy;
import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_material.dart';
import 'package:macos_window_utils/widgets/visual_effect_subview_container/visual_effect_subview_container.dart';

/// How a macOS window paints its background.
enum ArcWindowBackground {
  /// A flat theme colour. No native material involved.
  opaque,

  /// Mostly [ArcWallpaperTintedSurface.color], picking up a subtle hue from
  /// the desktop wallpaper behind the window.
  ///
  /// This is what macOS does to ordinary window backgrounds, and it is a
  /// different effect from [vibrant] rather than a weaker one: the window stays
  /// essentially opaque and merely takes on the wallpaper's colour cast.
  wallpaperTint,

  /// Genuinely translucent — the blurred desktop shows through.
  ///
  /// Correct for chrome (sidebars, toolbars); macOS itself keeps content areas
  /// opaque, so applying this to a whole window is a stylistic choice rather
  /// than the native convention.
  vibrant,
}

/// Paints a wallpaper-tinted background behind [child].
///
/// Built on the same `NSVisualEffectView` subview as the floating sidebar, but
/// with the `windowBackground` material and [color] layered over it at
/// [strength]. The material supplies the wallpaper's colour cast; the overlay
/// keeps the surface readable instead of see-through.
///
/// Falls back to a flat [color] anywhere the native subview is unavailable.
class ArcWallpaperTintedSurface extends StatelessWidget {
  const ArcWallpaperTintedSurface({
    super.key,
    required this.color,
    required this.child,
    this.strength = 0.10,
  });

  /// The window's own background colour.
  final Color color;

  /// How much of [color] sits over the material. At 1.0 the tint is fully
  /// hidden; at 0.0 this is effectively vibrancy.
  final double strength;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!arcSupportsVibrancy) {
      return ColoredBox(color: color, child: child);
    }

    // LayoutBuilder so the native subview is repositioned when the window is
    // resized; the container only syncs its frame on rebuild.
    return LayoutBuilder(
      builder: (context, _) => VisualEffectSubviewContainer(
        material: NSVisualEffectViewMaterial.windowBackground,
        child: ColoredBox(
          color: color.withValues(alpha: strength),
          child: child,
        ),
      ),
    );
  }
}
