import 'package:arc_ui/src/arc/slider.dart';
import 'package:flutter/cupertino.dart';

class CupertinoSliderFactory extends SliderFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Widget createSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0.0,
    double max = 1.0,
  }) {
    return CupertinoSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
    );
  }
}
