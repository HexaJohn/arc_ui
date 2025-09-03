import 'dart:math';

import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  final liquidGlassSettings = const LiquidGlassSettings(
    thickness: 10,
    glassColor: Color.fromARGB(
      116,
      255,
      255,
      255,
    ),
    lightIntensity: 1.5,
    lightAngle: 0.25 * pi,
    blend: 40,
    blur: 2,
  );

  @override
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  }) {
    switch (type) {
      case ButtonType.primary:
        return LiquidGlass(
          settings: liquidGlassSettings,
          shape: LiquidRoundedRectangle(borderRadius: Radius.circular(32)),
          glassContainsChild: false,
          child: CupertinoButton(
            foregroundColor: Colors.black,
            onPressed: onPressed,
            child: Text(
              text,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      case ButtonType.secondary:
        return LiquidGlass(
          settings: liquidGlassSettings,
          shape: LiquidRoundedRectangle(borderRadius: Radius.circular(32)),
          glassContainsChild: false,
          child: CupertinoButton(
            foregroundColor: Colors.black,
            onPressed: onPressed,
            child: Text(text),
          ),
        );
      case ButtonType.outlined:
        return LiquidGlass(
          settings: liquidGlassSettings,
          shape: LiquidRoundedRectangle(borderRadius: Radius.circular(32)),
          glassContainsChild: false,
          child: CupertinoButton(
            foregroundColor: Colors.black,
            onPressed: onPressed,
            child: Text(text),
          ),
        );
      case ButtonType.text:
        return CupertinoButton(onPressed: onPressed, child: Text(text));
    }
  }
}
