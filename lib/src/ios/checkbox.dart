import 'package:arc_ui/src/arc/checkbox.dart';
import 'package:flutter/cupertino.dart';

class CupertinoCheckboxFactory extends CheckboxFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Widget createCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return CupertinoCheckbox(
      value: value,
      onChanged: onChanged,
      tristate: value == null,
    );
  }
}
