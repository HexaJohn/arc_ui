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
      // MacOS does have an outlined button style
      // see SwitchResX extension preferences pane
      case ButtonType.outlined:
        return PushButton(
          controlSize: ControlSize.regular,
          onPressed: onPressed,
          secondary: true,
          child: Text(text),
        );
      // Text buttons in macOS are usually just for tooltips or links
      // see About This Mac > Regulatory Information
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
