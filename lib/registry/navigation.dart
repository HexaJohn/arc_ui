import 'package:arc_ui/registry/ui_style.dart';
import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/fluent/navigation.dart';
import 'package:arc_ui/src/ios/navigation.dart';
import 'package:arc_ui/src/liquid/navigation.dart';
import 'package:arc_ui/src/macos/navigation.dart';
import 'package:arc_ui/src/material/navigation.dart';

// Navigation style registry for dynamic registration
class NavigationStyleRegistry {
  static final Map<UIStyle, NavigationFactory> _factories = {
    UIStyle.material: MaterialNavigationFactory(),
    UIStyle.cupertino: CupertinoNavigationFactory(),
    UIStyle.fluent: FluentNavigationFactory(),
    UIStyle.macos: MacOsNavigationFactory(),
    UIStyle.liquid: LiquidNavigationFactory(),
  };

  static void registerFactory(UIStyle style, NavigationFactory factory) {
    _factories[style] = factory;
  }

  static NavigationFactory? getFactory(UIStyle style) {
    return _factories[style];
  }

  static List<UIStyle> get availableStyles => _factories.keys.toList();

  static List<String> get availableStyleNames =>
      _factories.values.map((f) => f.styleName).toList();

  /// Which presentations each style can draw — rendered as a support matrix in
  /// the sandbox so the holes are visible rather than discovered at runtime.
  static Map<UIStyle, Set<ArcNavPresentation>> get supportMatrix => {
    for (final entry in _factories.entries)
      entry.key: entry.value.supportedPresentations,
  };
}
