import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';

class MaterialButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Material Design';

  @override
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  }) {
    switch (type) {
      case ButtonType.primary:
        return Builder(
          builder: (context) {
            final theme = Theme.of(context);
            return ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    theme.colorScheme.secondary, // Use theme's secondary color
                foregroundColor:
                    theme.colorScheme.primary, // Use theme's primary color
              ),
              child: Text(
                text,
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            );
          },
        );
      case ButtonType.secondary:
        return ElevatedButton(onPressed: onPressed, child: Text(text));
      case ButtonType.outlined:
        return Builder(
          builder: (context) {
            final theme = Theme.of(context);

            return OutlinedButton(
              onPressed: onPressed,
              child: Text(text),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  width: 1.0,
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            );
          },
        );
      case ButtonType.text:
        return TextButton(onPressed: onPressed, child: Text(text));
    }
  }
}
