import 'package:arc_ui/src/arc/menu.dart';
import 'package:arc_ui/src/arc/menu_bar_widgets.dart';
import 'package:arc_ui/src/arc/window.dart';
import 'package:arc_ui/src/arc/window_theme.dart';
import 'package:arc_ui/src/macos/search_pill.dart';
import 'package:arc_ui/src/macos/titlebar.dart';
import 'package:flutter/material.dart';

class MacOsWindowFactory extends WindowFactory {
  @override
  String get styleName => 'macOS';

  /// Native when there is genuinely a system menu bar to talk to, inline
  /// otherwise.
  ///
  /// The fallback matters: [PlatformMenuBar] renders nothing and reports no
  /// error off macOS, so a macOS-styled app running on Windows would silently
  /// have no menus at all if this returned `native` unconditionally.
  @override
  ArcMenuPresentation resolveMenuPresentation({required double width}) =>
      arcHasSystemMenuBar
      ? ArcMenuPresentation.native
      : (width < 480 ? ArcMenuPresentation.none : ArcMenuPresentation.inline);

  /// Top right by default — where Mail and Finder put it. System Settings and
  /// the App Store use the navigation pane instead, so both are idiomatic and
  /// `ArcWindow.searchPlacement` overrides this either way.
  ///
  /// Below the threshold the titlebar cannot hold the field and the window
  /// buttons at once, so it moves into the pane rather than overlapping them.
  @override
  ArcSearchPlacement resolveSearchPlacement({required double width}) =>
      width < 560
      ? ArcSearchPlacement.navigationLeading
      : ArcSearchPlacement.windowTrailing;

  @override
  Widget createWindow(ArcWindowSpec spec) {
    // ArcSearchPill rather than MacosSearchField: see its doc comment — that
    // widget discards the colour and border of any decoration passed to it,
    // hardcodes a blue focus ring, and renders a tofu glyph unless the app
    // itself depends on cupertino_icons.
    //
    // The titlebar field is the larger of the two, matching macOS: Mail and
    // Finder give it noticeably more presence than a sidebar's.
    ArcSearchPill search({required double height}) => ArcSearchPill(
      controller: spec.searchController,
      placeholder: spec.searchPlaceholder,
      onChanged: spec.onSearchChanged,
      height: height,
    );

    // The floating surface is applied by MacOsNavigationFactory around the
    // sidebar panel alone, not here — wrapping the whole shell would put the
    // content inside the panel too.
    Widget content = spec.buildNavigation(
      leading: spec.searchPlacement == ArcSearchPlacement.navigationLeading
          ? search(height: 24)
          : null,
    );

    if (spec.searchPlacement == ArcSearchPlacement.windowTrailing) {
      // Overlaid rather than laid out in a column: the titlebar band is the
      // content's own top edge once a full-size content view is enabled, so
      // reserving a row for it would push the content down instead.
      content = Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: 6,
            right: 12,
            child: SizedBox(width: 260, child: search(height: 30)),
          ),
        ],
      );
    }

    // Mounted here and nowhere else: the taller titlebar is macOS chrome, and
    // unmounting when another design language takes over is what tears it
    // back down.
    // Not mounted at all when off, rather than mounted-and-disabled: it
    // reaches for the host NSWindow, and an app that never opted in should not
    // have that machinery in its tree — including under a test binding, where
    // the plugin is uninitialised and its futures never resolve.
    // `inner` captured separately on purpose: a closure captures the
    // *variable*, so building the Builder out of `content` and then assigning
    // it back to `content` would make the Builder its own child — an infinite
    // tree, which presents as a hang rather than an obvious error.
    final inner = content;
    content = Builder(
      builder: (context) => ArcWindowTheme.tallTitlebarOf(context)
          ? ArcMacosTitlebar(child: inner)
          : inner,
    );

    return switch (spec.menuPresentation) {
      ArcMenuPresentation.native => ArcNativeMenuBar(
        menus: spec.menus,
        child: content,
      ),
      ArcMenuPresentation.inline => Column(
        children: [
          ArcInlineMenuBar(menus: spec.menus),
          Expanded(child: content),
        ],
      ),
      ArcMenuPresentation.none => content,
    };
  }
}
