# arc_ui

**ARC — Adaptive Rendering Components.** One widget API that renders in the
design language you ask for: Material, Cupertino, Fluent, macOS, or Liquid Glass.

Write `ArcButton` once. Pass a different `UIStyle` and it becomes a Material
button, a Cupertino button, or a Fluent one — same call site, same behaviour,
native look on every target.

## Features

- **Seven widgets, five design languages.** Buttons, checkboxes, sliders,
  switches, app bars, scaffolds and navigation, each available in Material,
  Cupertino, Fluent, macOS and Liquid Glass.
- **Style is a parameter, not a fork.** No `if (Platform.isIOS)` branches at the
  call site; the style travels as an argument.
- **Extensible by registration.** Ship your own design language by registering a
  factory against `UIStyle.custom` — no fork of this package required.

## Getting started

```yaml
dependencies:
  arc_ui: ^0.0.1
```

## Usage

```dart
import 'package:arc_ui/arc_ui.dart';

ArcScaffold(
  style: UIStyle.fluent,
  appBar: const ArcAppBar(title: Text('Settings'), style: UIStyle.fluent),
  body: Column(
    children: [
      ArcCheckbox(
        value: subscribed,
        onChanged: (v) => setState(() => subscribed = v),
        style: UIStyle.fluent,
      ),
      ArcButton(
        text: 'Save',
        onPressed: save,
        style: UIStyle.fluent,
        type: ButtonType.primary,
      ),
    ],
  ),
);
```

Swap every `UIStyle.fluent` for `UIStyle.macos` and the same screen renders as a
native macOS one.

### Adding your own style

```dart
class BrandButtonFactory implements ButtonFactory {
  @override
  String get styleName => 'Brand';

  @override
  Widget createButton({
    required String text,
    required VoidCallback onPressed,
    ButtonType type = ButtonType.primary,
  }) => /* your button */;
}

ButtonStyleRegistry.registerFactory(UIStyle.custom, BrandButtonFactory());
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
