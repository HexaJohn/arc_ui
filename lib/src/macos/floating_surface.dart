import 'dart:ui' show ImageFilter;

import 'package:arc_ui/src/arc/window_theme.dart';
import 'package:arc_ui/src/macos/window_focus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_state.dart';
import 'package:macos_window_utils/widgets/visual_effect_subview_container/visual_effect_subview_container.dart';

/// Whether a real `NSVisualEffectView` can be attached on this host.
///
/// The visual-effect subview is created over a method channel that only the
/// macOS embedder answers, so everywhere else — web, tests, other desktops —
/// the blur fallback is used instead.
bool get arcSupportsVibrancy =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Gives the sidebar the inset, rounded, translucent look of a modern macOS
/// source list.
///
/// This wraps the navigation panel *only*. Content sits directly on the window
/// background beside it, which is what makes the panel read as floating rather
/// than as one pane of a split view.
///
/// With [ArcFloatingSidebarStyle.vibrancy] it attaches a real
/// `NSVisualEffectView` sized and rounded to match the panel, then punches the
/// Flutter canvas transparent above it with [BlendMode.clear] so the native
/// material shows through. That is the only way to sample the desktop
/// wallpaper behind the window — a [BackdropFilter] can only blur pixels
/// Flutter itself drew, so over a plain window background it does nothing.
///
/// It is still custom rather than `MacosWindow` + `Sidebar`: that pairing is
/// an app-root singleton with hardcoded traffic-light offsets and a
/// full-height sidebar, and it silently discards `Sidebar.decoration.color`.
/// Driving [VisualEffectSubviewContainer] directly is what allows the floating
/// inset shape.
class ArcFloatingSidebarSurface extends StatelessWidget {
  const ArcFloatingSidebarSurface({super.key, required this.child, this.style});

  final Widget child;

  /// Overrides the ambient [ArcWindowTheme] styling.
  final ArcFloatingSidebarStyle? style;

  @override
  Widget build(BuildContext context) {
    final s = style ?? ArcWindowTheme.sidebarOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintBase = isDark ? Colors.white : Colors.black;
    // Blended in Flutter rather than left to the material: AppKit's inactive
    // state flattens the view to the window colour, which makes the panel
    // vanish exactly when it should stand out.
    final isActive = ArcWindowFocus.of(context);
    final tint = isActive ? s.tintOpacity : s.inactiveTintOpacity;

    // Animated so focus changes read as the window receding rather than as a
    // hard flicker, and shared by both the vibrant and fallback paths.
    //
    // Masked rather than covered by a blurred scrim: the panel is already
    // inside a BackdropFilter, and nesting a second one produced haloing at
    // its edges that read as a drop shadow. Fading the child's own alpha needs
    // no extra blur pass and cannot halo.
    final content = AnimatedOpacity(
      opacity: isActive ? 1.0 : s.inactiveContentOpacity,
      duration: const Duration(milliseconds: 150),
      child: _FadeTopEdge(height: s.contentTopInset, child: child),
    );

    final border = Border.all(
      color: tintBase.withValues(alpha: s.borderOpacity),
    );
    final radius = BorderRadius.circular(s.radius);

    final Widget panel = s.vibrancy && arcSupportsVibrancy
        ? ClipRRect(
            borderRadius: radius,
            // Blurs whatever the app painted behind the panel. With the
            // content running full-bleed underneath, this is the diffuse
            // bleed-in macOS shows; with nothing behind it, it costs nothing.
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: s.blurSigma,
                sigmaY: s.blurSigma,
              ),
              child: VisualEffectSubviewContainer(
                material: s.material,
                state: NSVisualEffectViewState.active,
                cornerRadius: s.radius,
                child: DecoratedBox(
                  // Erases Flutter's pixels *proportionally*: at alpha 1 the
                  // panel is pure native material, at 0 it is pure blurred
                  // content, and in between the two compose. That blend is
                  // what lets the panel both match the window and carry a
                  // hint of the content beside it.
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, s.vibrancyAmount),
                    backgroundBlendMode: BlendMode.clear,
                    borderRadius: radius,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      color: tintBase.withValues(alpha: tint),
                      border: border,
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
          )
        : ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: s.blurSigma,
                sigmaY: s.blurSigma,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  color: tintBase.withValues(alpha: tint),
                  border: border,
                ),
                child: content,
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(s.inset, s.topInset, s.inset, s.inset),
      child: panel,
    );
  }
}

/// Rounds the window surface itself.
///
/// AppKit masks the window to its own corner radius, which reads as too tight
/// against a modern macOS look. Because the host has cleared the window
/// background, clipping the content to a larger radius leaves the corners
/// genuinely transparent — the desktop shows through, so the window *is*
/// rounder rather than merely appearing so.
///
/// Wrap the app's root surface, above any [ArcWindow].
class ArcWindowSurface extends StatelessWidget {
  const ArcWindowSurface({super.key, required this.child, this.radius});

  final Widget child;

  /// Overrides the ambient [ArcWindowTheme] radius.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        radius ?? ArcWindowTheme.radiusOf(context),
      ),
      child: child,
    );
  }
}

/// Fades the child out as it approaches the top of the panel.
///
/// macOS lets a source list run to the very top and dissolves it under the
/// titlebar band rather than clipping it, so a row travelling up disappears
/// gradually instead of at a line.
class _FadeTopEdge extends StatelessWidget {
  const _FadeTopEdge({required this.height, required this.child});

  /// How far down the fade reaches.
  final double height;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (height <= 0) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Expressed as a fraction because a shader's stops are normalised to
        // the rect it is created for.
        final span = constraints.maxHeight <= 0
            ? 0.0
            : (height / constraints.maxHeight).clamp(0.0, 1.0);

        return ShaderMask(
          // dstIn multiplies the child's alpha by the gradient, so this
          // subtracts opacity rather than painting anything over it.
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [Color(0x00000000), Color(0xFF000000)],
            stops: [0, span],
          ).createShader(rect),
          child: child,
        );
      },
    );
  }
}
