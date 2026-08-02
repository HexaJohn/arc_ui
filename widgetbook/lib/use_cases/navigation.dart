import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../addons/ui_style_addon.dart';
import '../helpers/liquid_glass_guard.dart';
import '../helpers/value_harness.dart';

/// The App Store's information architecture, as the thought experiment framed
/// it: five authored sections, one of them with children that only a sidebar
/// can show.
final _appStore = ArcNavSource.sections([
  const ArcDestination(
    label: 'Today',
    icon: Icon(Icons.today_outlined),
    selectedIcon: Icon(Icons.today),
    group: 'Discover',
  ),
  const ArcDestination(
    label: 'Games',
    icon: Icon(Icons.sports_esports_outlined),
    selectedIcon: Icon(Icons.sports_esports),
    group: 'Discover',
  ),
  const ArcDestination(
    label: 'Apps',
    icon: Icon(Icons.apps_outlined),
    selectedIcon: Icon(Icons.apps),
    group: 'Discover',
    children: [
      ArcDestination(label: 'Productivity'),
      ArcDestination(label: 'Photo & Video'),
    ],
  ),
  const ArcDestination(
    label: 'Arcade',
    icon: Icon(Icons.stadium_outlined),
    selectedIcon: Icon(Icons.stadium),
    group: 'Discover',
  ),
  const ArcDestination(
    label: 'Search',
    icon: Icon(Icons.search),
    group: 'Tools',
  ),
]);

Widget _page(BuildContext context, ArcDestination destination, int index) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(destination.label, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('destination $index', style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

/// Resize the use case (or switch viewport) to watch the presentation change:
/// each style resolves width using its own platform's breakpoints.
@widgetbook.UseCase(
  name: 'App Store',
  type: ArcNavigation,
  path: '[Components]',
)
Widget buildArcNavigationUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final preserve = context.knobs.boolean(
    label: 'Preserve stacks',
    initialValue: true,
  );
  // objectOrNull, not object: `knobs.object.dropdown` unwraps with `!`, so a
  // null option would crash rather than mean "unset". Null here is the whole
  // point — it means resolve the presentation from width.
  final pinned = context.knobs.objectOrNull.dropdown<ArcNavPresentation>(
    label: 'Presentation',
    options: ArcNavPresentation.values,
    labelBuilder: (value) => value.name,
    description: 'Unset resolves from width using the style\'s breakpoints',
  );

  return LiquidGlassGuard(
    style: style,
    builder: (context) => ValueHarness<int>(
      initialValue: 0,
      builder: (context, selected, onChanged) => ArcNavigation(
        style: style,
        source: _appStore,
        presentation: pinned,
        preserveStacks: preserve,
        selectedIndex: selected,
        onDestinationSelected: onChanged,
        bodyBuilder: _page,
      ),
    ),
  );
}

/// More destinations than a bottom strip can hold, to exercise the 5-item cap
/// that neither CupertinoTabBar nor Material's NavigationBar enforces.
@widgetbook.UseCase(
  name: 'Overflow (More)',
  type: ArcNavigation,
  path: '[Components]',
)
Widget buildArcNavigationOverflowUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final count = context.knobs.int.slider(
    label: 'Destinations',
    initialValue: 8,
    min: 2,
    max: 12,
  );
  final maxTabs = context.knobs.int.slider(
    label: 'Max bottom tabs',
    initialValue: 5,
    min: 2,
    max: 8,
  );

  final source = ArcNavSource.sections([
    for (var i = 0; i < count; i++)
      ArcDestination(label: 'Item ${i + 1}', icon: const Icon(Icons.circle_outlined)),
  ]);

  return LiquidGlassGuard(
    style: style,
    builder: (context) => ValueHarness<int>(
      initialValue: 0,
      builder: (context, selected, onChanged) => ArcNavigation(
        style: style,
        source: source,
        maxBottomTabs: maxTabs,
        presentation: ArcNavPresentation.bottomTabs,
        selectedIndex: selected,
        onDestinationSelected: onChanged,
        bodyBuilder: _page,
      ),
    ),
  );
}

/// A data source — the Messages case. Never renders as tabs at any width.
@widgetbook.UseCase(
  name: 'Data source',
  type: ArcNavigation,
  path: '[Components]',
)
Widget buildArcNavigationDataUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final count = context.knobs.int.slider(
    label: 'Rows',
    initialValue: 200,
    min: 2,
    max: 2000,
  );

  final source = ArcNavSource.data(
    count: count,
    builder: (i) => ArcDestination(
      label: 'Conversation ${i + 1}',
      icon: const Icon(Icons.person_outline),
    ),
  );

  return LiquidGlassGuard(
    style: style,
    builder: (context) => ValueHarness<int>(
      initialValue: 0,
      builder: (context, selected, onChanged) => ArcNavigation(
        style: style,
        source: source,
        selectedIndex: selected,
        onDestinationSelected: onChanged,
        bodyBuilder: _page,
      ),
    ),
  );
}

/// Which presentations each style can actually draw. Rendered from the
/// registry so the holes stay honest as factories change.
@widgetbook.UseCase(
  name: 'Support matrix',
  type: ArcNavigation,
  path: '[Components]',
)
Widget buildArcNavigationMatrixUseCase(BuildContext context) {
  final matrix = NavigationStyleRegistry.supportMatrix;
  final theme = Theme.of(context);

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: DataTable(
      columns: [
        const DataColumn(label: Text('Style')),
        for (final presentation in ArcNavPresentation.values)
          DataColumn(label: Text(presentation.name)),
      ],
      rows: [
        for (final entry in matrix.entries)
          DataRow(
            cells: [
              DataCell(Text(uiStyleLabel(entry.key))),
              for (final presentation in ArcNavPresentation.values)
                DataCell(
                  entry.value.contains(presentation)
                      ? Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                      : Icon(
                          Icons.remove,
                          size: 18,
                          color: theme.colorScheme.outlineVariant,
                        ),
                ),
            ],
          ),
      ],
    ),
  );
}
