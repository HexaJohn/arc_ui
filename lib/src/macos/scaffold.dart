import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/arc/scaffold.dart';
import 'package:arc_ui/src/macos/app_bar.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class MacOsScaffoldFactory extends ScaffoldFactory {
  @override
  String get styleName => 'macOS';

  @override
  Widget createScaffold({
    required Widget body,
    ArcAppBar? appBar,
  }) {
    return MacosScaffold(
      // Built here rather than delegating to MacOsAppBarFactory because
      // `toolBar` demands a ToolBar, which the factory's `Widget` return type
      // cannot guarantee.
      toolBar: appBar == null
          ? null
          : ToolBar(
              title: appBar.title,
              leading: appBar.leading,
              actions: toolbarItemsFrom(appBar.actions),
            ),
      children: [
        ContentArea(
          builder: (context, scrollController) => body,
        ),
      ],
    );
  }
}
