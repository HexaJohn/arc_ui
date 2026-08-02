import 'package:arc_ui/src/arc/system_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_material.dart';

/// Row density for a source list, mirroring macOS's own Sidebar icon size.
///
/// macOS exposes this in System Settings > Appearance, storing it in the
/// `NSTableViewDefaultSizeMode` user default. Reading that requires
/// `NSUserDefaults`, which no Dart package here exposes — and shelling out to
/// `defaults` is blocked by the App Sandbox — so arc_ui cannot follow the OS
/// setting on its own without becoming a native plugin.
///
/// Instead it is themeable, and [ArcWindowTheme.sidebarItemSize] can be fed
/// from an app's own platform channel where following the OS matters. The
/// default matches macOS's.
enum ArcSidebarItemSize {
  small(iconSize: 13, fontSize: 12, verticalPadding: 2),
  medium(iconSize: 16, fontSize: 13, verticalPadding: 4),
  large(iconSize: 20, fontSize: 14, verticalPadding: 6);

  const ArcSidebarItemSize({
    required this.iconSize,
    required this.fontSize,
    required this.verticalPadding,
  });

  final double iconSize;
  final double fontSize;
  final double verticalPadding;
}

/// Where the body sits relative to the floating sidebar.
enum ArcSidebarContentLayout {
  /// The body is laid out beside the panel, in the room left over.
  ///
  /// The default, because it is the only one that behaves the way dropping a
  /// widget into a slot is expected to: an existing layout handed to
  /// [ArcWindow.bodyBuilder] lands next to the sidebar and resizes with it,
  /// with no cooperation required from the body itself.
  inset,

  /// The body fills the window and runs full-bleed *underneath* the panel.
  ///
  /// What macOS actually does, and what gives the panel's backdrop filter
  /// something of the app's own to blur — beside it there would be nothing
  /// behind the panel but flat window background, and the bleed would be
  /// invisible at any sigma.
  ///
  /// The cost is that the body becomes responsible for keeping itself clear of
  /// the panel: the inset is published as `MediaQuery.paddingOf(context).left`
  /// and a body that ignores it is drawn underneath the sidebar. That is the
  /// standard Flutter idiom for content beneath chrome, and it is also a trap,
  /// which is why it is opt-in rather than the default.
  ///
  /// Read it from *inside* the body, not from the `context` handed to
  /// [ArcWindow.bodyBuilder]. That context belongs to [ArcNavigation], which
  /// sits above the sidebar and therefore above the padding — asking it
  /// reports 0 no matter which layout is in force. A `LayoutBuilder` or
  /// `Builder` at the top of the body gives a context that sees it, and is
  /// wanted anyway for the width.
  bleed,
}

/// The look of the macOS floating sidebar surface.
///
/// Exposed as a theme rather than hard-coded so the chrome can be tuned live
/// and the settled values promoted to defaults here.
@immutable
class ArcFloatingSidebarStyle {
  const ArcFloatingSidebarStyle({
    this.contentLayout = ArcSidebarContentLayout.inset,
    this.inset = 8,
    this.topInset = 8,
    this.contentTopInset = 22,
    this.radius = 18,
    this.blurSigma = 60,
    this.tintOpacity = 0,
    this.vibrancyAmount = 0.75,
    this.inactiveTintOpacity = 0.08,
    this.inactiveContentOpacity = 0.5,
    this.collapsible = true,
    this.width = 240,
    this.minWidth = 180,
    this.maxWidth = 420,
    this.material = NSVisualEffectViewMaterial.windowBackground,
    this.borderOpacity = 0.08,
    this.vibrancy = true,
  });

  /// Whether the body sits beside the panel or runs underneath it.
  final ArcSidebarContentLayout contentLayout;

  /// Gap between the sidebar and the left/bottom window edges.
  final double inset;

  /// Gap above the sidebar.
  ///
  /// Kept separate from [inset] so the panel's top edge can be tuned on its
  /// own; the room for the window buttons is [contentTopInset], not this.
  final double topInset;

  /// Padding *inside* the panel, above its content.
  ///
  /// macOS draws the close/minimise/zoom buttons over the top-left of the
  /// window, and a floating sidebar sits underneath them — so the panel
  /// extends up behind the buttons and its contents start below. Insetting the
  /// whole panel instead would push it away from the top edge and leave the
  /// buttons stranded on the window background.
  ///
  /// Assumes the host has enabled a full-size content view; set to zero for a
  /// window with a conventional title bar.
  final double contentTopInset;

  final double radius;

  /// Blur applied to the app's *own* content showing through the panel.
  ///
  /// Large by design: macOS bleeds the content beside a sidebar into it as a
  /// very diffuse wash, which needs a far bigger sigma than a normal frosted
  /// panel. Only meaningful when some of the panel is not cleared to the
  /// native material — see [vibrancyAmount].
  final double blurSigma;

  /// How much of the panel is cleared through to the native material, versus
  /// left showing the blurred app content behind it.
  ///
  /// At 1.0 the panel is pure `NSVisualEffectView` and samples only the
  /// desktop; at 0.0 it is pure [BackdropFilter] over the app's own pixels.
  /// In between, both compose — which is what produces the content bleed while
  /// keeping the material's response to window focus.
  final double vibrancyAmount;

  /// Opacity of the panel's contents while the window is not focused.
  ///
  /// macOS fades a sidebar's items along with tinting the panel — the whole
  /// region recedes rather than just its background changing.
  final double inactiveContentOpacity;

  /// Whether the panel can be hidden.
  ///
  /// When true a toggle is shown: inside the panel while it is open, and in
  /// the window's titlebar band once it has slid away — otherwise collapsing
  /// it would leave no way back.
  final bool collapsible;

  /// Starting width of the panel's list.
  final double width;

  /// Bounds the user can drag the panel between.
  ///
  /// macOS source lists are resizable and clamp rather than letting the user
  /// collapse them into nothing.
  final double minWidth;
  final double maxWidth;

  /// Tint applied while the window is *not* focused.
  ///
  /// macOS separates an inactive window's sidebar from its content, where an
  /// active one blends in. AppKit's own inactive treatment flattens the
  /// material to the window colour, which erases the panel entirely — so the
  /// distinction is drawn here instead.
  final double inactiveTintOpacity;

  /// Which `NSVisualEffectView` material backs the panel.
  ///
  /// Defaults to `windowBackground` rather than `sidebar`: the sidebar
  /// material is deliberately lighter than the window's, so a floating panel
  /// using it reads as brighter than everything around it no matter how far
  /// the tint is turned down. Matching the window's own material is what makes
  /// the panel disappear into it while the window is active, and still pick up
  /// AppKit's inactive treatment when it is not.
  final NSVisualEffectViewMaterial material;

  /// Strength of the white (dark mode) or black (light mode) tint over the
  /// blur.
  final double tintOpacity;

  final double borderOpacity;

  /// Use a real `NSVisualEffectView` behind the panel instead of a
  /// [BackdropFilter].
  ///
  /// This is the difference between sampling the desktop wallpaper behind the
  /// window and merely blurring the app's own pixels — only the former is what
  /// macOS actually does. It requires a macOS host whose window background has
  /// been cleared; everywhere else the blur fallback is used automatically.
  final bool vibrancy;

  ArcFloatingSidebarStyle copyWith({
    ArcSidebarContentLayout? contentLayout,
    double? inset,
    double? topInset,
    double? contentTopInset,
    double? radius,
    double? blurSigma,
    double? tintOpacity,
    double? borderOpacity,
    bool? vibrancy,
    double? vibrancyAmount,
    double? inactiveTintOpacity,
    double? inactiveContentOpacity,
    bool? collapsible,
    double? width,
    double? minWidth,
    double? maxWidth,
    NSVisualEffectViewMaterial? material,
  }) => ArcFloatingSidebarStyle(
    contentLayout: contentLayout ?? this.contentLayout,
    inset: inset ?? this.inset,
    topInset: topInset ?? this.topInset,
    contentTopInset: contentTopInset ?? this.contentTopInset,
    radius: radius ?? this.radius,
    blurSigma: blurSigma ?? this.blurSigma,
    tintOpacity: tintOpacity ?? this.tintOpacity,
    borderOpacity: borderOpacity ?? this.borderOpacity,
    vibrancy: vibrancy ?? this.vibrancy,
    vibrancyAmount: vibrancyAmount ?? this.vibrancyAmount,
    inactiveTintOpacity: inactiveTintOpacity ?? this.inactiveTintOpacity,
    inactiveContentOpacity:
        inactiveContentOpacity ?? this.inactiveContentOpacity,
    collapsible: collapsible ?? this.collapsible,
    width: width ?? this.width,
    minWidth: minWidth ?? this.minWidth,
    maxWidth: maxWidth ?? this.maxWidth,
    material: material ?? this.material,
  );

  @override
  bool operator ==(Object other) =>
      other is ArcFloatingSidebarStyle &&
      other.contentLayout == contentLayout &&
      other.inset == inset &&
      other.topInset == topInset &&
      other.contentTopInset == contentTopInset &&
      other.radius == radius &&
      other.blurSigma == blurSigma &&
      other.tintOpacity == tintOpacity &&
      other.borderOpacity == borderOpacity &&
      other.vibrancy == vibrancy &&
      other.vibrancyAmount == vibrancyAmount &&
      other.inactiveTintOpacity == inactiveTintOpacity &&
      other.inactiveContentOpacity == inactiveContentOpacity &&
      other.collapsible == collapsible &&
      other.width == width &&
      other.minWidth == minWidth &&
      other.maxWidth == maxWidth &&
      other.material == material;

  @override
  int get hashCode => Object.hash(
    contentLayout,
    inset,
    topInset,
    contentTopInset,
    radius,
    blurSigma,
    tintOpacity,
    borderOpacity,
    vibrancy,
    vibrancyAmount,
    inactiveTintOpacity,
    inactiveContentOpacity,
    collapsible,
    width,
    minWidth,
    maxWidth,
    material,
  );
}

/// Supplies window chrome styling to the factories below it.
class ArcWindowTheme extends InheritedWidget {
  const ArcWindowTheme({
    super.key,
    this.floatingSidebar = const ArcFloatingSidebarStyle(),
    this.windowRadius = 16,
    this.tallTitlebar = true,
    this.sidebarItemSize,
    required super.child,
  });

  final ArcFloatingSidebarStyle floatingSidebar;

  /// Corner radius of the window surface itself.
  ///
  /// Only meaningful once the host has cleared the window background: the
  /// corners outside this radius become transparent, so the desktop shows
  /// through and the window reads as rounder than AppKit's own mask.
  final double windowRadius;

  /// Whether the macOS window grows its titlebar and drops its title.
  ///
  /// Applied only while the macOS design language is rendering — see
  /// [ArcMacosTitlebar] — since a taller titlebar leaves the window buttons
  /// mispositioned under any other style, and it is torn back down when
  /// another style takes over.
  ///
  /// On by default, because it is what the macOS style is: the traffic lights
  /// sit over the floating sidebar, the toolbar band holds the search pill and
  /// the collapse toggle, and no title is drawn. Off gives a conventional
  /// AppKit titlebar with the window's title in it.
  ///
  /// **Requires `WindowManipulator.initialize()` to have run in `main()`.**
  /// Every call otherwise waits forever on a completer nothing resolves. The
  /// waiting is harmless — the futures are pending, not blocking, so the app
  /// still runs — but the titlebar simply never changes, which reads as this
  /// flag being ignored rather than as a missing setup call.
  final bool tallTitlebar;

  /// Row density for source lists below this theme.
  ///
  /// Null defers to [ArcSystemPreferences], so an app feeding the OS setting
  /// in gets it honoured while an explicit design choice still wins.
  final ArcSidebarItemSize? sidebarItemSize;

  /// The ambient sidebar row density: theme first, then system preference.
  static ArcSidebarItemSize sidebarItemSizeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ArcWindowTheme>()
          ?.sidebarItemSize ??
      ArcSystemPreferences.maybeOf(context)?.sidebarItemSize ??
      ArcSidebarItemSize.medium;

  /// The ambient tall-titlebar preference, off unless a theme opts in.
  static bool tallTitlebarOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ArcWindowTheme>()
          ?.tallTitlebar ??
      false;

  /// The ambient window radius, or the default when no [ArcWindowTheme] is
  /// present.
  static double radiusOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ArcWindowTheme>()
          ?.windowRadius ??
      16;

  /// The ambient floating-sidebar style, or the defaults when no
  /// [ArcWindowTheme] is present.
  static ArcFloatingSidebarStyle sidebarOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<ArcWindowTheme>()
          ?.floatingSidebar ??
      const ArcFloatingSidebarStyle();

  @override
  bool updateShouldNotify(ArcWindowTheme oldWidget) =>
      floatingSidebar != oldWidget.floatingSidebar ||
      windowRadius != oldWidget.windowRadius ||
      tallTitlebar != oldWidget.tallTitlebar ||
      sidebarItemSize != oldWidget.sidebarItemSize;
}
