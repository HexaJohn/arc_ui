import 'package:arc_ui/src/arc/switch.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class MacOsSwitchFactory extends SwitchFactory {
  @override
  String get styleName => 'macOS';

  @override
  Widget createSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    // MacosSwitch requires a non-null callback, so disabled is expressed by
    // swallowing the taps rather than by passing null.
    return MacosSwitch(value: value, onChanged: onChanged ?? (_) {});
  }
}
