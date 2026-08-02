import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import '../addons/ui_style_addon.dart';
import '../helpers/liquid_glass_guard.dart';
import '../helpers/value_harness.dart';

final _mail = ArcNavSource.sections([
  const ArcDestination(
    label: 'Inbox',
    icon: Icon(Icons.inbox_outlined),
    group: 'Mailboxes',
  ),
  const ArcDestination(
    label: 'Sent',
    icon: Icon(Icons.send_outlined),
    group: 'Mailboxes',
  ),
  const ArcDestination(
    label: 'Drafts',
    icon: Icon(Icons.drafts_outlined),
    group: 'Mailboxes',
  ),
  const ArcDestination(
    label: 'Archive',
    icon: Icon(Icons.archive_outlined),
    group: 'Folders',
  ),
]);

Widget _page(BuildContext context, ArcDestination destination, int index) =>
    Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            destination.label,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const SizedBox(
            width: 280,
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Focus me, then use the Edit menu',
              ),
            ),
          ),
        ],
      ),
    );

/// A full application window: menu bar, navigation and search.
///
/// The macOS menu bar only appears when actually running on macOS — Flutter's
/// PlatformMenuBar renders nothing anywhere else — so this use case falls back
/// to an in-window bar to stay inspectable in the sandbox.
@widgetbook.UseCase(name: 'Mail', type: ArcWindow, path: '[Components]')
Widget buildArcWindowUseCase(BuildContext context) {
  final style = ArcStyleScope.of(context);
  final showSearch = context.knobs.boolean(
    label: 'Show search',
    initialValue: true,
  );
  final showMenus = context.knobs.boolean(
    label: 'Show menus',
    initialValue: true,
  );

  return LiquidGlassGuard(
    style: style,
    builder: (context) => ValueHarness<int>(
      initialValue: 0,
      builder: (context, selected, onChanged) => ArcWindow(
        style: style,
        navigation: _mail,
        selectedIndex: selected,
        onDestinationSelected: onChanged,
        bodyBuilder: _page,
        showSearch: showSearch,
        searchPlaceholder: 'Search mail',
        menus: showMenus
            ? ArcMenus.standard(
                appName: 'Arc Mail',
                onNew: () {},
                onOpen: () {},
                onSave: () {},
              )
            : const [],
      ),
    ),
  );
}

/// What each style resolves its menu bar and search to, at the current width.
///
/// Rendered from the registry so it stays honest as factories change, and
/// recomputed on resize because both are width-dependent.
@widgetbook.UseCase(
  name: 'Chrome matrix',
  type: ArcWindow,
  path: '[Components]',
)
Widget buildArcWindowMatrixUseCase(BuildContext context) {
  final width = context.knobs.double.slider(
    label: 'Window width',
    initialValue: 1200,
    min: 320,
    max: 1600,
  );

  return SingleChildScrollView(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolved at ${width.round()}px',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          arcHasSystemMenuBar
              ? 'Running on macOS: a native system menu bar is available.'
              : 'No system menu bar on this platform — native resolves to inline.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        DataTable(
          columns: const [
            DataColumn(label: Text('Style')),
            DataColumn(label: Text('Menu bar')),
            DataColumn(label: Text('Search')),
          ],
          rows: [
            for (final style in WindowStyleRegistry.availableStyles)
              DataRow(
                cells: [
                  DataCell(Text(uiStyleLabel(style))),
                  DataCell(
                    Text(
                      WindowStyleRegistry.getFactory(style)!
                          .resolveMenuPresentation(width: width)
                          .name,
                    ),
                  ),
                  DataCell(
                    Text(
                      WindowStyleRegistry.getFactory(style)!
                          .resolveSearchPlacement(width: width)
                          .name,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    ),
  );
}
