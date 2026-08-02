import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/arc/scaffold.dart';
import 'package:arc_ui/src/ios/app_bar.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidScaffoldFactory extends ScaffoldFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Widget createScaffold({
    required Widget body,
    ArcAppBar? appBar,
  }) {
    if (appBar == null) {
      return CupertinoPageScaffold(child: body);
    }

    // The bar floats over full-bleed content rather than sitting above it in a
    // column: glass only reads as glass when there is something moving behind
    // it. This is also why it is not passed to `navigationBar`, which would
    // both inset the body and require an ObstructingPreferredSizeWidget.
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          Positioned.fill(child: body),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LiquidGlass(
              settings: kArcLiquidGlassSettings,
              shape: const LiquidRoundedRectangle(
                borderRadius: Radius.circular(24),
              ),
              glassContainsChild: false,
              child: CupertinoNavigationBar(
                backgroundColor: const Color(0x00000000),
                border: null,
                leading: appBar.leading,
                middle: appBar.title,
                trailing: trailingFrom(appBar.actions),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
