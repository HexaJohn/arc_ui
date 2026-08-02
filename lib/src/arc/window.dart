import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/registry/window.dart';
import 'package:arc_ui/src/arc/menu.dart';
import 'package:arc_ui/src/arc/navigation.dart';
import 'package:flutter/material.dart';

/// How a style draws its menu bar.
enum ArcMenuPresentation {
  /// No menu bar at all. iOS and Android have no equivalent concept, so it is
  /// omitted rather than substituted.
  none,

  /// The real system menu bar at the top of the screen, via [PlatformMenuBar].
  native,

  /// Drawn inside the window, the legacy Windows and KDE pattern.
  inline,
}

/// Where a style puts the search field.
enum ArcSearchPlacement {
  /// Above the destination list — the leading item of a sidebar or pane.
  navigationLeading,

  /// Above the content area.
  contentTop,

  /// Floating over the content, anchored to the bottom.
  floatingBottom,

  /// A pill in the window's top-right corner, in the titlebar band.
  ///
  /// The other place macOS parks search: Mail and Finder put it here, while
  /// System Settings and the App Store put it in the navigation pane. Both are
  /// idiomatic, so which one applies is the developer's call rather than
  /// something the style can infer.
  windowTrailing,

  /// Not shown.
  none,
}

/// An application window: menu bar, navigation and content, adapted per style.
///
/// This sits *above* [ArcNavigation] rather than replacing it — the window owns
/// the chrome a desktop has and a phone does not, and hands the destination
/// list straight through. On iOS and Android, where there is no window and no
/// menu bar, [ArcWindow] degrades to exactly the navigation shell.
///
/// **This is an app-root singleton on macOS.** Flutter permits only one active
/// [PlatformMenuBar] — a second trips
/// "More than one active PlatformMenuBar detected" — so [ArcWindow]s must not
/// be nested when [menus] are supplied.
class ArcWindow extends StatefulWidget {
  const ArcWindow({
    super.key,
    required this.navigation,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.bodyBuilder,
    this.style = UIStyle.material,
    this.menus = const <ArcMenu>[],
    this.showSearch = false,
    this.searchPlacement,
    this.onSearchChanged,
    this.searchPlaceholder = 'Search',
    this.presentation,
    this.presentationOverrides = const <UIStyle, ArcNavPresentation>{},
    this.preserveStacks = true,
    this.onChildSelected,
  });

  /// The destination list, handed to [ArcNavigation].
  final ArcNavSource navigation;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final ArcNavBodyBuilder bodyBuilder;

  /// The design language.
  final UIStyle style;

  /// Menu bar contents. Pruned of platform-provided items the running platform
  /// cannot draw before any factory sees them.
  final List<ArcMenu> menus;

  /// Whether to show a search field. Where it lands is the style's decision —
  /// a sidebar's leading slot on desktop, floating at the bottom on Liquid
  /// Glass — which is why this is a window-level flag rather than a parameter
  /// on the destination list.
  final bool showSearch;

  /// Pins where search appears, overriding the style's own choice.
  ///
  /// Leave null to let the factory decide from width.
  final ArcSearchPlacement? searchPlacement;

  final ValueChanged<String>? onSearchChanged;
  final String searchPlaceholder;

  /// Forwarded to [ArcNavigation].
  final ArcNavPresentation? presentation;
  final Map<UIStyle, ArcNavPresentation> presentationOverrides;
  final bool preserveStacks;
  final void Function(int parentIndex, int childIndex)? onChildSelected;

  @override
  State<ArcWindow> createState() => _ArcWindowState();
}

class _ArcWindowState extends State<ArcWindow> {
  late final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final factory = WindowStyleRegistry.getFactory(widget.style);
    if (factory == null) {
      return const Center(child: Text('(Unsupported Style)'));
    }

    // Pruned once, here, so no factory repeats the guard — and so a menu left
    // empty by pruning disappears instead of showing as a dead label.
    final menus = widget.menus.isEmpty
        ? const <ArcMenu>[]
        : pruneMenus(widget.menus);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        return factory.createWindow(
          ArcWindowSpec(
            menus: menus,
            menuPresentation: menus.isEmpty
                ? ArcMenuPresentation.none
                : factory.resolveMenuPresentation(width: width),
            searchPlacement: !widget.showSearch
                ? ArcSearchPlacement.none
                : widget.searchPlacement ??
                      factory.resolveSearchPlacement(width: width),
            searchController: _search,
            onSearchChanged: widget.onSearchChanged,
            searchPlaceholder: widget.searchPlaceholder,
            navigation: widget.navigation,
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            onChildSelected: widget.onChildSelected,
            bodyBuilder: widget.bodyBuilder,
            style: widget.style,
            presentation: widget.presentation,
            presentationOverrides: widget.presentationOverrides,
            preserveStacks: widget.preserveStacks,
          ),
        );
      },
    );
  }
}

/// Everything a [WindowFactory] needs, resolved.
class ArcWindowSpec {
  const ArcWindowSpec({
    required this.menus,
    required this.menuPresentation,
    required this.searchPlacement,
    required this.searchController,
    required this.searchPlaceholder,
    required this.navigation,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.bodyBuilder,
    required this.style,
    required this.presentationOverrides,
    required this.preserveStacks,
    this.onSearchChanged,
    this.onChildSelected,
    this.presentation,
  });

  /// Already pruned; safe to render as-is.
  final List<ArcMenu> menus;
  final ArcMenuPresentation menuPresentation;

  final ArcSearchPlacement searchPlacement;
  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchPlaceholder;

  final ArcNavSource navigation;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final void Function(int parentIndex, int childIndex)? onChildSelected;
  final ArcNavBodyBuilder bodyBuilder;

  final UIStyle style;
  final ArcNavPresentation? presentation;
  final Map<UIStyle, ArcNavPresentation> presentationOverrides;
  final bool preserveStacks;

  /// Builds the navigation shell, optionally injecting [leading] above the
  /// destination list.
  ///
  /// Factories call this rather than constructing [ArcNavigation] themselves,
  /// so the window never duplicates presentation resolution or stack handling.
  Widget buildNavigation({Widget? leading}) => ArcNavigation(
    style: style,
    source: navigation,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    onChildSelected: onChildSelected,
    bodyBuilder: bodyBuilder,
    presentation: presentation,
    overrides: presentationOverrides,
    preserveStacks: preserveStacks,
    leading: leading,
  );
}

/// Abstract window factory for extensibility
abstract class WindowFactory {
  /// How this style draws a menu bar at [width].
  ///
  /// Styles that can use the system menu bar must check [arcHasSystemMenuBar]
  /// rather than assuming: [PlatformMenuBar] renders nothing and reports no
  /// error off macOS, so choosing `native` on Windows would silently produce
  /// no menu at all.
  ArcMenuPresentation resolveMenuPresentation({required double width});

  /// Where this style puts the search field at [width].
  ArcSearchPlacement resolveSearchPlacement({required double width});

  Widget createWindow(ArcWindowSpec spec);

  String get styleName;
}
