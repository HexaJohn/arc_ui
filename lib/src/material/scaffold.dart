import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/arc/scaffold.dart';
import 'package:flutter/material.dart';

class MaterialScaffoldFactory extends ScaffoldFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createScaffold({
    required Widget body,
    ArcAppBar? appBar,
  }) {
    return Scaffold(
      // Built here rather than delegating to MaterialAppBarFactory because
      // `appBar` demands a PreferredSizeWidget, which the factory's `Widget`
      // return type cannot guarantee.
      appBar: appBar == null
          ? null
          : AppBar(
              title: appBar.title,
              leading: appBar.leading,
              actions: appBar.actions,
            ),
      body: body,
    );
  }
}
