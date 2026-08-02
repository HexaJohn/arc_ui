import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/arc/scaffold.dart';
import 'package:arc_ui/src/ios/app_bar.dart';
import 'package:flutter/cupertino.dart';

class CupertinoScaffoldFactory extends ScaffoldFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Widget createScaffold({
    required Widget body,
    ArcAppBar? appBar,
  }) {
    return CupertinoPageScaffold(
      // Built here rather than delegating to CupertinoAppBarFactory because
      // `navigationBar` demands an ObstructingPreferredSizeWidget, which the
      // factory's `Widget` return type cannot guarantee.
      navigationBar: appBar == null
          ? null
          : CupertinoNavigationBar(
              leading: appBar.leading,
              middle: appBar.title,
              trailing: trailingFrom(appBar.actions),
            ),
      child: SafeArea(child: body),
    );
  }
}
