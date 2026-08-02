import 'package:arc_ui/arc_ui.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

/// A human readable name for [style], used in the toolbar dropdown and in the
/// URL query parameters, so the labels have to stay unique.
String uiStyleLabel(UIStyle style) => switch (style) {
  UIStyle.material => 'Material',
  UIStyle.cupertino => 'Cupertino (iOS)',
  UIStyle.fluent => 'Fluent (Windows)',
  UIStyle.macos => 'macOS',
  UIStyle.windows11 => 'Windows 11',
  UIStyle.liquid => 'Liquid Glass',
  UIStyle.custom => 'Custom',
};

/// A toolbar addon that switches arc_ui's design language for every use case.
///
/// Publishes the selection through arc_ui's own [ArcStyleScope] — the same
/// scope ArcWindow and ArcNavigation supply, so adaptive widgets like [ArcIcon]
/// resolve the toolbar's design language exactly as they would in a real app.
/// It also installs the theme ancestors the individual factories reach for, by
/// delegating to [ArcTheme] — the same widget any arc_ui consumer needs near
/// its root.
class UIStyleAddon extends WidgetbookAddon<UIStyle> {
  UIStyleAddon({
    List<UIStyle>? styles,
    this.initialStyle = UIStyle.material,
    Color? primaryColor,
    fluent.AccentColor? fluentAccentColor,
  }) : styles = styles ?? implementedStyles,
       primaryColor = primaryColor ?? Colors.blue,
       fluentAccentColor = fluentAccentColor ?? fluent.Colors.blue,
       super(name: 'Design Language');

  /// The styles arc_ui currently ships factories for.
  ///
  /// [UIStyle.windows11] and [UIStyle.custom] are intentionally left out: no
  /// registry has an entry for them yet, so selecting them would only ever
  /// render the "unsupported style" fallback.
  static const List<UIStyle> implementedStyles = [
    UIStyle.material,
    UIStyle.cupertino,
    UIStyle.fluent,
    UIStyle.macos,
    UIStyle.liquid,
  ];

  /// The styles offered in the dropdown.
  final List<UIStyle> styles;

  /// The style selected on first load.
  final UIStyle initialStyle;

  /// Accent colour handed to [macos.MacosThemeData].
  final Color primaryColor;

  /// Accent colour handed to [fluent.FluentThemeData].
  final fluent.AccentColor fluentAccentColor;

  @override
  List<Field> get fields => [
    ObjectDropdownField<UIStyle>(
      name: 'style',
      values: styles,
      initialValue: initialStyle,
      labelBuilder: uiStyleLabel,
    ),
  ];

  @override
  UIStyle valueFromQueryGroup(Map<String, String> group) {
    return valueOf<UIStyle>('style', group) ?? initialStyle;
  }

  @override
  Widget buildUseCase(BuildContext context, Widget child, UIStyle setting) {
    // ArcTheme mirrors the ambient Material brightness into the
    // macOS/Fluent/Cupertino themes, so as long as the theme addon is listed
    // before this one in Widgetbook.addons, switching light/dark moves all
    // five design languages together.
    return ArcStyleScope(
      style: setting,
      child: ArcTheme(
        primaryColor: primaryColor,
        fluentAccentColor: fluentAccentColor,
        child: child,
      ),
    );
  }
}
