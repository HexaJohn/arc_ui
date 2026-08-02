import 'package:arc_ui/src/arc/switch.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidSwitchFactory extends SwitchFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Widget createSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return LiquidGlass(
      settings: kArcLiquidGlassSettings,
      shape: const LiquidRoundedRectangle(borderRadius: Radius.circular(16)),
      glassContainsChild: false,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        // Let the glass supply the off-state fill.
        inactiveTrackColor: const Color(0x00000000),
      ),
    );
  }
}
