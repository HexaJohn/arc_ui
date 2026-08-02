import 'package:arc_ui/src/arc/switch.dart';
import 'package:flutter/material.dart';

class MaterialSwitchFactory extends SwitchFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Switch(value: value, onChanged: onChanged);
  }
}
