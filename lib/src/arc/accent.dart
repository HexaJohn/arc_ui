import 'package:appkit_ui_element_colors/appkit_ui_element_colors.dart';
import 'package:appkit_ui_element_colors/convenience/ui_element_color_builder.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The accent colour arc_ui should tint selection and controls with.
///
/// On macOS this is the user's own choice from System Settings, not a constant
/// — someone running the red accent expects red highlights. Elsewhere it falls
/// back to whatever the app supplies.
class ArcAccent extends InheritedWidget {
  const ArcAccent({super.key, required this.color, required super.child});

  final Color color;

  /// The ambient accent, falling back to the Material primary so this is safe
  /// to call anywhere.
  static Color of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ArcAccent>()?.color ??
      Theme.of(context).colorScheme.primary;

  @override
  bool updateShouldNotify(ArcAccent oldWidget) => color != oldWidget.color;
}

/// Supplies [ArcAccent] from the live macOS system accent colour.
///
/// Reads `controlAccentColor` through AppKit and rebuilds when the user
/// changes it, so the app follows System Settings without a restart. On every
/// other platform — and while the first async read is in flight — it passes
/// [fallback] straight through.
class ArcSystemAccent extends StatelessWidget {
  const ArcSystemAccent({
    super.key,
    required this.child,
    required this.fallback,
  });

  final Widget child;
  final Color fallback;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) {
      return ArcAccent(color: fallback, child: child);
    }

    return UiElementColorBuilder(
      // Both builders render the subtree with the fallback rather than an
      // empty box: the accent is a tint, so being briefly wrong is far better
      // than the whole app blinking out while a colour is fetched.
      errorBuilder: (context, error) => ArcAccent(color: fallback, child: child),
      missingDataBuilder: (context) => ArcAccent(color: fallback, child: child),
      builder: (context, colors) =>
          ArcAccent(color: colors.controlAccentColor, child: child),
    );
  }
}
