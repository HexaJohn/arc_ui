import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/checkbox.dart';
import 'package:arc_ui/src/fluent/checkbox.dart';
import 'package:arc_ui/src/ios/checkbox.dart';
import 'package:arc_ui/src/liquid/checkbox.dart';
import 'package:arc_ui/src/macos/checkbox.dart';
import 'package:arc_ui/src/material/checkbox.dart';

// Checkbox style registry for dynamic registration
class CheckboxStyleRegistry {
  static final Map<UIStyle, CheckboxFactory> _factories = {
    UIStyle.material: MaterialCheckboxFactory(),
    UIStyle.cupertino: CupertinoCheckboxFactory(),
    UIStyle.fluent: FluentCheckboxFactory(),
    UIStyle.macos: MacOsCheckboxFactory(),
    UIStyle.liquid: LiquidCheckboxFactory(),
  };

  static void registerFactory(UIStyle style, CheckboxFactory factory) {
    _factories[style] = factory;
  }

  static CheckboxFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
