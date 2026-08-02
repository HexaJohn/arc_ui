import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:flutter/cupertino.dart';

class CupertinoAppBarFactory extends AppBarFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Widget createAppBar({
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  }) {
    return CupertinoNavigationBar(
      leading: leading,
      middle: title,
      trailing: trailingFrom(actions),
    );
  }
}

/// Collapses [actions] into the single trailing slot Cupertino gives you.
Widget? trailingFrom(List<Widget>? actions) {
  if (actions == null || actions.isEmpty) return null;
  if (actions.length == 1) return actions.single;
  return Row(mainAxisSize: MainAxisSize.min, children: actions);
}
