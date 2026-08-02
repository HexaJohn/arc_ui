import 'package:arc_ui/src/arc/slider.dart';
import 'package:arc_ui/src/liquid/glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidSliderFactory extends SliderFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Widget createSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0.0,
    double max = 1.0,
  }) {
    return LiquidGlass(
      settings: kArcLiquidGlassSettings,
      shape: const LiquidRoundedRectangle(borderRadius: Radius.circular(16)),
      glassContainsChild: false,
      child: CupertinoSlider(
        value: value,
        onChanged: onChanged,
        min: min,
        max: max,
      ),
    );
  }
}
