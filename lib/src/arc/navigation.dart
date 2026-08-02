import 'package:arc_ui/registry/navigation.dart';
import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/icon.dart';
import 'package:flutter/material.dart';

/// A single top-level destination.
///
/// The model is deliberately shaped at macOS fidelity — a sidebar is the
/// richest presentation, supporting groups and one level of nesting — and every
/// other presentation is a lossy projection of it. Designing for bottom tabs
/// and extending upward would have made [children] and [group] unexpressible.
class ArcDestination {
  const ArcDestination({
    required this.label,
    this.icon,
    this.selectedIcon,
    this.group,
    this.badge,
    this.children = const <ArcDestination>[],
  });

  /// The destination's name. Presentations that can only show a string (macOS
  /// tabs, Cupertino) use it directly; the rest wrap it in a [Text].
  final String label;

  /// Shown alongside [label]. Bottom tab bars require one in practice, so a
  /// destination without an icon falls back to a placeholder rather than
  /// rendering a bare label in a tab strip.
  final Widget? icon;

  /// Substituted for [icon] while this destination is selected.
  final Widget? selectedIcon;

  /// Optional section title. Consecutive destinations sharing a [group] are
  /// rendered under one header by presentations that support sections, and the
  /// grouping is dropped by those that do not.
  final String? group;

  /// Trailing count or status, e.g. an unread tally.
  ///
  /// Only presentations with room show it — a sidebar row has a trailing edge
  /// to put it on, a tab in a strip does not.
  final String? badge;

  /// Sub-destinations, shown as disclosure children by sidebar presentations.
  ///
  /// These are never independently selectable: selecting one reports *this*
  /// destination's index. That is the "flatten to parent" rule, and it is what
  /// keeps a single `selectedIndex` meaningful in every presentation.
  final List<ArcDestination> children;
}

/// Describes what fills the navigation slot.
///
/// Sections and data are the same slot filled two ways, not two widgets: the
/// distinction only changes which presentations are legal and whether per
/// destination navigation stacks can be preserved.
sealed class ArcNavSource {
  const ArcNavSource();

  /// A small, authored set of app sections — the App Store / Music case.
  const factory ArcNavSource.sections(List<ArcDestination> destinations) =
      ArcSectionSource;

  /// A dynamic, potentially large list of content rows — the Messages / Mail
  /// case. Built lazily, so this stays viable at thousands of rows.
  const factory ArcNavSource.data({
    required int count,
    required ArcDestination Function(int index) builder,
  }) = ArcDataSource;

  /// How many top-level destinations exist.
  int get length;

  /// The destination at [index]. Must not be called with `index >= length`.
  ArcDestination destinationAt(int index);

  /// Whether this is a fixed set of app sections.
  ///
  /// Data sources cannot be rendered as tabs at any width — you cannot put
  /// three thousand conversations in a tab strip — and cannot have their
  /// navigation stacks preserved per row.
  bool get isSectioned;
}

/// A fixed set of app sections.
class ArcSectionSource extends ArcNavSource {
  const ArcSectionSource(this.destinations);

  final List<ArcDestination> destinations;

  @override
  int get length => destinations.length;

  @override
  ArcDestination destinationAt(int index) => destinations[index];

  @override
  bool get isSectioned => true;
}

/// A lazily built list of content destinations.
class ArcDataSource extends ArcNavSource {
  const ArcDataSource({required this.count, required this.builder});

  final int count;
  final ArcDestination Function(int index) builder;

  @override
  int get length => count;

  @override
  ArcDestination destinationAt(int index) => builder(index);

  @override
  bool get isSectioned => false;
}

/// Where and how the destination list is presented.
///
/// This is the *outcome*, not the request — the developer picks a [UIStyle]
/// and optionally pins a presentation; otherwise the style's own factory
/// resolves one from the available width using that platform's breakpoints.
enum ArcNavPresentation {
  /// A bar of tabs along the bottom edge. Phone-shaped.
  bottomTabs,

  /// A horizontal strip above the content. Tablet-shaped.
  topTabs,

  /// A narrow, icon-first vertical strip.
  rail,

  /// A full-width vertical list, with sections and disclosure where supported.
  sidebar,

  /// A sidebar that slides in over the content behind a menu affordance.
  drawer,
}

/// Presentations that render a flat strip and therefore cannot show
/// [ArcDestination.children] or [ArcDestination.group].
const Set<ArcNavPresentation> kFlatPresentations = {
  ArcNavPresentation.bottomTabs,
  ArcNavPresentation.topTabs,
  ArcNavPresentation.rail,
};

/// Preference order used when a resolved presentation is not supported by the
/// selected style. Walked left to right until a supported one is found.
const List<ArcNavPresentation> kPresentationFallback = [
  ArcNavPresentation.sidebar,
  ArcNavPresentation.drawer,
  ArcNavPresentation.rail,
  ArcNavPresentation.topTabs,
  ArcNavPresentation.bottomTabs,
];

/// Builds the page for a selected destination.
typedef ArcNavBodyBuilder =
    Widget Function(BuildContext context, ArcDestination destination, int index);

/// An adaptive top-level navigation shell.
///
/// This is a shell rather than a bar on purpose. In four of the five styles the
/// destination list is a region of the window frame rather than a placeable
/// widget — `CupertinoTabScaffold.tabBar` is typed to the concrete
/// `CupertinoTabBar`, `Sidebar` and `NavigationPane` are configuration objects
/// their frames consume — so there is no `ArcNavigationBar` to hand around.
/// What is portable is the destination list plus one integer of selection.
///
/// Two axes govern the result and they are handled differently. [style] is a
/// registry key, exactly as for every other arc_ui component. Form factor is
/// *not* a second key: it is resolved to an [ArcNavPresentation] by the factory
/// that [style] already selected, because the breakpoints are themselves
/// platform knowledge — Fluent's are 640/1008, macOS's is 556, Material's are
/// 600/840. Putting width in the registry would have moved that decision away
/// from the only code that knows the right answer.
class ArcNavigation extends StatefulWidget {
  const ArcNavigation({
    super.key,
    required this.source,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.bodyBuilder,
    this.style = UIStyle.material,
    this.presentation,
    this.overrides = const <UIStyle, ArcNavPresentation>{},
    this.preserveStacks = true,
    this.maxBottomTabs = 5,
    this.onChildSelected,
    this.leading,
  }) : assert(maxBottomTabs >= 2, 'A tab strip needs at least two tabs');

  /// What fills the navigation slot.
  final ArcNavSource source;

  /// The selected top-level destination.
  final int selectedIndex;

  /// Called when a different top-level destination is chosen. Selecting a
  /// nested child reports its parent's index here.
  final ValueChanged<int> onDestinationSelected;

  /// Builds the page for the selected destination.
  final ArcNavBodyBuilder bodyBuilder;

  /// The design language.
  final UIStyle style;

  /// Pins the presentation, disabling width-based resolution entirely.
  final ArcNavPresentation? presentation;

  /// Per-style presentation pins, for fine tuning one platform without
  /// affecting the others. Ignored where [presentation] is set.
  final Map<UIStyle, ArcNavPresentation> overrides;

  /// Whether each section keeps its own navigation stack across switches.
  ///
  /// Real platforms disagree here — the App Store returns you to where you
  /// were in a section, System Settings resets to the pane root — so this is a
  /// house rule rather than a native behaviour. It defaults to preserving,
  /// because users forgive a reset far more readily than silent state loss.
  ///
  /// Only meaningful for [ArcSectionSource]: preserving means keeping every
  /// section's subtree alive, which is impossible for a data source of
  /// arbitrary length, so those always share a single stack.
  final bool preserveStacks;

  /// How many tabs a bottom strip shows before collapsing the remainder behind
  /// a "More" tab.
  ///
  /// Neither `CupertinoTabBar` nor Material's `NavigationBar` enforces any
  /// maximum — Cupertino asserts a minimum of two and nothing else, and extra
  /// tabs simply get thinner until their labels clip. UIKit's own 5-then-More
  /// behaviour has no Flutter equivalent, so enforcing it is this widget's job.
  final int maxBottomTabs;

  /// Called when a nested child is chosen, with its parent and child indices.
  /// Purely additive: [onDestinationSelected] still fires with the parent.
  final void Function(int parentIndex, int childIndex)? onChildSelected;

  /// Placed above the destination list, typically a search field.
  ///
  /// Only presentations with a vertical list — sidebar, drawer, and an
  /// extended rail — have anywhere to put this; flat tab strips ignore it, and
  /// [ArcWindow] is expected to place search elsewhere in that case.
  final Widget? leading;

  @override
  State<ArcNavigation> createState() => _ArcNavigationState();
}

class _ArcNavigationState extends State<ArcNavigation> {
  /// Kept so that preserved sections survive a presentation change: the
  /// navigator for section 3 must be the same element whether it was reached
  /// from a sidebar or a tab bar.
  final Map<int, GlobalKey> _sectionKeys = <int, GlobalKey>{};

  GlobalKey _keyFor(int index) =>
      _sectionKeys.putIfAbsent(index, () => GlobalKey());

  ArcNavPresentation _resolve(NavigationFactory factory, double width) {
    final requested =
        widget.presentation ??
        widget.overrides[widget.style] ??
        factory.resolvePresentation(width: width, source: widget.source);

    if (factory.supportedPresentations.contains(requested)) return requested;

    // A style was asked for something it cannot draw — macOS has no bottom tab
    // bar and never will. Walk to the nearest thing it can, rather than
    // asserting: the same destination set has to stay legal in every style.
    for (final candidate in kPresentationFallback) {
      if (factory.supportedPresentations.contains(candidate)) return candidate;
    }
    return ArcNavPresentation.sidebar;
  }

  /// Builds the content area, honouring [ArcNavigation.preserveStacks].
  Widget _buildBody(BuildContext context) {
    final source = widget.source;
    final selected = widget.selectedIndex.clamp(0, source.length - 1);

    if (!widget.preserveStacks || !source.isSectioned) {
      return widget.bodyBuilder(
        context,
        source.destinationAt(selected),
        selected,
      );
    }

    // IndexedStack keeps every section's subtree mounted, which is what makes
    // "return to where I was" work. It is also why this is restricted to
    // section sources: doing it for a data source would mount every row.
    return IndexedStack(
      index: selected,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < source.length; i++)
          KeyedSubtree(
            key: _keyFor(i),
            child: widget.bodyBuilder(context, source.destinationAt(i), i),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final factory = NavigationStyleRegistry.getFactory(widget.style);
    if (factory == null) {
      return const Center(child: Text('(Unsupported Style)'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        final presentation = _resolve(factory, width);

        // Wrapped so ArcIcon — which the caller constructs, outside any
        // factory — can discover which design language it is rendering in.
        return ArcStyleScope(
          style: widget.style,
          child: factory.createNavigation(
          ArcNavigationSpec(
            source: widget.source,
            presentation: presentation,
            selectedIndex: widget.selectedIndex.clamp(
              0,
              widget.source.length - 1,
            ),
            onDestinationSelected: widget.onDestinationSelected,
            onChildSelected: widget.onChildSelected,
            leading: widget.leading,
            maxBottomTabs: widget.maxBottomTabs,
            body: _buildBody(context),
            bodyBuilder: widget.bodyBuilder,
          ),
          ),
        );
      },
    );
  }
}

/// Everything a [NavigationFactory] needs, resolved.
///
/// Factories receive data rather than a [BuildContext] or [BoxConstraints],
/// preserving the invariant that every arc_ui factory is a pure
/// description-to-widget function.
class ArcNavigationSpec {
  const ArcNavigationSpec({
    required this.source,
    required this.presentation,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.maxBottomTabs,
    required this.body,
    required this.bodyBuilder,
    this.onChildSelected,
    this.leading,
  });

  final ArcNavSource source;

  /// Already resolved and already checked against the factory's
  /// [NavigationFactory.supportedPresentations].
  final ArcNavPresentation presentation;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final void Function(int parentIndex, int childIndex)? onChildSelected;
  final int maxBottomTabs;

  /// Rendered above the destination list by presentations that have a vertical
  /// list; ignored by flat tab strips, which have nowhere to put it.
  final Widget? leading;

  /// The content area, with stack preservation already applied. Factories that
  /// let their native shell own the body — Fluent's `NavigationView` requires
  /// this — use [bodyBuilder] instead.
  final Widget body;

  /// Used only by shells that insist on owning page construction themselves.
  final ArcNavBodyBuilder bodyBuilder;

  /// The destinations to show in a flat strip, after the "flatten to parent"
  /// rule and the [maxBottomTabs] cap.
  ///
  /// Children are dropped rather than promoted, so the index of every visible
  /// destination still matches [selectedIndex].
  List<ArcDestination> get flatDestinations => [
    for (var i = 0; i < source.length; i++) source.destinationAt(i),
  ];

  /// Whether a bottom strip has to collapse its tail behind "More".
  bool get overflows =>
      presentation == ArcNavPresentation.bottomTabs &&
      source.length > maxBottomTabs;

  /// How many real destinations a bottom strip shows before "More".
  int get visibleTabCount => overflows ? maxBottomTabs - 1 : source.length;
}

/// Abstract navigation factory for extensibility
abstract class NavigationFactory {
  /// The presentations this style can actually draw.
  ///
  /// Declared rather than discovered so that unsupported combinations are
  /// data, not a runtime surprise — the sandbox renders this as a support
  /// matrix.
  Set<ArcNavPresentation> get supportedPresentations;

  /// Maps available width to a presentation using *this platform's*
  /// breakpoints, which is why it lives on the factory and not in the shell.
  ArcNavPresentation resolvePresentation({
    required double width,
    required ArcNavSource source,
  });

  Widget createNavigation(ArcNavigationSpec spec);

  String get styleName;
}
