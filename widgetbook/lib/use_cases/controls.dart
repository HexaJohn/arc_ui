import 'package:arc_ui/arc_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../helpers/liquid_glass_guard.dart';
import '../helpers/style_matrix.dart';
import '../helpers/value_harness.dart';

// ---------------------------------------------------------------- checkbox

@widgetbook.UseCase(name: 'Default', type: ArcCheckbox, path: '[Components]')
Widget buildArcCheckboxUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final initial = context.knobs.boolean(label: 'Checked', initialValue: true);

  return LiquidGlassGuard(
    style: style,
    builder: (context) => ValueHarness<bool?>(
      initialValue: initial,
      builder: (context, value, onChanged) => ArcCheckbox(
        style: style,
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Style Matrix',
  type: ArcCheckbox,
  path: '[Components]',
)
Widget buildArcCheckboxMatrixUseCase(BuildContext context) {
  return StyleMatrix(
    rows: const ['checked', 'unchecked', 'disabled'],
    builder: (context, style, rowIndex) => ArcCheckbox(
      style: style,
      value: rowIndex != 1,
      onChanged: rowIndex == 2 ? null : (_) {},
    ),
  );
}

// ------------------------------------------------------------------ switch

@widgetbook.UseCase(name: 'Default', type: ArcSwitch, path: '[Components]')
Widget buildArcSwitchUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final initial = context.knobs.boolean(label: 'On', initialValue: true);

  return LiquidGlassGuard(
    style: style,
    builder: (context) => ValueHarness<bool>(
      initialValue: initial,
      builder: (context, value, onChanged) => ArcSwitch(
        style: style,
        value: value,
        onChanged: enabled ? onChanged : null,
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Style Matrix', type: ArcSwitch, path: '[Components]')
Widget buildArcSwitchMatrixUseCase(BuildContext context) {
  return StyleMatrix(
    rows: const ['on', 'off', 'disabled'],
    builder: (context, style, rowIndex) => ArcSwitch(
      style: style,
      value: rowIndex != 1,
      onChanged: rowIndex == 2 ? null : (_) {},
    ),
  );
}

// ------------------------------------------------------------------ slider

@widgetbook.UseCase(name: 'Default', type: ArcSlider, path: '[Components]')
Widget buildArcSliderUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final initial = context.knobs.double.slider(
    label: 'Value',
    initialValue: 0.5,
    min: 0,
    max: 1,
  );

  return SizedBox(
    width: 240,
    child: LiquidGlassGuard(
      style: style,
      builder: (context) => ValueHarness<double>(
        initialValue: initial,
        builder: (context, value, onChanged) => ArcSlider(
          style: style,
          value: value,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(name: 'Style Matrix', type: ArcSlider, path: '[Components]')
Widget buildArcSliderMatrixUseCase(BuildContext context) {
  return StyleMatrix(
    rows: const ['0%', '50%', '100%'],
    cellSize: const Size(220, 72),
    builder: (context, style, rowIndex) => SizedBox(
      width: 180,
      child: ArcSlider(
        style: style,
        value: [0.0, 0.5, 1.0][rowIndex],
        onChanged: (_) {},
      ),
    ),
  );
}
