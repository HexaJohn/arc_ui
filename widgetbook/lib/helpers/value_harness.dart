import 'package:flutter/widgets.dart';

/// Holds the value for a controlled widget so use cases stay interactive.
///
/// Widgetbook use cases are plain functions, so a checkbox driven only by a
/// knob would never respond to being clicked. This keeps local state while
/// still re-seeding from [initialValue] whenever a knob changes it.
class ValueHarness<T> extends StatefulWidget {
  const ValueHarness({
    super.key,
    required this.initialValue,
    required this.builder,
  });

  /// The starting value, usually supplied by a knob.
  final T initialValue;

  /// Builds the controlled widget from the current value and its setter.
  final Widget Function(BuildContext context, T value, ValueChanged<T> onChanged)
  builder;

  @override
  State<ValueHarness<T>> createState() => _ValueHarnessState<T>();
}

class _ValueHarnessState<T> extends State<ValueHarness<T>> {
  late T _value = widget.initialValue;

  @override
  void didUpdateWidget(ValueHarness<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A knob edit should win over whatever the user last clicked, otherwise
    // the knob would appear stuck once the widget has been interacted with.
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      _value,
      (next) => setState(() => _value = next),
    );
  }
}
