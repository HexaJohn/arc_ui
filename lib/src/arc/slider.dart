import 'package:arc_ui/registry/slider.dart';
import 'package:arc_ui/registry/ui_style.dart';
import 'package:flutter/material.dart';

/// A slider rendered in whichever design language [style] selects.
class ArcSlider extends StatelessWidget {
  const ArcSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.style = UIStyle.material,
  });

  /// The current value, between [min] and [max].
  final double value;

  /// Called as the thumb moves; `null` renders the slider disabled.
  final ValueChanged<double>? onChanged;

  /// The lowest selectable value.
  final double min;

  /// The highest selectable value.
  final double max;

  /// The design language to render in.
  final UIStyle style;

  @override
  Widget build(BuildContext context) {
    final factory = SliderStyleRegistry.getFactory(style);
    if (factory == null) {
      return const Text('(Unsupported Style)');
    }

    return factory.createSlider(
      value: value,
      onChanged: onChanged,
      min: min,
      max: max,
    );
  }
}

/// Abstract slider factory for extensibility
abstract class SliderFactory {
  Widget createSlider({
    required double value,
    required ValueChanged<double>? onChanged,
    double min = 0.0,
    double max = 1.0,
  });

  String get styleName;
}
