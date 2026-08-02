import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/slider.dart';
import 'package:arc_ui/src/fluent/slider.dart';
import 'package:arc_ui/src/ios/slider.dart';
import 'package:arc_ui/src/liquid/slider.dart';
import 'package:arc_ui/src/macos/slider.dart';
import 'package:arc_ui/src/material/slider.dart';

// Slider style registry for dynamic registration
class SliderStyleRegistry {
  static final Map<UIStyle, SliderFactory> _factories = {
    UIStyle.material: MaterialSliderFactory(),
    UIStyle.cupertino: CupertinoSliderFactory(),
    UIStyle.fluent: FluentSliderFactory(),
    UIStyle.macos: MacOsSliderFactory(),
    UIStyle.liquid: LiquidSliderFactory(),
  };

  static void registerFactory(UIStyle style, SliderFactory factory) {
    _factories[style] = factory;
  }

  static SliderFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();
}
