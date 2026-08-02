import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_window_utils/macos/ns_window_toolbar_style.dart';
import 'package:macos_window_utils/window_manipulator.dart';

/// Grows the window's titlebar, and drops its title, for as long as it is
/// mounted.
///
/// AppKit exposes no way to set the traffic lights' frame — `macos_window_utils`
/// only ever hides or disables them — so the supported lever is titlebar
/// height: a unified `NSToolbar` makes the titlebar taller and AppKit
/// re-centres the buttons within it, moving them down and inward.
///
/// The title goes with it. A macOS app built around a floating sidebar shows
/// no window title — Mail, Finder and Notes all leave the band empty but for
/// the traffic lights and toolbar items — and leaving it drawn puts the app
/// name squarely on top of the sidebar the buttons are already sitting over.
/// It is restored on dispose along with the toolbar, so a style switch does
/// not strand the window without one.
///
/// This is a window-wide side effect, so it is scoped to the widget's
/// lifetime: mounted only by the macOS window factory, it applies when that
/// design language is in use and is torn down the moment another style takes
/// over. Leaving a Cupertino or Fluent window with a macOS-height titlebar
/// would strand the buttons in the wrong place.
class ArcMacosTitlebar extends StatefulWidget {
  const ArcMacosTitlebar({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<ArcMacosTitlebar> createState() => _ArcMacosTitlebarState();
}

class _ArcMacosTitlebarState extends State<ArcMacosTitlebar> {
  bool _applied = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ArcMacosTitlebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) _sync();
  }

  @override
  void dispose() {
    if (_applied) {
      WindowManipulator.removeToolbar();
      WindowManipulator.showTitle();
    }
    super.dispose();
  }

  Future<void> _sync() async {
    if (!_supported) return;

    if (widget.enabled && !_applied) {
      _applied = true;
      await WindowManipulator.addToolbar();
      await WindowManipulator.setToolbarStyle(
        toolbarStyle: NSWindowToolbarStyle.unified,
      );
      // After the toolbar, not before: adding one re-lays out the titlebar,
      // and hiding the title first leaves AppKit room it then fills back in.
      await WindowManipulator.hideTitle();
    } else if (!widget.enabled && _applied) {
      _applied = false;
      await WindowManipulator.removeToolbar();
      await WindowManipulator.showTitle();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
