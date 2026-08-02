import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentAppBarFactory extends AppBarFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  @override
  Widget createAppBar({
    required Widget title,
    Widget? leading,
    List<Widget>? actions,
  }) {
    return PageHeader(
      leading: leading,
      title: title,
      commandBar: actions == null || actions.isEmpty
          ? null
          : Row(mainAxisSize: MainAxisSize.min, children: actions),
    );
  }
}
