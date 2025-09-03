import 'package:arc_ui/registry/button.dart';
import 'package:flutter/material.dart';

// Arc button widget
class ArcButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final UIStyle style;
  final ButtonType type;

  const ArcButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = UIStyle.material,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final factory = ButtonStyleRegistry.getFactory(style);
    if (factory == null) {
      return ElevatedButton(
        onPressed: onPressed,
        child: Text('$text (Unsupported Style)'),
      );
    }

    return factory.createButton(text: text, onPressed: onPressed, type: type);
  }
}

// Abstract button factory for extensibility
abstract class ButtonFactory {
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  });

  String get styleName;
}

// Button types for different use cases
enum ButtonType { primary, secondary, outlined, text }
