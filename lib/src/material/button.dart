import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';

class MaterialButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createButton({required String text, required VoidCallback onPressed, ButtonType type = ButtonType.primary}) {
    switch (type) {
      case ButtonType.primary:
        return ElevatedButton(onPressed: onPressed, child: Text(text));
      case ButtonType.secondary:
        return FilledButton.tonal(onPressed: onPressed, child: Text(text));
      case ButtonType.outlined:
        return OutlinedButton(onPressed: onPressed, child: Text(text));
      case ButtonType.text:
        return TextButton(onPressed: onPressed, child: Text(text));
    }
  }
}
