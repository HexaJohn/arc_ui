import 'package:arc_ui/src/arc/slider.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class MacOsSliderFactory extends SliderFactory {
  @override
  String get styleName => 'macOS';

  @override
  Widget createSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0.0,
    double max = 1.0,
  }) {
    // MacosSlider requires a non-null callback, so disabled is expressed by
    // swallowing the drags rather than by passing null.
    return MacosSlider(
      value: value,
      onChanged: onChanged ?? (_) {},
      min: min,
      max: max,
    );
  }
}
