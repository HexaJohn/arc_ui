import 'package:arc_ui/arc_ui.dart';
import 'package:arc_ui/src/fluent/button.dart';
import 'package:arc_ui/src/ios/button.dart';
import 'package:arc_ui/src/macos/button.dart';
import 'package:arc_ui/src/material/button.dart';

// Extensible enum for UI styles
enum UIStyle { material, cupertino, fluent, macos, windows11, custom }

// Button style registry for dynamic registration
class ButtonStyleRegistry {
  static final Map<UIStyle, ButtonFactory> _factories = {
    UIStyle.material: MaterialButtonFactory(),
    UIStyle.cupertino: CupertinoButtonFactory(),
    UIStyle.fluent: FluentButtonFactory(),
    UIStyle.macos: MacOsButtonFactory(),
  };

  static void registerFactory(UIStyle style, ButtonFactory factory) {
    _factories[style] = factory;
  }

  static ButtonFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
