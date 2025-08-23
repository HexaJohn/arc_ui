import 'package:arc_ui/arc_ui.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  @override
  Widget createButton({required String text, required VoidCallback onPressed, ButtonType type = ButtonType.primary}) {
    switch (type) {
      case ButtonType.primary:
        return FilledButton(onPressed: onPressed, child: Text(text));
      case ButtonType.secondary:
        return FilledButton(
          onPressed: onPressed,
          child: Text(text, style: TextStyle(color: Colors.grey)),
        );
      case ButtonType.outlined:
        return FilledButton(onPressed: onPressed, child: Text(text));

      case ButtonType.text:
        return HyperlinkButton(onPressed: onPressed, child: Text(text));
    }
  }
}
