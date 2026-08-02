import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../helpers/liquid_glass_guard.dart';
import '../helpers/style_matrix.dart';
import 'scaffold.dart';

/// A standalone app bar in whichever design language is selected in the
/// toolbar.
@widgetbook.UseCase(name: 'Default', type: ArcAppBar, path: '[Components]')
Widget buildArcAppBarUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final title = context.knobs.string(label: 'Title', initialValue: 'arc_ui');
  final showLeading = context.knobs.boolean(label: 'Leading');
  final actionCount = context.knobs.int.slider(
    label: 'Actions',
    initialValue: 2,
    min: 0,
    max: 3,
  );

  return Align(
    alignment: Alignment.topCenter,
    child: LiquidGlassGuard(
      style: style,
      builder: (context) => ArcAppBar(
        style: style,
        title: Text(title),
        leading: showLeading ? const Icon(Icons.arrow_back) : null,
        actions: demoActions(actionCount),
      ),
    ),
  );
}

/// The same app bar in every design language at once.
///
/// Worth comparing side by side because the styles disagree about where
/// actions go: Material lays them out in a row, Cupertino collapses them into
/// one trailing slot, macOS turns them into toolbar items and Fluent puts them
/// in a command bar.
@widgetbook.UseCase(name: 'Style Matrix', type: ArcAppBar, path: '[Components]')
Widget buildArcAppBarMatrixUseCase(BuildContext context) {
  final title = context.knobs.string(label: 'Title', initialValue: 'arc_ui');
  final actionCount = context.knobs.int.slider(
    label: 'Actions',
    initialValue: 2,
    min: 0,
    max: 3,
  );

  return StyleMatrix(
    rows: const ['app bar'],
    cellSize: const Size(260, 120),
    builder: (context, style, rowIndex) => ArcAppBar(
      style: style,
      title: Text(title),
      actions: demoActions(actionCount),
    ),
  );
}
