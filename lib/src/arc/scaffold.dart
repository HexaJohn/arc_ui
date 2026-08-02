import 'package:arc_ui/registry/scaffold.dart';
import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:flutter/material.dart';

/// A page scaffold rendered in whichever design language [style] selects.
class ArcScaffold extends StatelessWidget {
  const ArcScaffold({
    super.key,
    required this.body,
    this.style = UIStyle.material,
    this.appBar,
  });

  /// The page content.
  final Widget body;

  /// The design language to render in.
  final UIStyle style;

  /// Describes the chrome above [body]. Each factory turns this into its own
  /// native bar; see [ArcAppBar] for why this is a description rather than a
  /// built widget.
  final ArcAppBar? appBar;

  @override
  Widget build(BuildContext context) {
    final factory = ScaffoldStyleRegistry.getFactory(style);
    if (factory == null) {
      return const Scaffold(
        body: Center(child: Text('(Unsupported Style)')),
      );
    }

    return factory.createScaffold(body: body, appBar: appBar);
  }
}

/// Abstract scaffold factory for extensibility
abstract class ScaffoldFactory {
  Widget createScaffold({
    required Widget body,
    ArcAppBar? appBar,
  });

  String get styleName;
}
