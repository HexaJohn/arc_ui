import 'package:arc_ui/src/arc/checkbox.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentCheckboxFactory extends CheckboxFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  @override
  Widget createCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
  }) {
    return Checkbox(checked: value, onChanged: onChanged);
  }
}
