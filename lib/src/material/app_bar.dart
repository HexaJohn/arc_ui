import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:flutter/material.dart';

class MaterialAppBarFactory extends AppBarFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createAppBar({
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  }) {
    return AppBar(
      title: title,
      leading: leading,
      actions: actions,
    );
  }
}
