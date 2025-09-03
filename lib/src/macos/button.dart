import 'package:arc_ui/arc_ui.dart';
import 'package:macos_ui/macos_ui.dart';

class MacOsButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  @override
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  }) {
    switch (type) {
      case ButtonType.primary:
        return PushButton(
          controlSize: ControlSize.regular,
          onPressed: onPressed,
          child: Text(text),
        );
      case ButtonType.secondary:
        return PushButton(
          controlSize: ControlSize.regular,
          onPressed: onPressed,
          secondary: true,
          child: Text(text),
        );
      case ButtonType.outlined:
        return PushButton(
          controlSize: ControlSize.regular,
          onPressed: onPressed,
          secondary: true,
          child: Text(text),
        );
      case ButtonType.text:
        return PushButton(
          controlSize: ControlSize.regular,
          onPressed: onPressed,
          secondary: true,
          child: Text(text),
        );
    }
  }
}
