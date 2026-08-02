import 'dart:ui' show ImageFilter;

import 'package:arc_ui/registry/ui_style.dart';
import 'package:flutter/material.dart';

/// Whether the current rendering backend can run `liquid_glass_renderer`.
///
/// The package asserts on this internally rather than degrading, so Liquid
/// Glass widgets have to be kept off the tree entirely when it is false.
/// That happens more often than you would expect: Impeller is not on by
/// default for macOS desktop here (hence `--enable-impeller` in
/// `.vscode/launch.json`) and is unavailable on web.
bool get isLiquidGlassSupported => ImageFilter.isShaderFilterSupported;

/// Builds a widget only if it will not trip `liquid_glass_renderer`'s Impeller
/// assert, and explains the situation in place of the widget if it would.
///
/// [builder] is deliberately lazy: constructing a `LiquidGlass` is what throws,
/// so the unsupported path must never call it.
class LiquidGlassGuard extends StatelessWidget {
  const LiquidGlassGuard({
    super.key,
    required this.style,
    required this.builder,
  });

  /// The design language the guarded widget will be rendered in.
  final UIStyle style;

  /// Builds the widget when the backend supports it.
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (style != UIStyle.liquid || isLiquidGlassSupported) {
      return builder(context);
    }
    return const _ImpellerNotice();
  }
}

class _ImpellerNotice extends StatelessWidget {
  const _ImpellerNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message:
          'liquid_glass_renderer requires Impeller, which is off on this '
          'backend.\nRun the "arc_ui sandbox (widgetbook)" launch config, or '
          '`flutter run -d macos --enable-impeller`.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Needs Impeller',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
