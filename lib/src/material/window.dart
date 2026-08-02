import 'package:arc_ui/src/arc/menu_bar_widgets.dart';
import 'package:arc_ui/src/arc/window.dart';
import 'package:flutter/material.dart';

class MaterialWindowFactory extends WindowFactory {
  @override
  String get styleName => 'Material Design';

  /// Material has no system menu bar concept, so it is always in-window — and
  /// only where there is room for it.
  @override
  ArcMenuPresentation resolveMenuPresentation({required double width}) =>
      width < 600 ? ArcMenuPresentation.none : ArcMenuPresentation.inline;

  /// 840 rather than 600, to match the breakpoint at which
  /// [MaterialNavigationFactory] extends the rail: the collapsed rail is
  /// 80px wide and a `SearchBar` does not fit in it.
  @override
  ArcSearchPlacement resolveSearchPlacement({required double width}) =>
      width < 840
      ? ArcSearchPlacement.contentTop
      : ArcSearchPlacement.navigationLeading;

  @override
  Widget createWindow(ArcWindowSpec spec) {
    final search = SearchBar(
      controller: spec.searchController,
      hintText: spec.searchPlaceholder,
      onChanged: spec.onSearchChanged,
      leading: const Icon(Icons.search),
      elevation: const WidgetStatePropertyAll(0),
      constraints: const BoxConstraints(minHeight: 40),
    );

    final navigation = spec.buildNavigation(
      leading: spec.searchPlacement == ArcSearchPlacement.navigationLeading
          ? search
          : null,
    );

    return Column(
      children: [
        if (spec.menuPresentation == ArcMenuPresentation.inline)
          ArcInlineMenuBar(menus: spec.menus),
        if (spec.searchPlacement == ArcSearchPlacement.contentTop)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: search,
          ),
        Expanded(child: navigation),
      ],
    );
  }
}
