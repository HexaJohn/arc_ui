import 'package:arc_ui/src/arc/checkbox.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidCheckboxFactory extends CheckboxFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Widget createCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return LiquidGlass(
      settings: kArcLiquidGlassSettings,
      shape: const LiquidRoundedRectangle(borderRadius: Radius.circular(8)),
      glassContainsChild: false,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: CupertinoCheckbox(
          value: value,
          onChanged: onChanged,
          tristate: value == null,
          // Transparent when unchecked so the glass shows through instead of a
          // solid Cupertino fill.
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? CupertinoColors.systemBlue
                : const Color(0x00000000),
          ),
        ),
      ),
    );
  }
}
