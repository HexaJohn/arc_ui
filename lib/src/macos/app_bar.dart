import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class MacOsAppBarFactory extends AppBarFactory {
  @override
  String get styleName => 'macOS';

  @override
  Widget createAppBar({
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  }) {
    return ToolBar(
      title: title,
      leading: leading,
      actions: toolbarItemsFrom(actions),
    );
  }
}

/// Adapts plain widgets to the [ToolbarItem]s `macos_ui` requires.
///
/// [CustomToolbarItem] is the only [ToolbarItem] that accepts arbitrary
/// widgets; the same builder serves both the toolbar and its overflow menu.
List<ToolbarItem>? toolbarItemsFrom(List<Widget>? actions) {
  if (actions == null || actions.isEmpty) return null;
  return actions
      .map(
        (action) => CustomToolbarItem(
          inToolbarBuilder: (context) => action,
          inOverflowedBuilder: (context) => action,
        ),
      )
      .toList();
}
