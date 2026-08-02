import 'package:arc_ui/src/arc/menu.dart';
import 'package:flutter/material.dart';

/// Renders [menus] as Flutter's native macOS menu bar, wrapping [child].
///
/// Off macOS this is a silent no-op that still renders [child], which is why
/// callers must decide via [arcHasSystemMenuBar] rather than relying on a
/// fallback here.
///
/// Deliberately drives [PlatformMenuDelegate.setMenus] rather than mounting a
/// [PlatformMenuBar]. That widget takes a process-wide debug lock keyed on its
/// [BuildContext] and releases it in `dispose`, but a hot restart builds the
/// new tree without disposing the old one — so the lock stays held by a dead
/// context and every subsequent build throws
/// "More than one active PlatformMenuBar detected". The imperative API is
/// documented as the supported alternative, takes no lock, and is what makes
/// this survive hot reload and hot restart.
class ArcNativeMenuBar extends StatefulWidget {
  const ArcNativeMenuBar({
    super.key,
    required this.menus,
    required this.child,
  });

  final List<ArcMenu> menus;
  final Widget child;

  @override
  State<ArcNativeMenuBar> createState() => _ArcNativeMenuBarState();

  /// Converts the description into Flutter's platform menu types.
  ///
  /// Prunes first. [ArcWindow] already does, but this is public API and
  /// constructing a [PlatformProvidedMenuItem] the host cannot draw throws —
  /// so relying on the caller would leave a footgun. Pruning is idempotent, so
  /// doing it twice costs nothing.
  static List<PlatformMenuItem> toPlatform(List<ArcMenu> menus) => [
    for (final menu in pruneMenus(menus))
      PlatformMenu(label: menu.label, menus: _entries(menu.entries)),
  ];

  /// A cheap structural fingerprint, used to avoid re-serialising the menu
  /// across the platform channel on every unrelated rebuild — this widget sits
  /// above the whole app, so it rebuilds on things like slider drags.
  static String signature(List<ArcMenu> menus) {
    final buffer = StringBuffer();
    menus = pruneMenus(menus);
    void walk(List<ArcMenuEntry> entries) {
      for (final entry in entries) {
        switch (entry) {
          case ArcMenuItem(:final label, :final enabled):
            buffer.write('i:$label:$enabled;');
          case ArcMenuGroup(:final members):
            buffer.write('g(');
            walk(members);
            buffer.write(');');
          case ArcMenuSubmenu(:final label, :final entries):
            buffer.write('s:$label(');
            walk(entries);
            buffer.write(');');
          case ArcProvidedItem(:final type):
            buffer.write('p:${type.name};');
        }
      }
    }

    for (final menu in menus) {
      buffer.write('m:${menu.label}(');
      walk(menu.entries);
      buffer.write(');');
    }
    return buffer.toString();
  }

  static List<PlatformMenuItem> _entries(List<ArcMenuEntry> entries) {
    final out = <PlatformMenuItem>[];
    for (final entry in entries) {
      switch (entry) {
        case ArcMenuItem():
          out.add(
            PlatformMenuItem(
              label: entry.label,
              shortcut: entry.shortcut,
              onSelected: entry.onSelected,
              onSelectedIntent: entry.intent,
            ),
          );
        case ArcMenuGroup(:final members):
          out.add(PlatformMenuItemGroup(members: _entries(members)));
        case ArcMenuSubmenu(:final label, :final entries):
          out.add(PlatformMenu(label: label, menus: _entries(entries)));
        case ArcProvidedItem(:final type):
          // Safe because toPlatform prunes unsupported types before this runs.
          out.add(PlatformProvidedMenuItem(type: _providedType(type)));
      }
    }
    return out;
  }

  static PlatformProvidedMenuItemType _providedType(ArcProvidedMenuItem type) {
    return switch (type) {
      ArcProvidedMenuItem.about => PlatformProvidedMenuItemType.about,
      ArcProvidedMenuItem.quit => PlatformProvidedMenuItemType.quit,
      ArcProvidedMenuItem.servicesSubmenu =>
        PlatformProvidedMenuItemType.servicesSubmenu,
      ArcProvidedMenuItem.hide => PlatformProvidedMenuItemType.hide,
      ArcProvidedMenuItem.hideOtherApplications =>
        PlatformProvidedMenuItemType.hideOtherApplications,
      ArcProvidedMenuItem.showAllApplications =>
        PlatformProvidedMenuItemType.showAllApplications,
      ArcProvidedMenuItem.startSpeaking =>
        PlatformProvidedMenuItemType.startSpeaking,
      ArcProvidedMenuItem.stopSpeaking =>
        PlatformProvidedMenuItemType.stopSpeaking,
      ArcProvidedMenuItem.toggleFullScreen =>
        PlatformProvidedMenuItemType.toggleFullScreen,
      ArcProvidedMenuItem.minimizeWindow =>
        PlatformProvidedMenuItemType.minimizeWindow,
      ArcProvidedMenuItem.zoomWindow => PlatformProvidedMenuItemType.zoomWindow,
      ArcProvidedMenuItem.arrangeWindowsInFront =>
        PlatformProvidedMenuItemType.arrangeWindowsInFront,
    };
  }
}

class _ArcNativeMenuBarState extends State<ArcNativeMenuBar> {
  String? _pushed;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(ArcNativeMenuBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    // Only clear if this instance is the one currently installed; after a hot
    // restart a stale State may be disposed after the new one has published,
    // and clearing then would wipe a live menu bar.
    if (_pushed != null) {
      WidgetsBinding.instance.platformMenuDelegate.clearMenus();
    }
    super.dispose();
  }

  void _sync() {
    final signature = ArcNativeMenuBar.signature(widget.menus);
    if (signature == _pushed) return;
    _pushed = signature;
    WidgetsBinding.instance.platformMenuDelegate.setMenus(
      ArcNativeMenuBar.toPlatform(widget.menus),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// An in-window menu bar — the legacy Windows and KDE pattern, and the only
/// option on Linux, where Flutter has no native menu integration at all.
class ArcInlineMenuBar extends StatelessWidget {
  const ArcInlineMenuBar({super.key, required this.menus, this.height = 32});

  final List<ArcMenu> menus;
  final double height;

  @override
  Widget build(BuildContext context) {
    // Menus whose every entry is platform-provided cannot be drawn in-window —
    // the application menu is entirely About/Services/Hide/Quit — and would
    // otherwise render as a labelled button opening onto nothing.
    final renderable = [
      for (final menu in menus)
        if (_entries(menu.entries).isNotEmpty) menu,
    ];

    return SizedBox(
      height: height,
      // Full width and start-aligned: MenuBar shrink-wraps its children, so
      // dropped into a Column it lands centred rather than tucked against the
      // leading edge where a Windows menu bar belongs.
      width: double.infinity,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: MenuBar(
          style: const MenuStyle(
            elevation: WidgetStatePropertyAll(0),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
          children: [
            for (final menu in renderable)
              SubmenuButton(
                menuChildren: _entries(menu.entries),
                child: MenuAcceleratorLabel(menu.label),
              ),
          ],
        ),
      ),
    );
  }

  static List<Widget> _entries(List<ArcMenuEntry> entries) {
    final out = <Widget>[];
    for (final entry in entries) {
      switch (entry) {
        case ArcMenuItem():
          out.add(
            MenuItemButton(
              shortcut: entry.shortcut,
              onPressed: entry.enabled ? () => _invoke(entry) : null,
              child: MenuAcceleratorLabel(entry.label),
            ),
          );
        case ArcMenuGroup(:final members):
          if (out.isNotEmpty) out.add(const Divider(height: 1));
          out.addAll(_entries(members));
        case ArcMenuSubmenu(:final label, :final entries):
          out.add(
            SubmenuButton(
              menuChildren: _entries(entries),
              child: MenuAcceleratorLabel(label),
            ),
          );
        case ArcProvidedItem():
          // Pruned upstream off macOS; if one survives here the platform draws
          // its own, so there is nothing to render in-window.
          break;
      }
    }
    return out;
  }

  static void _invoke(ArcMenuItem item) {
    if (item.onSelected != null) {
      item.onSelected!();
      return;
    }
    final intent = item.intent;
    if (intent == null) return;
    // Dispatch against the primary focus so editing commands reach whichever
    // text field is focused, matching how the native menu behaves.
    final context = primaryFocus?.context;
    if (context == null) return;
    Actions.maybeInvoke(context, intent);
  }
}
