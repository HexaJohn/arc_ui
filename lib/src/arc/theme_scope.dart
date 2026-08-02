import 'package:arc_ui/src/arc/accent.dart';
import 'package:arc_ui/src/macos/window_focus.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart' as macos;

/// Installs the theme and localization ancestors arc_ui's non-Material
/// factories require.
///
/// `PushButton` reaches for [macos.MacosTheme], the Fluent controls reach for
/// [fluent.FluentTheme], and the iOS ones for [CupertinoTheme]. Without these
/// every style except Material throws the moment it is rendered, so any app
/// using arc_ui needs this near its root — which is why it lives in the
/// package rather than being re-derived by each consumer.
///
/// It also injects [fluent.FluentLocalizations]. `NavigationView` throws
/// "No FluentLocalizations found" without it, and a [MaterialApp] supplies
/// only the Material and Cupertino delegates — so a Fluent-styled arc_ui app
/// inside a [MaterialApp] would otherwise fail as soon as it navigated.
///
/// Brightness is mirrored from the ambient Material [Theme] so that switching
/// light/dark moves all five design languages together.
class ArcTheme extends StatelessWidget {
  const ArcTheme({
    super.key,
    required this.child,
    this.primaryColor,
    this.fluentAccentColor,
  });

  final Widget child;

  /// Accent handed to [macos.MacosThemeData]. Defaults to [Colors.blue].
  final Color? primaryColor;

  /// Accent handed to [fluent.FluentThemeData]. Defaults to Fluent's blue.
  final fluent.AccentColor? fluentAccentColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    // override rather than a bare Localizations: this merges the Fluent
    // delegate into whatever the surrounding app already provides instead of
    // replacing the Material and Cupertino ones.
    return Localizations.override(
      context: context,
      delegates: const [fluent.FluentLocalizations.delegate],
      // Resolves the live macOS system accent, so a user running the red
      // accent gets red selection rather than a hardcoded blue.
      child: ArcSystemAccent(
        fallback: primaryColor ?? Colors.blue,
        // Publishes window focus, which macOS chrome responds to — the
        // sidebar tints itself when the window is not key.
        child: ArcWindowFocusTracker(
          child: Builder(
            builder: (context) => _themes(brightness, ArcAccent.of(context)),
          ),
        ),
      ),
    );
  }

  Widget _themes(Brightness brightness, Color accent) {
    return macos.MacosTheme(
      data: macos.MacosThemeData(
        brightness: brightness,
        primaryColor: accent,
      ),
      child: fluent.FluentTheme(
        data: fluent.FluentThemeData(
          brightness: brightness,
          accentColor: fluentAccentColor ?? fluent.Colors.blue,
        ),
        child: CupertinoTheme(
          data: CupertinoThemeData(brightness: brightness),
          child: child,
        ),
      ),
    );
  }
}
