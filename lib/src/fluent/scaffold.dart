import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/arc/scaffold.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentScaffoldFactory extends ScaffoldFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  @override
  Widget createScaffold({
    required Widget body,
    ArcAppBar? appBar,
  }) {
    return ScaffoldPage(
      header: appBar == null
          ? null
          : PageHeader(
              leading: appBar.leading,
              title: appBar.title,
              commandBar:
                  appBar.actions == null || appBar.actions!.isEmpty
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: appBar.actions!,
                    ),
            ),
      content: body,
    );
  }
}
