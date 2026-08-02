import 'package:arc_ui/src/arc/switch.dart';
import 'package:flutter/cupertino.dart';

class CupertinoSwitchFactory extends SwitchFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Widget createSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return CupertinoSwitch(value: value, onChanged: onChanged);
  }
}
