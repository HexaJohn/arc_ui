import 'package:arc_ui/arc_ui.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../helpers/liquid_glass_guard.dart';
import '../helpers/style_matrix.dart';

/// A single button in whichever design language is selected in the toolbar.
@widgetbook.UseCase(name: 'Default', type: ArcButton, path: '[Components]')
Widget buildArcButtonUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final text = context.knobs.string(label: 'Text', initialValue: 'Button');
  final type = context.knobs.object.dropdown(
    label: 'Type',
    options: ButtonType.values,
    labelBuilder: (type) => type.name,
  );

  return LiquidGlassGuard(
    style: style,
    builder: (context) =>
        ArcButton(text: text, onPressed: () {}, style: style, type: type),
  );
}

/// Every [ButtonType] in the selected design language, to check that the four
/// variants stay visually distinct from one another.
@widgetbook.UseCase(name: 'Types', type: ArcButton, path: '[Components]')
Widget buildArcButtonTypesUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final text = context.knobs.string(label: 'Text', initialValue: 'Button');

  return Wrap(
    spacing: 24,
    runSpacing: 24,
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final type in ButtonType.values)
        LiquidGlassGuard(
          style: style,
          builder: (context) =>
              ArcButton(text: text, onPressed: () {}, style: style, type: type),
        ),
    ],
  );
}

/// Every [ButtonType] against every design language at once.
///
/// This one deliberately ignores the toolbar's design language — comparing the
/// styles against each other is the whole point of the matrix.
@widgetbook.UseCase(name: 'Style Matrix', type: ArcButton, path: '[Components]')
Widget buildArcButtonMatrixUseCase(BuildContext context) {
  final text = context.knobs.string(label: 'Text', initialValue: 'Button');

  return StyleMatrix(
    rows: [for (final type in ButtonType.values) type.name],
    builder: (context, style, rowIndex) => ArcButton(
      text: text,
      onPressed: () {},
      style: style,
      type: ButtonType.values[rowIndex],
    ),
  );
}
