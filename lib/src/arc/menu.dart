import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A top-level entry in a window's menu bar — File, Edit, Window and so on.
///
/// This is a description rather than a widget, for the same reason [ArcAppBar]
/// is: macOS renders it as a real `NSMenu` via [PlatformMenuBar] while Windows
/// and Linux draw it in-window with `MenuBar`, and those share no supertype.
class ArcMenu {
  const ArcMenu({required this.label, required this.entries});

  final String label;
  final List<ArcMenuEntry> entries;
}

/// Anything that can appear inside an [ArcMenu].
sealed class ArcMenuEntry {
  const ArcMenuEntry();
}

/// A selectable command.
///
/// Supply exactly one of [onSelected] or [intent]. Prefer [intent] for editing
/// commands: dispatching `CopySelectionTextIntent` through the focus tree hits
/// whatever text field is focused, which a plain callback cannot do.
class ArcMenuItem extends ArcMenuEntry {
  const ArcMenuItem({
    required this.label,
    this.shortcut,
    this.onSelected,
    this.intent,
  }) : assert(
         onSelected == null || intent == null,
         'Supply only one of onSelected or intent',
       );

  final String label;

  /// Rendered as an accelerator hint and, on macOS, registered with the system
  /// menu. [SingleActivator] and [CharacterActivator] both qualify.
  final MenuSerializableShortcut? shortcut;

  final VoidCallback? onSelected;

  /// Dispatched via `Actions.invoke` against the primary focus.
  final Intent? intent;

  /// Menu items with neither callback nor intent render disabled, matching
  /// `PlatformMenuItem`'s own enablement rule.
  bool get enabled => onSelected != null || intent != null;
}

/// A run of entries fenced by dividers.
class ArcMenuGroup extends ArcMenuEntry {
  const ArcMenuGroup(this.members);
  final List<ArcMenuEntry> members;
}

/// A nested submenu.
class ArcMenuSubmenu extends ArcMenuEntry {
  const ArcMenuSubmenu({required this.label, required this.entries});
  final String label;
  final List<ArcMenuEntry> entries;
}

/// The standard items macOS supplies itself.
///
/// Mirrors Flutter's `PlatformProvidedMenuItemType` one-to-one. This is the
/// complete set — note what is *absent*: there is no New, Close, Save,
/// Preferences, or any Edit command. Every Mac app's Edit menu is hand-built,
/// which is why [ArcMenus.standard] builds one for you.
enum ArcProvidedMenuItem {
  about,
  quit,
  servicesSubmenu,
  hide,
  hideOtherApplications,
  showAllApplications,
  startSpeaking,
  stopSpeaking,
  toggleFullScreen,
  minimizeWindow,
  zoomWindow,
  arrangeWindowsInFront,
}

/// An item the platform draws and handles itself.
///
/// Silently dropped where unsupported. That is not laziness: constructing
/// Flutter's `PlatformProvidedMenuItem` on Windows or Linux throws in debug,
/// so these must be filtered before they ever reach a factory.
class ArcProvidedItem extends ArcMenuEntry {
  const ArcProvidedItem(this.type);
  final ArcProvidedMenuItem type;
}

/// Whether the running platform will actually draw [type].
///
/// Deliberately stricter than Flutter's `PlatformProvidedMenuItem.hasMenu`,
/// which only inspects [defaultTargetPlatform] and so answers `true` on
/// Flutter web when the browser reports macOS — where there is no system menu
/// bar at all.
bool arcSupportsProvidedItem(ArcProvidedMenuItem type) {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.macOS;
}

/// Whether a real system menu bar is available right now.
///
/// [PlatformMenuBar] fails *silently* off macOS — the channel is an
/// `OptionalMethodChannel`, which swallows the missing-plugin error with no
/// throw and no log — so a style that assumes a native menu would simply show
/// nothing. Every factory checks this before choosing the native path.
bool get arcHasSystemMenuBar =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Ready-made menus, so an app gets a HIG-correct bar without hand-authoring
/// the parts every application shares.
abstract final class ArcMenus {
  /// The macOS application menu. Everything in it is platform-provided, so it
  /// collapses to nothing off macOS.
  static ArcMenu application(String appName) => ArcMenu(
    label: appName,
    entries: const [
      ArcProvidedItem(ArcProvidedMenuItem.about),
      ArcMenuGroup([ArcProvidedItem(ArcProvidedMenuItem.servicesSubmenu)]),
      ArcMenuGroup([
        ArcProvidedItem(ArcProvidedMenuItem.hide),
        ArcProvidedItem(ArcProvidedMenuItem.hideOtherApplications),
        ArcProvidedItem(ArcProvidedMenuItem.showAllApplications),
      ]),
      ArcMenuGroup([ArcProvidedItem(ArcProvidedMenuItem.quit)]),
    ],
  );

  /// A File menu. Every command is optional; omitted ones are left out rather
  /// than shown disabled.
  static ArcMenu file({
    VoidCallback? onNew,
    VoidCallback? onOpen,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
    VoidCallback? onClose,
  }) {
    final entries = <ArcMenuEntry>[
      if (onNew != null)
        ArcMenuItem(
          label: 'New',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyN, meta: true),
          onSelected: onNew,
        ),
      if (onOpen != null)
        ArcMenuItem(
          label: 'Open…',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyO, meta: true),
          onSelected: onOpen,
        ),
      if (onClose != null)
        ArcMenuItem(
          label: 'Close',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyW, meta: true),
          onSelected: onClose,
        ),
      if (onSave != null)
        ArcMenuItem(
          label: 'Save',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyS, meta: true),
          onSelected: onSave,
        ),
      if (onSaveAs != null)
        ArcMenuItem(
          label: 'Save As…',
          shortcut: const SingleActivator(
            LogicalKeyboardKey.keyS,
            meta: true,
            shift: true,
          ),
          onSelected: onSaveAs,
        ),
    ];

    return ArcMenu(label: 'File', entries: entries);
  }

  /// The Edit menu macOS does *not* provide.
  ///
  /// Every entry dispatches an [Intent] rather than a callback, so the command
  /// lands on whatever text field currently holds focus — the same mechanism
  /// Flutter's own text shortcuts use.
  static ArcMenu edit() => const ArcMenu(
    label: 'Edit',
    entries: [
      ArcMenuGroup([
        ArcMenuItem(
          label: 'Undo',
          shortcut: SingleActivator(LogicalKeyboardKey.keyZ, meta: true),
          intent: UndoTextIntent(SelectionChangedCause.keyboard),
        ),
        ArcMenuItem(
          label: 'Redo',
          shortcut: SingleActivator(
            LogicalKeyboardKey.keyZ,
            meta: true,
            shift: true,
          ),
          intent: RedoTextIntent(SelectionChangedCause.keyboard),
        ),
      ]),
      ArcMenuGroup([
        ArcMenuItem(
          label: 'Cut',
          shortcut: SingleActivator(LogicalKeyboardKey.keyX, meta: true),
          intent: CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
        ),
        ArcMenuItem(
          label: 'Copy',
          shortcut: SingleActivator(LogicalKeyboardKey.keyC, meta: true),
          intent: CopySelectionTextIntent.copy,
        ),
        ArcMenuItem(
          label: 'Paste',
          shortcut: SingleActivator(LogicalKeyboardKey.keyV, meta: true),
          intent: PasteTextIntent(SelectionChangedCause.keyboard),
        ),
        ArcMenuItem(
          label: 'Select All',
          shortcut: SingleActivator(LogicalKeyboardKey.keyA, meta: true),
          intent: SelectAllTextIntent(SelectionChangedCause.keyboard),
        ),
      ]),
    ],
  );

  /// The Window menu. Entirely platform-provided, so it disappears off macOS.
  static ArcMenu window() => const ArcMenu(
    label: 'Window',
    entries: [
      ArcProvidedItem(ArcProvidedMenuItem.minimizeWindow),
      ArcProvidedItem(ArcProvidedMenuItem.zoomWindow),
      ArcMenuGroup([ArcProvidedItem(ArcProvidedMenuItem.toggleFullScreen)]),
      ArcMenuGroup([
        ArcProvidedItem(ArcProvidedMenuItem.arrangeWindowsInFront),
      ]),
    ],
  );

  /// The conventional bar: application, File, Edit, Window.
  static List<ArcMenu> standard({
    required String appName,
    VoidCallback? onNew,
    VoidCallback? onOpen,
    VoidCallback? onSave,
    VoidCallback? onSaveAs,
    VoidCallback? onClose,
  }) {
    final file = ArcMenus.file(
      onNew: onNew,
      onOpen: onOpen,
      onSave: onSave,
      onSaveAs: onSaveAs,
      onClose: onClose,
    );

    return [
      application(appName),
      if (file.entries.isNotEmpty) file,
      edit(),
      window(),
    ];
  }
}

/// Strips entries the running platform cannot draw, then drops any menu left
/// empty.
///
/// Runs once in [ArcWindow] so no factory has to repeat the guard — and so the
/// Window menu vanishes entirely off macOS rather than appearing as an empty
/// stub.
List<ArcMenu> pruneMenus(List<ArcMenu> menus) {
  List<ArcMenuEntry> prune(List<ArcMenuEntry> entries) {
    final out = <ArcMenuEntry>[];
    for (final entry in entries) {
      switch (entry) {
        case ArcProvidedItem(:final type):
          if (arcSupportsProvidedItem(type)) out.add(entry);
        case ArcMenuGroup(:final members):
          final kept = prune(members);
          if (kept.isNotEmpty) out.add(ArcMenuGroup(kept));
        case ArcMenuSubmenu(:final label, :final entries):
          final kept = prune(entries);
          if (kept.isNotEmpty) {
            out.add(ArcMenuSubmenu(label: label, entries: kept));
          }
        case ArcMenuItem():
          out.add(entry);
      }
    }
    return out;
  }

  return [
    for (final menu in menus)
      if (prune(menu.entries).isNotEmpty)
        ArcMenu(label: menu.label, entries: prune(menu.entries)),
  ];
}
