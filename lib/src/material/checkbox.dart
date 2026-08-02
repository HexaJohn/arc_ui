import 'package:arc_ui/src/arc/checkbox.dart';
import 'package:flutter/material.dart';

class MaterialCheckboxFactory extends CheckboxFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      tristate: value == null,
    );
  }
}
