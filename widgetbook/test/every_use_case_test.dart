import 'package:arc_widgetbook/main.directories.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:arc_widgetbook/main.dart';

/// Renders every registered use case through the real Widgetbook app.
///
/// The unit tests build arc_ui widgets directly, which means a use case can be
/// broken — a misused knob, a bad const, a missing ancestor — while every other
/// test stays green. That is exactly how a `knobs.object.dropdown` with a null
/// option shipped: the crash lives in the use-case function, and nothing was
/// executing those functions. This walks the generated directory tree and
/// mounts each leaf for real.
void main() {
  final useCases = <WidgetbookUseCase>[];

  // WidgetbookNode.path is only computable once the tree has parents wired,
  // which happens when a WidgetbookRoot takes ownership of the directories.
  final root = WidgetbookRoot(children: directories);
  for (final leaf in root.leaves) {
    if (leaf is WidgetbookUseCase) useCases.add(leaf);
  }

  test('the generated tree actually contains use cases', () {
    // Guards against this whole file silently passing on an empty list.
    expect(useCases, isNotEmpty);
    expect(useCases.length, greaterThanOrEqualTo(14));
  });

  for (final useCase in useCases) {
    testWidgets('renders: ${useCase.path}', (tester) async {
      tester.view.physicalSize = const Size(1800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ArcWidgetbook(
          initialRoute: Uri(
            path: '/',
            queryParameters: {'path': useCase.path},
          ).toString(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(
        tester.takeException(),
        isNull,
        reason: '${useCase.path} threw while building',
      );
    });
  }
}
