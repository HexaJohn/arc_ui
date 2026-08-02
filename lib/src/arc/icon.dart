import 'package:arc_ui/registry/ui_style.dart';
import 'package:fluent_ui/fluent_ui.dart' show FluentIcons;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';

/// Publishes the active [UIStyle] to descendants.
///
/// Supplied by [ArcWindow] and [ArcNavigation], so widgets that need to adapt
/// but are constructed by the *caller* — icons above all — can find out which
/// design language they are being rendered in without it being threaded
/// through every constructor.
class ArcStyleScope extends InheritedWidget {
  const ArcStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  final UIStyle style;

  /// The ambient style, defaulting to Material where none is published.
  static UIStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ArcStyleScope>()?.style ??
      UIStyle.material;

  @override
  bool updateShouldNotify(ArcStyleScope oldWidget) => style != oldWidget.style;
}

/// One semantic icon, expressed in each design language's own icon set.
///
/// Icons are as much a part of a design language as its controls — a Material
/// glyph in a macOS sidebar reads as wrong even when everything around it is
/// right. This holds the per-style glyphs for a single meaning so callers name
/// the *meaning* and the style picks the artwork.
@immutable
class ArcIconData {
  const ArcIconData({
    required this.material,
    required this.cupertino,
    required this.fluent,
  });

  /// Material Design (`Icons`).
  final IconData material;

  /// Apple's set (`CupertinoIcons`), shared by Cupertino, macOS and Liquid
  /// Glass — macos_ui itself draws from it rather than shipping its own.
  final IconData cupertino;

  /// Fluent (`FluentIcons`).
  final IconData fluent;

  IconData resolve(UIStyle style) => switch (style) {
    UIStyle.material => material,
    UIStyle.fluent => fluent,
    UIStyle.cupertino || UIStyle.macos || UIStyle.liquid => cupertino,
    // Unimplemented styles fall back rather than throwing, matching how the
    // registries treat them.
    UIStyle.windows11 || UIStyle.custom => material,
  };
}

/// Renders an [ArcIconData] in the ambient design language.
///
/// Pass [style] to pin it; otherwise it reads [ArcStyleScope].
class ArcIcon extends StatelessWidget {
  const ArcIcon(this.icon, {super.key, this.style, this.size, this.color});

  final ArcIconData icon;
  final UIStyle? style;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon.resolve(style ?? ArcStyleScope.of(context)),
      size: size,
      color: color,
    );
  }
}

/// A catalogue of common icons, each mapped across the three icon sets.
///
/// Deliberately small and additive: every entry is a hand-checked triple, so
/// it is better to have twenty right than two hundred approximate.
abstract final class ArcIcons {
  static const inbox = ArcIconData(
    material: Icons.inbox_outlined,
    cupertino: CupertinoIcons.tray,
    fluent: FluentIcons.inbox,
  );

  static const send = ArcIconData(
    material: Icons.send_outlined,
    cupertino: CupertinoIcons.paperplane,
    fluent: FluentIcons.send,
  );

  static const drafts = ArcIconData(
    material: Icons.drafts_outlined,
    cupertino: CupertinoIcons.doc,
    fluent: FluentIcons.mail,
  );

  static const archive = ArcIconData(
    material: Icons.archive_outlined,
    cupertino: CupertinoIcons.archivebox,
    fluent: FluentIcons.archive,
  );

  static const trash = ArcIconData(
    material: Icons.delete_outline,
    cupertino: CupertinoIcons.trash,
    fluent: FluentIcons.delete,
  );

  static const search = ArcIconData(
    material: Icons.search,
    cupertino: CupertinoIcons.search,
    fluent: FluentIcons.search,
  );

  static const add = ArcIconData(
    material: Icons.add,
    cupertino: CupertinoIcons.add,
    fluent: FluentIcons.add,
  );

  static const settings = ArcIconData(
    material: Icons.settings_outlined,
    cupertino: CupertinoIcons.settings,
    fluent: FluentIcons.settings,
  );

  static const folder = ArcIconData(
    material: Icons.folder_outlined,
    cupertino: CupertinoIcons.folder,
    fluent: FluentIcons.folder,
  );

  static const star = ArcIconData(
    material: Icons.star_outline,
    cupertino: CupertinoIcons.star,
    fluent: FluentIcons.favorite_star,
  );

  static const person = ArcIconData(
    material: Icons.person_outline,
    cupertino: CupertinoIcons.person,
    fluent: FluentIcons.contact,
  );

  static const home = ArcIconData(
    material: Icons.home_outlined,
    cupertino: CupertinoIcons.house,
    fluent: FluentIcons.home,
  );

  static const chevronRight = ArcIconData(
    material: Icons.chevron_right,
    cupertino: CupertinoIcons.chevron_right,
    fluent: FluentIcons.chevron_right,
  );

  /// Placeholder for a destination that supplies no icon of its own.
  static const circle = ArcIconData(
    material: Icons.circle_outlined,
    cupertino: CupertinoIcons.circle,
    fluent: FluentIcons.circle_ring,
  );

  /// The overflow ("More") affordance on a capped tab strip.
  static const more = ArcIconData(
    material: Icons.more_horiz,
    cupertino: CupertinoIcons.ellipsis,
    fluent: FluentIcons.more,
  );

  static const flag = ArcIconData(
    material: Icons.flag_outlined,
    cupertino: CupertinoIcons.flag,
    fluent: FluentIcons.flag,
  );

  /// The show/hide-sidebar control.
  static const sidebarToggle = ArcIconData(
    material: Icons.view_sidebar_outlined,
    cupertino: CupertinoIcons.sidebar_left,
    fluent: FluentIcons.open_pane,
  );

  /// Every entry, for sandbox catalogues and tests.
  static const all = <String, ArcIconData>{
    'inbox': inbox,
    'send': send,
    'drafts': drafts,
    'archive': archive,
    'trash': trash,
    'search': search,
    'add': add,
    'settings': settings,
    'folder': folder,
    'star': star,
    'person': person,
    'home': home,
    'chevronRight': chevronRight,
    'circle': circle,
    'more': more,
    'flag': flag,
    'sidebarToggle': sidebarToggle,
  };
}
