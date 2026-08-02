import 'package:arc_ui/registry/switch.dart';
import 'package:arc_ui/registry/ui_style.dart';
import 'package:flutter/material.dart';

/// An on/off switch rendered in whichever design language [style] selects.
class ArcSwitch extends StatelessWidget {
  const ArcSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.style = UIStyle.material,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the next value; `null` renders the switch disabled.
  final ValueChanged<bool>? onChanged;

  /// The design language to render in.
  final UIStyle style;

  @override
  Widget build(BuildContext context) {
    final factory = SwitchStyleRegistry.getFactory(style);
    if (factory == null) {
      return const Text('(Unsupported Style)');
    }

    return factory.createSwitch(value: value, onChanged: onChanged);
  }
}

/// Abstract switch factory for extensibility
abstract class SwitchFactory {
  Widget createSwitch({
    required bool value,
    required ValueChanged<bool>? onChanged,
  });

  String get styleName;
}
