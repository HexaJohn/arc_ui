import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// A real SwiftUI `NavigationSplitView`, embedded in the Flutter tree.
///
/// This is the worked example of hosting a native view — the Swift half lives
/// in `macos/Runner/MainFlutterWindow.swift` — and it earns its place in the
/// bench besides: arc_ui's macOS sidebar is tuned by eye against Apple's own,
/// so having AppKit draw the real thing in the next pane makes the comparison
/// exact rather than remembered.
///
/// Worth knowing before reaching for one of these:
///
///  * It is a real NSView, composited *outside* Flutter's scene. Flutter
///    transforms — opacity, rotation, the sidebar's vibrancy punch-through —
///    do not apply to it, and it will not blur or fade with its surroundings.
///  * Construction is asynchronous. The widget paints nothing until the NSView
///    arrives, holding its constraints, so it must be given a bounded size.
///  * It is macOS-only, and a `viewType` with no registered factory fails as a
///    silent blank rectangle rather than an error — hence the guard below and
///    the shared constant on both sides.
class NativeSidebar extends StatelessWidget {
  const NativeSidebar({super.key});

  /// Must match `NativeSidebarFactory.viewType` in the Runner.
  static const viewType = 'arc_ui/native_sidebar';

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    if (!isSupported) {
      return Center(
        child: Text(
          'The native view is macOS-only.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return const AppKitView(
      viewType: viewType,
      // Without this the native view only receives events Flutter declines,
      // and a list is exactly the case where that fails: clicking a row is a
      // tap, but dragging the split divider is a pan, which an ancestor
      // scrollable would win. Eager hands every gesture straight to AppKit.
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
      },
    );
  }
}
