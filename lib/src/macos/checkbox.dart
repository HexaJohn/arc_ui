import 'package:arc_ui/src/arc/checkbox.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class MacOsCheckboxFactory extends CheckboxFactory {
  @override
  String get styleName => 'macOS';

  @override
  Widget createCheckbox({
    required bool? value,
    required ValueChanged<bool?>? onChanged,
  }) {
    // MacosCheckbox requires a non-null callback, so disabled is expressed by
    // swallowing the taps rather than by passing null.
    return MacosCheckbox(
      value: value,
      onChanged: onChanged ?? (_) {},
    );
  }
}
