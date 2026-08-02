import 'package:arc_ui/src/arc/icon.dart';
import 'package:arc_ui/src/arc/navigation.dart';
import 'package:flutter/material.dart';

/// How a bottom strip splits its destinations once it runs out of room.
///
/// The index arithmetic is easy to get subtly wrong — the strip's selected
/// index is not the destination index once "More" is in play — so it is
/// computed once here and shared by every style that draws bottom tabs.
class ArcTabSplit {
  const ArcTabSplit({
    required this.visible,
    required this.overflow,
    required this.moreIndex,
    required this.stripSelectedIndex,
    required this.selectionIsHidden,
  });

  /// Destinations shown directly, paired with their real index.
  final List<({int index, ArcDestination destination})> visible;

  /// Destinations collapsed behind "More", paired with their real index.
  final List<({int index, ArcDestination destination})> overflow;

  /// Position of the "More" tab within the strip, or `-1` when it is absent.
  final int moreIndex;

  /// Which strip position to highlight. When the selected destination lives in
  /// [overflow] this is [moreIndex], so "More" reads as active.
  final int stripSelectedIndex;

  /// Whether the current selection is hidden behind "More".
  final bool selectionIsHidden;

  bool get hasOverflow => moreIndex >= 0;
}

/// Applies the tab cap that neither `CupertinoTabBar` nor Material's
/// `NavigationBar` enforces.
ArcTabSplit splitForBottomTabs(ArcNavigationSpec spec) {
  final all = [
    for (var i = 0; i < spec.source.length; i++)
      (index: i, destination: spec.source.destinationAt(i)),
  ];

  if (!spec.overflows) {
    return ArcTabSplit(
      visible: all,
      overflow: const [],
      moreIndex: -1,
      stripSelectedIndex: spec.selectedIndex,
      selectionIsHidden: false,
    );
  }

  final visible = all.take(spec.visibleTabCount).toList();
  final overflow = all.skip(spec.visibleTabCount).toList();
  final hidden = spec.selectedIndex >= spec.visibleTabCount;

  return ArcTabSplit(
    visible: visible,
    overflow: overflow,
    moreIndex: visible.length,
    stripSelectedIndex: hidden ? visible.length : spec.selectedIndex,
    selectionIsHidden: hidden,
  );
}

/// Icon used for a destination that supplies none, so a tab strip never has to
/// render a bare label where an icon is structurally expected.
///
/// Adaptive: [ArcNavigation] publishes an [ArcStyleScope], so this resolves to
/// the icon set of whichever design language is rendering it.
const Widget kArcFallbackNavIcon = ArcIcon(ArcIcons.circle);

/// Icon for the overflow tab.
const Widget kArcMoreNavIcon = ArcIcon(ArcIcons.more);

/// Flattens the group/child structure into the flat rows a strip can show.
///
/// This is the "flatten to parent" rule: children are dropped, never promoted,
/// so every visible row's position still equals its destination index and one
/// integer of selection stays meaningful in every presentation.
List<ArcDestination> flattenToParent(ArcNavSource source) => [
  for (var i = 0; i < source.length; i++) source.destinationAt(i),
];

/// Groups consecutive destinations that share an [ArcDestination.group].
///
/// Returns entries in presentation order; a null title means the run is
/// ungrouped and should render without a header.
List<({String? title, List<({int index, ArcDestination destination})> items})>
groupDestinations(ArcNavSource source) {
  final out =
      <({String? title, List<({int index, ArcDestination destination})> items})>[];

  for (var i = 0; i < source.length; i++) {
    final destination = source.destinationAt(i);
    final entry = (index: i, destination: destination);

    if (out.isNotEmpty && out.last.title == destination.group) {
      out.last.items.add(entry);
    } else {
      out.add((title: destination.group, items: [entry]));
    }
  }

  return out;
}
