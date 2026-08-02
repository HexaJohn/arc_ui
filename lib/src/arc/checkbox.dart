import 'package:arc_ui/registry/checkbox.dart';
import 'package:arc_ui/registry/ui_style.dart';
import 'package:flutter/material.dart';

/// A checkbox rendered in whichever design language [style] selects.
///
/// [value] is nullable so the mixed/indeterminate state is representable; the
/// styles that cannot draw it fall back to unchecked.
class ArcCheckbox extends StatelessWidget {
  const ArcCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = UIStyle.material,
  });

  /// Whether the box is checked. `null` is the mixed state.
  final bool? value;

  /// Called with the next value; `null` renders the box disabled.
  final ValueChanged<bool?>? onChanged;

  /// The design language to render in.
  final UIStyle style;

  @override
  Widget build(BuildContext context) {
    final factory = CheckboxStyleRegistry.getFactory(style);
    if (factory == null) {
      return const Text('(Unsupported Style)');
    }

    return factory.createCheckbox(value: value, onChanged: onChanged);
  }
}

/// Abstract checkbox factory for extensibility
abstract class CheckboxFactory {
  Widget createCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
  });

  String get styleName;
}
