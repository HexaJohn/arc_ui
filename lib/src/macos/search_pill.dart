import 'package:arc_ui/src/arc/accent.dart';
import 'package:flutter/material.dart';

/// The pill-shaped search field macOS uses, in both of the places it parks it.
///
/// Built from scratch rather than styling `MacosSearchField`, because that
/// widget cannot be styled: `MacosTextField` discards the `color` and `border`
/// of any decoration you hand it — `decoration?.copyWith(border:
/// resolvedBorder, color: decorationColor)` — keeping only the radius, and it
/// hardcodes its focus ring to blue regardless of the user's accent.
///
/// It also draws its magnifier with `CupertinoIcons.search` while declaring no
/// dependency on `cupertino_icons`, so the glyph renders as tofu in any app
/// that has not added that package itself. This uses a Material icon, which is
/// always bundled.
class ArcSearchPill extends StatefulWidget {
  const ArcSearchPill({
    super.key,
    required this.controller,
    this.placeholder = 'Search',
    this.onChanged,
    this.height = 24,
  });

  final TextEditingController controller;

  /// Shown when empty. Callers are expected to make this specific — "Search
  /// mail" rather than "Search" — which is why it is plumbed all the way from
  /// [ArcWindow.searchPlaceholder].
  final String placeholder;

  final ValueChanged<String>? onChanged;

  /// Drives the whole scale: ring, radius, icon and text all derive from it.
  ///
  /// macOS uses a noticeably larger field in the titlebar than in a sidebar,
  /// so the two placements pass different values.
  final double height;

  @override
  State<ArcSearchPill> createState() => _ArcSearchPillState();
}

class _ArcSearchPillState extends State<ArcSearchPill> {
  late final FocusNode _focus = FocusNode()..addListener(_onFocusChanged);

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  /// Thickness of the focus glow. macOS draws it *outside* the control, so it
  /// is reserved unconditionally and merely made transparent when unfocused —
  /// otherwise the field would jump on focus.
  static const double _ring = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;
    final accent = ArcAccent.of(context);
    final foreground = isDark ? Colors.white : Colors.black87;
    final muted = base.withValues(alpha: isDark ? 0.55 : 0.45);

    final fontSize = widget.height >= 28 ? 13.0 : 12.0;
    final iconSize = widget.height >= 28 ? 15.0 : 13.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.height / 2 + _ring),
        // An outline, not a fill. The field's own background is translucent,
        // so a filled ring showed through behind it and tinted the whole
        // control rather than just haloing it. A Border insets its child by
        // its own width, which is why there is no padding here.
        border: Border.all(
          color: _focus.hasFocus
              ? accent.withValues(alpha: 0.5)
              : Colors.transparent,
          width: _ring,
        ),
      ),
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: base.withValues(alpha: isDark ? 0.12 : 0.06),
          borderRadius: BorderRadius.circular(widget.height / 2),
          border: Border.all(
            color: base.withValues(alpha: isDark ? 0.16 : 0.12),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: iconSize, color: muted),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                onChanged: widget.onChanged,
                cursorHeight: fontSize + 1,
                // Explicit, because the ambient DefaultTextStyle over a vibrant
                // surface is not guaranteed to contrast with it.
                style: TextStyle(fontSize: fontSize, color: foreground),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: widget.placeholder,
                  hintStyle: TextStyle(fontSize: fontSize, color: muted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
