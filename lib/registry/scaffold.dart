import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/scaffold.dart';
import 'package:arc_ui/src/fluent/scaffold.dart';
import 'package:arc_ui/src/ios/scaffold.dart';
import 'package:arc_ui/src/liquid/scaffold.dart';
import 'package:arc_ui/src/macos/scaffold.dart';
import 'package:arc_ui/src/material/scaffold.dart';

// Scaffold style registry for dynamic registration
class ScaffoldStyleRegistry {
  static final Map<UIStyle, ScaffoldFactory> _factories = {
    UIStyle.material: MaterialScaffoldFactory(),
    UIStyle.cupertino: CupertinoScaffoldFactory(),
    UIStyle.fluent: FluentScaffoldFactory(),
    UIStyle.macos: MacOsScaffoldFactory(),
    UIStyle.liquid: LiquidScaffoldFactory(),
  };

  static void registerFactory(UIStyle style, ScaffoldFactory factory) {
    _factories[style] = factory;
  }

  static ScaffoldFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
