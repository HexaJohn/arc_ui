import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/ios/app_bar.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidAppBarFactory extends AppBarFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Widget createAppBar({
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  }) {
    // The bar is transparent and the glass sits behind it, so content scrolling
    // underneath is what actually refracts — a solid bar would defeat it.
    return LiquidGlass(
      settings: kArcLiquidGlassSettings,
      shape: const LiquidRoundedRectangle(borderRadius: Radius.circular(24)),
      glassContainsChild: false,
      child: CupertinoNavigationBar(
        backgroundColor: const Color(0x00000000),
        border: null,
        leading: leading,
        middle: title,
        trailing: trailingFrom(actions),
      ),
    );
  }
}
