import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/switch.dart';
import 'package:arc_ui/src/fluent/switch.dart';
import 'package:arc_ui/src/ios/switch.dart';
import 'package:arc_ui/src/liquid/switch.dart';
import 'package:arc_ui/src/macos/switch.dart';
import 'package:arc_ui/src/material/switch.dart';

// Switch style registry for dynamic registration
class SwitchStyleRegistry {
  static final Map<UIStyle, SwitchFactory> _factories = {
    UIStyle.material: MaterialSwitchFactory(),
    UIStyle.cupertino: CupertinoSwitchFactory(),
    UIStyle.fluent: FluentSwitchFactory(),
    UIStyle.macos: MacOsSwitchFactory(),
    UIStyle.liquid: LiquidSwitchFactory(),
  };

  static void registerFactory(UIStyle style, SwitchFactory factory) {
    _factories[style] = factory;
  }

  static SwitchFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
