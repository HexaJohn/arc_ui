import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/app_bar.dart';
import 'package:arc_ui/src/fluent/app_bar.dart';
import 'package:arc_ui/src/ios/app_bar.dart';
import 'package:arc_ui/src/liquid/app_bar.dart';
import 'package:arc_ui/src/macos/app_bar.dart';
import 'package:arc_ui/src/material/app_bar.dart';

// App bar style registry for dynamic registration
class AppBarStyleRegistry {
  static final Map<UIStyle, AppBarFactory> _factories = {
    UIStyle.material: MaterialAppBarFactory(),
    UIStyle.cupertino: CupertinoAppBarFactory(),
    UIStyle.fluent: FluentAppBarFactory(),
    UIStyle.macos: MacOsAppBarFactory(),
    UIStyle.liquid: LiquidAppBarFactory(),
  };

  static void registerFactory(UIStyle style, AppBarFactory factory) {
    _factories[style] = factory;
  }

  static AppBarFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
