import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_window_utils/macos/ns_window_delegate.dart';
import 'package:macos_window_utils/ns_window_delegate_handler/ns_window_delegate_handle.dart';
import 'package:macos_window_utils/window_manipulator.dart';

/// Whether the window currently has focus.
///
/// macOS treats an unfocused window as a distinct visual state, and chrome is
/// expected to respond: an inactive window's sidebar picks up a tint that
/// separates it from the content, where an active one blends in.
class ArcWindowFocus extends InheritedWidget {
  const ArcWindowFocus({
    super.key,
    required this.isActive,
    required super.child,
  });

  final bool isActive;

  /// Defaults to active where no tracker is present, so widgets outside a
  /// macOS window render as they would in a focused one.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ArcWindowFocus>()?.isActive ??
      true;

  @override
  bool updateShouldNotify(ArcWindowFocus oldWidget) =>
      isActive != oldWidget.isActive;
}

/// Publishes [ArcWindowFocus] from AppKit's own main-window notifications.
///
/// Uses `NSWindowDelegate` rather than Flutter's [AppLifecycleState], which on
/// desktop conflates "window lost focus" with other transitions and is not a
/// reliable key-window signal.
class ArcWindowFocusTracker extends StatefulWidget {
  const ArcWindowFocusTracker({super.key, required this.child});

  final Widget child;

  @override
  State<ArcWindowFocusTracker> createState() => _ArcWindowFocusTrackerState();
}

class _ArcWindowFocusTrackerState extends State<ArcWindowFocusTracker> {
  bool _isActive = true;
  NSWindowDelegateHandle? _handle;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;

    _handle = WindowManipulator.addNSWindowDelegate(
      _ArcFocusDelegate(onChanged: _set),
    );

    // The delegate only reports *transitions*, and the window has usually
    // already become key before this tree mounts — so without seeding, that
    // first transition is missed and the panel starts in the wrong state.
    _reseed();
  }

  void _set(bool active) {
    if (mounted && active != _isActive) setState(() => _isActive = active);
  }

  /// Asks AppKit directly rather than trusting accumulated transitions.
  ///
  /// Re-run after the first frame as well as immediately: at `initState` the
  /// plugin channel may not have answered yet, and a window that is mid-launch
  /// reports itself as not main.
  void _reseed() {
    WindowManipulator.isMainWindow().then(_set);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) WindowManipulator.isMainWindow().then(_set);
    });
  }

  @override
  void dispose() {
    _handle?.removeFromHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ArcWindowFocus(isActive: _isActive, child: widget.child);
}

class _ArcFocusDelegate extends NSWindowDelegate {
  _ArcFocusDelegate({required this.onChanged});

  final ValueChanged<bool> onChanged;

  // Key *and* main are both tracked. AppKit distinguishes them — a panel can
  // be key without being main — but for a single-window app they move
  // together, and relying on only one of the pairs leaves the state stuck
  // whenever the other fires alone.
  @override
  void windowDidBecomeKey() => onChanged(true);

  @override
  void windowDidResignKey() => onChanged(false);

  @override
  void windowDidBecomeMain() => onChanged(true);

  @override
  void windowDidResignMain() => onChanged(false);
}
