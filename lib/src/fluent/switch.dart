import 'package:arc_ui/src/arc/switch.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentSwitchFactory extends SwitchFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  @override
  Widget createSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ToggleSwitch(checked: value, onChanged: onChanged);
  }
}
