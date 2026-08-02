import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../helpers/liquid_glass_guard.dart';
import '../helpers/style_matrix.dart';

/// A full page scaffold in whichever design language is selected in the
/// toolbar.
@widgetbook.UseCase(name: 'Default', type: ArcScaffold, path: '[Components]')
Widget buildArcScaffoldUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final title = context.knobs.string(label: 'Title', initialValue: 'arc_ui');
  final body = context.knobs.string(
    label: 'Body',
    initialValue: 'Body content',
  );
  final showLeading = context.knobs.boolean(label: 'Leading');
  final actionCount = context.knobs.int.slider(
    label: 'Actions',
    initialValue: 2,
    min: 0,
    max: 3,
  );

  return SizedBox.expand(
    child: LiquidGlassGuard(
      style: style,
      builder: (context) => ArcScaffold(
        style: style,
        appBar: ArcAppBar(
          style: style,
          title: Text(title),
          leading: showLeading ? const Icon(Icons.arrow_back) : null,
          actions: demoActions(actionCount),
        ),
        body: Center(child: Text(body)),
      ),
    ),
  );
}

/// Every design language's scaffold side by side, each in a page-shaped cell.
@widgetbook.UseCase(
  name: 'Style Matrix',
  type: ArcScaffold,
  path: '[Components]',
)
Widget buildArcScaffoldMatrixUseCase(BuildContext context) {
  final title = context.knobs.string(label: 'Title', initialValue: 'arc_ui');

  return StyleMatrix(
    rows: const ['scaffold'],
    cellSize: const Size(260, 220),
    builder: (context, style, rowIndex) => DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ArcScaffold(
        style: style,
        appBar: ArcAppBar(
          style: style,
          title: Text(title),
          actions: demoActions(1),
        ),
        body: const Center(child: Text('Body content')),
      ),
    ),
  );
}

/// A few interchangeable action widgets, so the knobs can show how each design
/// language places a varying number of them.
List<Widget>? demoActions(int count) {
  if (count <= 0) return null;
  const icons = [Icons.add, Icons.search, Icons.more_horiz];
  return [
    for (var i = 0; i < count; i++)
      Icon(icons[i % icons.length], size: 18),
  ];
}
