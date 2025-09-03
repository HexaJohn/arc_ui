import 'dart:math';

import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidButtonFactory extends ButtonFactory {
  @override
  String get styleName => 'Liquid Glass (iOS 26)';

  @override
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  }) {
    switch (type) {
      case ButtonType.primary:
        return LiquidGlass(
          settings: const LiquidGlassSettings(
            thickness: 10,
            glassColor: Color.fromARGB(
              116,
              255,
              255,
              255,
            ), // A subtle white tint
            lightIntensity: 1.5,
            lightAngle: 0.25 * pi,
            blend: 40,
            blur: 2,
            // outlineIntensity: 0.5,
          ),
          shape: LiquidRoundedRectangle(borderRadius: Radius.circular(32)),
          glassContainsChild: false,
          child: CupertinoButton(
            foregroundColor: Colors.black,
            onPressed: onPressed,
            child: Text(text),
          ),
        );
      // return CupertinoButton.filled(onPressed: onPressed, child: Text(text));
      case ButtonType.secondary:
        return CupertinoButton.tinted(
          color: CupertinoColors.systemGrey,
          onPressed: onPressed,
          child: Text(text, style: TextStyle(color: CupertinoColors.label)),
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
        return CupertinoButton(onPressed: onPressed, child: Text(text));
    }
  }
}
