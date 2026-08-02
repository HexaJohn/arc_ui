import 'package:arc_ui/src/arc/slider.dart';
import 'package:flutter/material.dart';

class MaterialSliderFactory extends SliderFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0.0,
    double max = 1.0,
  }) {
    return Slider(value: value, onChanged: onChanged, min: min, max: max);
  }
}
