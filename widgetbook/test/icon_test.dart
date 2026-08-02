import 'package:arc_ui/arc_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArcIconData resolves per design language', () {
    test('Apple styles share the Cupertino set', () {
      for (final style in [UIStyle.cupertino, UIStyle.macos, UIStyle.liquid]) {
        expect(
          ArcIcons.inbox.resolve(style),
          CupertinoIcons.tray,
          reason: '${style.name} did not use the Cupertino glyph',
        );
      }
    });

    test('Material and Fluent each get their own', () {
      expect(ArcIcons.inbox.resolve(UIStyle.material), Icons.inbox_outlined);
      expect(ArcIcons.inbox.resolve(UIStyle.fluent), FluentIcons.inbox);
    });

    test('unimplemented styles fall back rather than throwing', () {
      for (final style in [UIStyle.windows11, UIStyle.custom]) {
        expect(ArcIcons.inbox.resolve(style), isNotNull);
      }
    });

    test('every catalogue entry differs across the three sets', () {
      // A mapping that quietly reuses the Material glyph everywhere would
      // defeat the point, and is easy to introduce when adding entries.
      for (final entry in ArcIcons.all.entries) {
        final icon = entry.value;
        expect(
          icon.cupertino,
          isNot(icon.material),
          reason: '${entry.key} uses the Material glyph for Cupertino',
        );
        expect(
          icon.fluent,
          isNot(icon.material),
          reason: '${entry.key} uses the Material glyph for Fluent',
        );
      }
    });
  });

  testWidgets('ArcIcon follows the ambient style scope', (tester) async {
    Future<IconData> glyphFor(UIStyle style) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ArcStyleScope(
            style: style,
            child: const ArcIcon(ArcIcons.trash),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.widget<Icon>(find.byType(Icon)).icon!;
    }

    expect(await glyphFor(UIStyle.material), Icons.delete_outline);
    expect(await glyphFor(UIStyle.macos), CupertinoIcons.trash);
    expect(await glyphFor(UIStyle.fluent), FluentIcons.delete);
  });

  testWidgets('ArcNavigation publishes the scope its icons need', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // The caller builds the icon, outside any factory — so without the scope
    // it would silently render Material glyphs in a macOS sidebar.
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ArcTheme(
            child: ArcNavigation(
              style: UIStyle.macos,
              presentation: ArcNavPresentation.sidebar,
              source: ArcNavSource.sections(const [
                ArcDestination(label: 'Inbox', icon: ArcIcon(ArcIcons.inbox)),
                ArcDestination(label: 'Trash', icon: ArcIcon(ArcIcons.trash)),
              ]),
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              bodyBuilder: (context, destination, index) => const SizedBox(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final glyphs = tester
        .widgetList<Icon>(find.byType(Icon))
        .map((icon) => icon.icon)
        .toSet();
    expect(glyphs, contains(CupertinoIcons.tray));
    expect(glyphs, isNot(contains(Icons.inbox_outlined)));
  });
}
