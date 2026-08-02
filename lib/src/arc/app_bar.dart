import 'package:arc_ui/registry/app_bar.dart';
import 'package:arc_ui/registry/ui_style.dart';
import 'package:flutter/material.dart';

/// An app bar rendered in whichever design language [style] selects.
///
/// This carries app bar *description* rather than a built widget on purpose.
/// Every design language wants a different chrome type — [AppBar],
/// [CupertinoNavigationBar], macOS `ToolBar`, Fluent `PageHeader` — and they
/// share no common supertype, so [ArcScaffold] cannot be handed a finished
/// widget and place it. Keeping [title], [leading] and [actions] as plain
/// fields lets this widget and every [ScaffoldFactory] build the right native
/// chrome from one description.
class ArcAppBar extends StatelessWidget {
  const ArcAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.style = UIStyle.material,
  });

  /// The primary content, usually a [Text].
  final Widget title;

  /// Shown before [title]; a back button or icon.
  final Widget? leading;

  /// Shown after [title]. Each style places these differently — Cupertino
  /// collapses them into its single trailing slot, macOS wraps them as
  /// toolbar items.
  final List<Widget>? actions;

  /// The design language to render in.
  final UIStyle style;

  @override
  Widget build(BuildContext context) {
    final factory = AppBarStyleRegistry.getFactory(style);
    if (factory == null) {
      return AppBar(title: const Text('(Unsupported Style)'));
    }

    return factory.createAppBar(
      title: title,
      leading: leading,
      actions: actions,
    );
  }
}

/// Abstract app bar factory for extensibility
abstract class AppBarFactory {
  Widget createAppBar({
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  });

  String get styleName;
}
