import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'addons/ui_style_addon.dart';
import 'main.directories.g.dart';

void main() {
  runApp(const ArcWidgetbook());
}

@widgetbook.App()
class ArcWidgetbook extends StatelessWidget {
  const ArcWidgetbook({super.key, this.initialRoute = '/'});

  /// Which use case to open on launch. Exists so tests can mount a specific
  /// use case; the app itself starts on the default home page.
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      directories: directories,
      initialRoute: initialRoute,
      appBuilder: _appBuilder,
      addons: [
        // Addons wrap use cases in list order, and UIStyleAddon copies the
        // ambient brightness into the macOS/Fluent/Cupertino themes, so the
        // theme addon has to stay above it.
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: _themeFor(Brightness.light)),
            WidgetbookTheme(name: 'Dark', data: _themeFor(Brightness.dark)),
          ],
        ),
        UIStyleAddon(),
        ViewportAddon([
          Viewports.none,
          MacosViewports.macbookPro,
          WindowsViewports.desktop,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyS20,
        ]),
        AlignmentAddon(),
        TextScaleAddon(),
        ZoomAddon(),
        GridAddon(),
        InspectorAddon(),
      ],
    );
  }
}

/// The same seeded scheme the demo app uses, so the sandbox and
/// `example/lib/main.dart` render identically.
ThemeData _themeFor(Brightness brightness) => ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  ),
);

/// [Widgetbook.material]'s default builder plus the Fluent localizations, which
/// some `fluent_ui` widgets look up unconditionally.
Widget _appBuilder(BuildContext context, Widget child) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [
      fluent.FluentLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate,
      DefaultWidgetsLocalizations.delegate,
    ],
    home: Material(child: child),
  );
}
