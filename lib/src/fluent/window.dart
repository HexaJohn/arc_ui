import 'package:arc_ui/src/arc/menu_bar_widgets.dart';
import 'package:arc_ui/src/arc/window.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

class FluentWindowFactory extends WindowFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  /// Windows draws its menu bar inside the window. Note this is the legacy
  /// pattern — modern Fluent apps favour a CommandBar — but it is what an
  /// inline File/Edit/Window bar means on Windows, and it is what was asked
  /// for.
  @override
  ArcMenuPresentation resolveMenuPresentation({required double width}) =>
      width < 480 ? ArcMenuPresentation.none : ArcMenuPresentation.inline;

  /// Always in the pane: NavigationPane has a dedicated search slot that
  /// survives collapsing to compact, so there is no narrow-width special case.
  @override
  ArcSearchPlacement resolveSearchPlacement({required double width}) =>
      ArcSearchPlacement.navigationLeading;

  @override
  Widget createWindow(ArcWindowSpec spec) {
    final search = fluent.TextBox(
      controller: spec.searchController,
      placeholder: spec.searchPlaceholder,
      onChanged: spec.onSearchChanged,
      prefix: const Padding(
        padding: EdgeInsets.only(left: 8),
        child: Icon(fluent.FluentIcons.search, size: 12),
      ),
    );

    return Column(
      children: [
        if (spec.menuPresentation == ArcMenuPresentation.inline)
          // fluent_ui MenuBar has no shortcut support of any kind, so the
          // shared inline bar is used instead: it renders accelerators and
          // shortcut hints, which a Windows menu is expected to have.
          ArcInlineMenuBar(menus: spec.menus),
        Expanded(
          child: spec.buildNavigation(
            leading: spec.searchPlacement == ArcSearchPlacement.navigationLeading
                ? search
                : null,
          ),
        ),
      ],
    );
  }
}
