import 'package:arc_ui/src/arc/icon.dart';
import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/sidebar_list.dart';
import 'package:arc_ui/src/arc/window_theme.dart';
import 'package:arc_ui/src/macos/floating_surface.dart';
import 'package:flutter/material.dart';

class MacOsNavigationFactory extends NavigationFactory {
  @override
  String get styleName => 'macOS';

  /// Arity one, at every width. macOS has no bottom tab bar and no rail, and
  /// this is not an omission in `macos_ui` — the HIG has no such control. The
  /// only near-miss, `MacosTabView`, is a bordered in-page panel whose
  /// `MacosTab` accepts a bare `String` and no icon, so using it for app-level
  /// navigation would be a lie.
  @override
  Set<ArcNavPresentation> get supportedPresentations => {
    ArcNavPresentation.sidebar,
  };

  @override
  ArcNavPresentation resolvePresentation({
    required double width,
    required ArcNavSource source,
  }) => ArcNavPresentation.sidebar;

  @override
  Widget createNavigation(ArcNavigationSpec spec) => _MacOsSidebar(spec: spec);
}

/// Space between the panel and the content that begins beside it.
const double _panelGutter = 24;

class _MacOsSidebar extends StatefulWidget {
  const _MacOsSidebar({required this.spec});

  final ArcNavigationSpec spec;

  @override
  State<_MacOsSidebar> createState() => _MacOsSidebarState();
}

class _MacOsSidebarState extends State<_MacOsSidebar> {
  /// Null until the user drags, so the style's width stays authoritative and
  /// a theme change is still picked up.
  double? _dragWidth;

  bool _collapsed = false;

  void _toggleCollapsed() => setState(() => _collapsed = !_collapsed);

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final style = ArcWindowTheme.sidebarOf(context);
    final panelWidth = (_dragWidth ?? style.width).clamp(
      style.minWidth,
      style.maxWidth,
    );
    // Deliberately NOT MacosWindow: it is a window frame and cannot be
    // embedded, and its Sidebar.windowBreakpoint defaults to 556, below which
    // the sidebar collapses to zero width with no rail, no hamburger and no
    // substitute — every destination becomes unreachable. That is data loss
    // rather than degradation, and arc_ui does not inherit it.
    //
    // A Stack, not a Row, in both layouts: the panel floats over the window
    // and the toggle has to be able to park outside it once it has slid away.
    // What changes is whether the body is given the whole window or only the
    // room left over — see [ArcSidebarContentLayout].
    final footprint = panelWidth + _panelGutter;
    final bleed = style.contentLayout == ArcSidebarContentLayout.bleed;

    // A single 0..1 drives the slide, so the panel's offset and the content's
    // inset can never disagree mid-animation.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _collapsed ? 0.0 : 1.0),
      duration: _slideDuration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final surfaceWidth = panelWidth + style.inset * 2;
        final slid = -surfaceWidth * (1 - t);

        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Builder(
                builder: (context) {
                  final media = MediaQuery.of(context);
                  // Published either way, so a body written against one layout
                  // is correct in the other: in `bleed` it is the distance the
                  // body must keep clear of the panel, and in `inset` that
                  // distance has already been taken out of its constraints, so
                  // it is zero. A body that adds `paddingOf(context).left` is
                  // right in both; one that ignores it is only wrong in the
                  // layout that advertises the hazard.
                  final child = MediaQuery(
                    data: media.copyWith(
                      padding: media.padding.copyWith(
                        left: bleed ? footprint * t : 0,
                      ),
                    ),
                    child: spec.body,
                  );

                  return bleed
                      ? child
                      : Padding(
                          padding: EdgeInsets.only(left: footprint * t),
                          child: child,
                        );
                },
              ),
            ),
            Positioned(
              left: slid,
              top: 0,
              bottom: 0,
              width: surfaceWidth,
              child: ArcFloatingSidebarSurface(
                child: ArcSidebarList(
                  spec: spec,
                  width: panelWidth,
                  topPadding: style.contentTopInset,
                ),
              ),
            ),
            // Only while open: a grip floating over the content would be a
            // dead drag target with nothing to resize.
            if (t > 0.99)
              Positioned(
                left: footprint - _panelGutter / 2 - _gripWidth / 2,
                top: 0,
                bottom: 0,
                width: _gripWidth,
                child: _ResizeGrip(
                  onDelta: (dx) => setState(
                    () => _dragWidth = (panelWidth + dx).clamp(
                      style.minWidth,
                      style.maxWidth,
                    ),
                  ),
                ),
              ),
            if (style.collapsible)
              // Travels with the panel: parked at its trailing edge while
              // open, and left behind in the titlebar band once it has slid
              // away — otherwise collapsing would strip the only way back.
              Positioned(
                left:
                    _collapsedToggleLeft +
                    (surfaceWidth -
                            _toggleSize -
                            style.inset * 2 -
                            _collapsedToggleLeft) *
                        t,
                top: style.topInset + _toggleTop,
                child: _SidebarToggle(onPressed: _toggleCollapsed),
              ),
          ],
        );
      },
    );
  }
}

/// Hit width of the resize grip. Wider than it looks so the drag is easy to
/// catch; it paints nothing of its own.
const double _gripWidth = 10;

class _ResizeGrip extends StatelessWidget {
  const _ResizeGrip({required this.onDelta});

  final ValueChanged<double> onDelta;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // Horizontal-only, so a vertical flick scrolls the list behind rather
        // than being swallowed as a resize.
        onHorizontalDragUpdate: (details) => onDelta(details.delta.dx),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// How long the panel takes to slide in or out.
const Duration _slideDuration = Duration(milliseconds: 260);

/// Distance from the panel's top edge to the toggle.
///
/// Fixed rather than derived from [ArcFloatingSidebarStyle.contentTopInset]:
/// that inset positions the *list*, and tying the control to it made the
/// button climb whenever the list was tightened. This aligns with the window
/// buttons, which AppKit places at a fixed height.
const double _toggleTop = 10;

/// Size of the show/hide-sidebar control.
const double _toggleSize = 30;

/// Where the toggle parks once the panel is gone: clear of the traffic lights,
/// which macOS positions at the window's top-left and which no API here moves
/// out of the way.
const double _collapsedToggleLeft = 84;

class _SidebarToggle extends StatelessWidget {
  const _SidebarToggle({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: _toggleSize,
          height: _toggleSize,
          child: Center(
            child: ArcIcon(ArcIcons.sidebarToggle, size: 20, color: onSurface),
          ),
        ),
      ),
    );
  }
}
