import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/window.dart';
import 'package:arc_ui/src/fluent/window.dart';
import 'package:arc_ui/src/ios/window.dart';
import 'package:arc_ui/src/liquid/window.dart';
import 'package:arc_ui/src/macos/window.dart';
import 'package:arc_ui/src/material/window.dart';

// Window style registry for dynamic registration
class WindowStyleRegistry {
  static final Map<UIStyle, WindowFactory> _factories = {
    UIStyle.material: MaterialWindowFactory(),
    UIStyle.cupertino: CupertinoWindowFactory(),
    UIStyle.fluent: FluentWindowFactory(),
    UIStyle.macos: MacOsWindowFactory(),
    UIStyle.liquid: LiquidWindowFactory(),
  };

  static void registerFactory(UIStyle style, WindowFactory factory) {
    _factories[style] = factory;
  }

  static WindowFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
