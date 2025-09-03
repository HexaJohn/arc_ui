import 'package:arc_ui/arc_ui.dart';
import 'package:fluent_ui/fluent_ui.dart';

class FluentButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Fluent Design (Windows)';

  @override
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  }) {
    switch (type) {
      case ButtonType.primary:
        return FilledButton(onPressed: onPressed, child: Text(text));
      case ButtonType.secondary:
        return Button(onPressed: onPressed, child: Text(text));
      case ButtonType.outlined:
        return OutlinedButton(onPressed: onPressed, child: Text(text));

      case ButtonType.text:
        return HyperlinkButton(onPressed: onPressed, child: Text(text));
    }
  }
}
