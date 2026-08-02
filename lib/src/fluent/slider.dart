import 'package:arc_ui/src/arc/slider.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentSliderFactory extends SliderFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

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
