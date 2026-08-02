import 'package:arc_ui/src/arc/window_theme.dart';
import 'package:flutter/widgets.dart';

/// macOS "Show scroll bars" (`AppleShowScrollBars`).
///
/// Reported for callers that want it, but arc_ui does not act on it: honouring
/// it means wrapping scrollables in an explicit [Scrollbar], which needs the
/// scrollable's own controller and stacks on top of the one ScrollBehavior
/// already provides. Getting that wrong breaks dragging outright, and the
/// default behaviour is close enough that the trade was not worth it.
enum ArcScrollbarVisibility {
  /// Shown when a mouse is attached, hidden for a trackpad.
  automatic,

  /// Overlay only, fading in while scrolling.
  whenScrolling,

  /// Always visible, taking layout space.
  always,
}

/// macOS "Click in the scroll bar to" (`AppleScrollerPagingBehavior`).
enum ArcScrollbarPaging {
  /// Jump to the next page.
  nextPage,

  /// Jump to the spot that's clicked.
  spotClicked,
}

/// Operating-system preferences arc_ui honours where it can.
///
/// These live in `NSUserDefaults` — `NSTableViewDefaultSizeMode`,
/// `AppleShowScrollBars`, `AppleScrollerPagingBehavior` — and arc_ui is a pure
/// Dart package with no native side, so it cannot read them itself. Shelling
/// out to `defaults` is not a way around it either: a Flutter macOS app ships
/// with the App Sandbox enabled, which blocks it.
///
/// So they are supplied rather than detected. An app that cares about matching
/// the system exactly reads them over its own platform channel and wraps its
/// tree in one of these; everything below then adapts. Without it the defaults
/// apply, which match macOS's own out-of-the-box values.
class ArcSystemPreferences extends InheritedWidget {
  const ArcSystemPreferences({
    super.key,
    this.scrollbarVisibility = ArcScrollbarVisibility.automatic,
    this.scrollbarPaging = ArcScrollbarPaging.nextPage,
    this.sidebarItemSize = ArcSidebarItemSize.medium,
    required super.child,
  });

  final ArcScrollbarVisibility scrollbarVisibility;
  final ArcScrollbarPaging scrollbarPaging;

  /// Row density for source lists, unless a nearer [ArcWindowTheme] overrides
  /// it — an explicit design choice beats the system preference.
  final ArcSidebarItemSize sidebarItemSize;

  static ArcSystemPreferences? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ArcSystemPreferences>();

  static ArcScrollbarVisibility scrollbarVisibilityOf(BuildContext context) =>
      maybeOf(context)?.scrollbarVisibility ?? ArcScrollbarVisibility.automatic;

  static ArcScrollbarPaging scrollbarPagingOf(BuildContext context) =>
      maybeOf(context)?.scrollbarPaging ?? ArcScrollbarPaging.nextPage;

  @override
  bool updateShouldNotify(ArcSystemPreferences oldWidget) =>
      scrollbarVisibility != oldWidget.scrollbarVisibility ||
      scrollbarPaging != oldWidget.scrollbarPaging ||
      sidebarItemSize != oldWidget.sidebarItemSize;
}
