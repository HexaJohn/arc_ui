import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Feeds [ArcSystemPreferences] from the real macOS settings.
///
/// arc_ui cannot read them itself — they are `NSUserDefaults` keys and it has
/// no native side — so the app supplies them. The Swift half lives in
/// `macos/Runner/MainFlutterWindow.swift`.
///
/// Anywhere else this is a pass-through, and arc_ui's defaults apply.
class MacosSystemPreferences extends StatefulWidget {
  const MacosSystemPreferences({super.key, required this.child});

  final Widget child;

  @override
  State<MacosSystemPreferences> createState() => _MacosSystemPreferencesState();
}

class _MacosSystemPreferencesState extends State<MacosSystemPreferences> {
  static const _channel = MethodChannel('arc_ui/system_preferences');

  ArcSidebarItemSize _sidebarItemSize = ArcSidebarItemSize.medium;
  ArcScrollbarVisibility _scrollbarVisibility =
      ArcScrollbarVisibility.automatic;
  ArcScrollbarPaging _scrollbarPaging = ArcScrollbarPaging.nextPage;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (!_supported) return;

    // The native side pushes on change as well as answering a read, so the
    // handler is installed before the first request rather than after.
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'changed') _apply(call.arguments);
    });
    _read();
  }

  @override
  void dispose() {
    if (_supported) _channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _read() async {
    try {
      _apply(await _channel.invokeMethod<Map<Object?, Object?>>('read'));
    } on PlatformException {
      // An app that has not wired the native half still runs, on arc_ui's
      // defaults — this is a refinement, not a requirement.
    } on MissingPluginException {
      // Same, for a host binary built before the channel existed.
    }
  }

  void _apply(Object? raw) {
    if (!mounted || raw is! Map) return;

    final sidebarItemSize = switch (raw['sidebarIconSize']) {
      1 => ArcSidebarItemSize.small,
      3 => ArcSidebarItemSize.large,
      _ => ArcSidebarItemSize.medium,
    };
    final visibility = switch (raw['showScrollBars']) {
      'WhenScrolling' => ArcScrollbarVisibility.whenScrolling,
      'Always' => ArcScrollbarVisibility.always,
      _ => ArcScrollbarVisibility.automatic,
    };
    final paging =
        raw['scrollerPagingToSpot'] == true
            ? ArcScrollbarPaging.spotClicked
            : ArcScrollbarPaging.nextPage;

    if (sidebarItemSize == _sidebarItemSize &&
        visibility == _scrollbarVisibility &&
        paging == _scrollbarPaging) {
      return;
    }

    setState(() {
      _sidebarItemSize = sidebarItemSize;
      _scrollbarVisibility = visibility;
      _scrollbarPaging = paging;
    });
  }

  @override
  Widget build(BuildContext context) => ArcSystemPreferences(
    sidebarItemSize: _sidebarItemSize,
    scrollbarVisibility: _scrollbarVisibility,
    scrollbarPaging: _scrollbarPaging,
    child: widget.child,
  );
}
