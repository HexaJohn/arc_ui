import 'package:arc_ui/src/arc/accent.dart';
import 'package:arc_ui/src/arc/icon.dart';
import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/navigation_widgets.dart';
import 'package:arc_ui/src/arc/window_theme.dart';
import 'package:flutter/material.dart';

/// A macOS-shaped source list.
///
/// Custom rather than `macos_ui`'s `SidebarItems` for three reasons, each of
/// which that widget gets wrong for a modern sidebar:
///
/// * Selection is a solid accent fill with white text. Current macOS uses a
///   neutral greyscale highlight and tints only the label and icon with the
///   accent, so a red accent does not paint a red block behind each row.
/// * Its disclosure rows indent their icon relative to plain rows, so the
///   icons in a mixed list do not line up. Here every row reserves a leading
///   chevron column whether or not it has children, so all icons and labels
///   share one left edge.
/// * A row with children is a disclosure control there, not a destination.
///   On macOS an expandable item is still selectable in its own right, so the
///   chevron only toggles and the rest of the row selects.
class ArcSidebarList extends StatefulWidget {
  const ArcSidebarList({
    super.key,
    required this.spec,
    this.width = 240,
    this.backgroundColor,
    this.topPadding = 0,
  });

  final ArcNavigationSpec spec;
  final double width;
  final Color? backgroundColor;

  /// Space above the first row.
  ///
  /// Applied as scroll padding rather than by insetting the list, so rows
  /// travel up into it and out the top edge — which is what gives the blurred
  /// strip something to obscure. Insetting the whole list would leave that
  /// strip permanently empty.
  final double topPadding;

  @override
  State<ArcSidebarList> createState() => _ArcSidebarListState();
}

class _ArcSidebarListState extends State<ArcSidebarList> {
  /// Paths of collapsed nodes, e.g. `'2'` or `'2.0'`. Absent means expanded,
  /// matching macOS, where a sidebar group opens on first use.
  ///
  /// Keyed by path rather than by index so collapsing a nested child does not
  /// also collapse the same index under a different parent.
  final Set<String> _collapsed = <String>{};

  /// Which row is highlighted, as a path from the top level — `[0]` for a
  /// root, `[0, 1]` for its second child.
  ///
  /// Held here rather than added to the widget API on purpose. A single
  /// `selectedIndex` is what makes selection portable across presentations: a
  /// tab strip has no way to express a nested row. So the sidebar tracks the
  /// finer-grained highlight itself and still reports the top-level index
  /// outward, leaving the contract that every style can honour intact.
  List<int>? _path;

  @override
  void didUpdateWidget(ArcSidebarList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Selection driven from outside wins: it addresses a top-level
    // destination, so any nested highlight is stale.
    if (oldWidget.spec.selectedIndex != widget.spec.selectedIndex) {
      _path = null;
    }
  }

  bool _isSelected(List<int> path) {
    final current = _path ?? [widget.spec.selectedIndex];
    if (current.length != path.length) return false;
    for (var i = 0; i < path.length; i++) {
      if (current[i] != path[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final groups = groupDestinations(spec.source);
    final accent = ArcAccent.of(context);
    final theme = Theme.of(context);
    final metrics = _RowMetrics.of(context);

    // Only scanned for authored section lists: a data source may hold
    // thousands of rows, and building every one just to look for children
    // would defeat its laziness. Data rows do not nest in practice.
    final anyExpandable =
        spec.source.isSectioned &&
        groups.any(
          (group) => group.items.any((e) => e.destination.children.isNotEmpty),
        );

    return Container(
      width: widget.width,
      color: widget.backgroundColor,
      // A plain ListView, with the scrollbar left to ScrollBehavior. Wrapping
      // it to honour the OS "Show scroll bars" setting broke dragging twice
      // over — an explicit Scrollbar needs the scrollable's own controller and
      // stacks on top of the automatic one — for a cosmetic gain.
      child: ListView(
        primary: false,
        padding: EdgeInsets.only(top: widget.topPadding + 6, bottom: 6),
        children: [
          if (spec.leading != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: spec.leading,
            ),
          for (final group in groups) ...[
            if (group.title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 18, 4),
                child: Text(
                  group.title!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final entry in group.items)
              ..._rows(
                entry.destination,
                index: entry.index,
                path: [entry.index],
                depth: 0,
                accent: accent,
                anyExpandable: anyExpandable,
                metrics: metrics,
              ),
          ],
        ],
      ),
    );
  }

  /// Emits a row for [destination] followed by its visible descendants.
  ///
  /// Recursive because real source lists nest deeper than one level — Mail
  /// puts each account under All Inboxes, and those have children of their
  /// own.
  List<Widget> _rows(
    ArcDestination destination, {
    required int index,
    required List<int> path,
    required int depth,
    required Color accent,
    required bool anyExpandable,
    required _RowMetrics metrics,
  }) {
    final expandable = destination.children.isNotEmpty;
    final key = path.join('.');
    final open = !_collapsed.contains(key);

    return [
      _SidebarRow(
        destination: destination,
        selected: _isSelected(path),
        accent: accent,
        indent: depth * metrics.nestIndent,
        reserveChevron: anyExpandable,
        metrics: metrics,
        expanded: expandable ? open : null,
        onToggle: () => setState(() {
          if (open) {
            _collapsed.add(key);
          } else {
            _collapsed.remove(key);
          }
        }),
        onTap: () {
          setState(() => _path = path);
          // The top-level index still goes out, so a caller driving a tab
          // strip from the same state stays correct.
          widget.spec.onDestinationSelected(index);
          if (path.length == 2) {
            widget.spec.onChildSelected?.call(index, path.last);
          }
        },
      ),
      if (expandable && open)
        for (var i = 0; i < destination.children.length; i++)
          ..._rows(
            destination.children[i],
            index: index,
            path: [...path, i],
            depth: depth + 1,
            accent: accent,
            anyExpandable: anyExpandable,
            metrics: metrics,
          ),
    ];
  }
}

/// Row metrics, resolved from the themed density and the ambient text scale.
///
/// Every dimension scales together. Flutter already scales a [Text] by
/// [MediaQuery.textScalerOf], so leaving icons, slots and padding fixed makes
/// a larger text size overflow the row rather than grow it — the label swells
/// inside chrome that stayed put.
class _RowMetrics {
  const _RowMetrics({
    required this.iconSize,
    required this.fontSize,
    required this.badgeSize,
    required this.chevronSize,
    required this.chevronSlot,
    required this.iconSlot,
    required this.iconGap,
    required this.verticalPadding,
    required this.nestIndent,
  });

  factory _RowMetrics.of(BuildContext context) {
    final size = ArcWindowTheme.sidebarItemSizeOf(context);
    // Clamped: accessibility scales run far past what a fixed-width sidebar
    // can absorb, and an unbounded icon would push the label out entirely.
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.6);

    return _RowMetrics(
      iconSize: size.iconSize * scale,
      fontSize: size.fontSize,
      badgeSize: size.fontSize - 1,
      chevronSize: 8 * scale,
      chevronSlot: 16 * scale,
      iconSlot: (size.iconSize + 4) * scale,
      iconGap: 8 * scale,
      verticalPadding: size.verticalPadding,
      nestIndent: 14 * scale,
    );
  }

  final double iconSize;

  /// Unscaled: [Text] applies the scaler itself, so pre-multiplying here would
  /// square it.
  final double fontSize;
  final double badgeSize;
  final double chevronSize;
  final double chevronSlot;
  final double iconSlot;
  final double iconGap;
  final double verticalPadding;
  final double nestIndent;
}

class _SidebarRow extends StatelessWidget {
  const _SidebarRow({
    required this.destination,
    required this.selected,
    required this.accent,
    required this.indent,
    required this.reserveChevron,
    required this.metrics,
    required this.expanded,
    required this.onToggle,
    required this.onTap,
  });

  final ArcDestination destination;
  final bool selected;
  final Color accent;
  final double indent;

  /// Whether to leave room for the chevron column. False when no row in the
  /// list can expand, so a flat list is not indented for an affordance that
  /// never appears.
  final bool reserveChevron;

  final _RowMetrics metrics;

  /// Null when the row has no children.
  final bool? expanded;
  final VoidCallback? onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = selected
        ? (destination.selectedIcon ?? destination.icon)
        : destination.icon;
    final foreground = selected ? accent : theme.colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: EdgeInsets.fromLTRB(8 + indent, 0.5, 8, 0.5),
        padding: EdgeInsets.fromLTRB(
          3,
          metrics.verticalPadding,
          10,
          metrics.verticalPadding,
        ),
        decoration: BoxDecoration(
          // Greyscale, deliberately: macOS tints the *label* with the accent
          // and leaves the highlight itself neutral, so a red accent does not
          // paint a red block behind every selected row.
          color: selected
              ? (theme.brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08))
              : null,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            // Reserved on every row of a list that has *any* expandable row —
            // otherwise plain rows would put their icon where expandable rows
            // put their chevron and the column would zig-zag.
            if (reserveChevron)
              SizedBox(
                width: metrics.chevronSlot,
                child: expanded == null
                    ? null
                    // Its own hit target: the chevron toggles, the rest of the
                    // row selects.
                    : GestureDetector(
                        onTap: onToggle,
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedRotation(
                          turns: expanded! ? 0.25 : 0,
                          duration: const Duration(milliseconds: 150),
                          child: ArcIcon(
                            ArcIcons.chevronRight,
                            size: metrics.chevronSize,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            // Likewise fixed whether or not this row has an icon, so every
            // label shares one left edge.
            //
            // merge, not an overriding IconTheme: an icon given an explicit
            // colour keeps it, which is what lets coloured flags stay orange
            // and red through selection rather than being tinted flat.
            SizedBox(
              width: metrics.iconSlot,
              child: icon == null
                  ? null
                  : IconTheme.merge(
                      data: IconThemeData(
                        size: metrics.iconSize,
                        color: foreground,
                      ),
                      child: icon,
                    ),
            ),
            SizedBox(width: metrics.iconGap),
            Expanded(
              child: Text(
                destination.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: metrics.fontSize, color: foreground),
              ),
            ),
            if (destination.badge != null) ...[
              const SizedBox(width: 6),
              Text(
                destination.badge!,
                style: TextStyle(
                  fontSize: metrics.badgeSize,
                  // Tabular so a column of counts stays aligned as the digits
                  // change.
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
