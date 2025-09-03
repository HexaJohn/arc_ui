import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/cupertino.dart';

class CupertinoButtonFactory extends ButtonFactory {
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
        return CupertinoButton.filled(
          color: CupertinoColors.systemBlue,
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(color: CupertinoColors.white),
          ),
        );
      // TODO: This completely breaks in dark mode
      case ButtonType.secondary:
        return CupertinoButton.filled(
          color: CupertinoColors.white,
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(color: CupertinoColors.black),
          ),
        );
      case ButtonType.outlined:
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: CupertinoColors.systemBlue),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CupertinoButton(
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(color: CupertinoColors.systemBlue),
            ),
          ),
        );
      case ButtonType.text:
        return CupertinoButton(
          onPressed: onPressed,
          child: Text(
            text,
            style: TextStyle(color: CupertinoColors.systemBlue),
          ),
        );
    }
  }
}
