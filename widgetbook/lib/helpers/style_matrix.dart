import 'package:arc_ui/registry/ui_style.dart';
import 'package:flutter/material.dart';

import '../addons/ui_style_addon.dart';
import 'liquid_glass_guard.dart';

/// Renders one widget per (row, [UIStyle]) pair so every design language can be
/// compared side by side in a single use case.
///
/// This is the view the demo app hand-rolls in `example/lib/views/buttons.dart`,
/// generalised so any component can reuse it.
class StyleMatrix extends StatelessWidget {
  const StyleMatrix({
    super.key,
    required this.rows,
    required this.builder,
    this.styles = UIStyleAddon.implementedStyles,
    this.cellSize = const Size(180, 72),
  });

  /// The label for each row, e.g. one per `ButtonType`.
  final List<String> rows;

  /// Builds the cell for [style] at [rowIndex].
  final Widget Function(BuildContext context, UIStyle style, int rowIndex)
  builder;

  /// The design languages to render as columns.
  final List<UIStyle> styles;

  /// The fixed size every cell is laid out in, so that a tall widget in one
  /// column does not shift the rest of the row.
  final Size cellSize;

  static const double _labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: _labelWidth),
                for (final style in styles)
                  SizedBox(
                    width: cellSize.width,
                    child: Text(
                      uiStyleLabel(style),
                      textAlign: TextAlign.center,
                      style: headerStyle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            for (var rowIndex = 0; rowIndex < rows.length; rowIndex++)
              Row(
                children: [
                  SizedBox(
                    width: _labelWidth,
                    child: Text(rows[rowIndex], style: headerStyle),
                  ),
                  for (final style in styles)
                    SizedBox(
                      width: cellSize.width,
                      height: cellSize.height,
                      child: Center(
                        child: LiquidGlassGuard(
                          style: style,
                          builder: (context) =>
                              builder(context, style, rowIndex),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
