import 'package:arc_ui/arc_ui.dart';
import 'package:example/system_preferences.dart';
import 'package:example/views/window_bench.dart';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_material.dart';
import 'package:macos_window_utils/window_manipulator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // enableWindowDelegate defaults to false, and without it the native
  // FlutterWindowDelegate is never created — so NSWindowDelegate callbacks
  // (including focus changes) silently never arrive.
  await WindowManipulator.initialize(enableWindowDelegate: true);
  // The floating sidebar wants to sit against the window's own background
  // rather than a title bar, so the content view runs full height and the
  // sidebar reserves room for the traffic lights via its topInset.
  WindowManipulator.makeTitlebarTransparent();
  WindowManipulator.enableFullSizeContentView();
  // Required for the sidebar's vibrancy: the panel punches a transparent hole
  // in the Flutter canvas, and only a cleared window background lets the
  // NSVisualEffectView behind it — and the desktop behind that — show through.
  // Without this the hole would reveal an opaque window and the panel would
  // read as a black rectangle.
  await WindowManipulator.setWindowBackgroundColorToClear();
  // macOS apps built around a floating sidebar show no window title — the
  // close/minimise/zoom buttons sit over the panel and nothing else does.
  await WindowManipulator.hideTitle();
  // Matches the bench's default background mode (wallpaper tint), which
  // supplies its own subview material — this is the window-level fallback.
  await WindowManipulator.setMaterial(
    NSVisualEffectViewMaterial.windowBackground,
  );
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  Brightness _brightness = Brightness.dark;

  @override
  void initState() {
    super.initState();
    _syncWindowBrightness();
  }

  /// Keeps the native vibrancy in step with the Flutter theme.
  ///
  /// An NSVisualEffectView derives its light/dark treatment from the window's
  /// appearance, which follows the system setting — so toggling the app's own
  /// ThemeData alone leaves the vibrancy stuck in the wrong mode.
  void _syncWindowBrightness() {
    WindowManipulator.overrideMacOSBrightness(
      dark: _brightness == Brightness.dark,
    );
  }

  void _setBrightness(Brightness value) {
    setState(() => _brightness = value);
    _syncWindowBrightness();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arc Mail',
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: _brightness,
        ),
      ),
      // MacosSystemPreferences supplies the macOS settings arc_ui cannot read
      // itself, so sidebar density and scrollbar visibility follow System
      // Settings. ArcTheme then installs the MacosTheme / FluentTheme /
      // CupertinoTheme ancestors the non-Material factories require, mirroring
      // the brightness above so all five design languages move together.
      home: MacosSystemPreferences(
        child: ArcTheme(
          child: WindowBench(
            brightness: _brightness,
            onBrightnessChanged: _setBrightness,
          ),
        ),
      ),
    );
  }
}
