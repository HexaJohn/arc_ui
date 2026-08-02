# arc_ui sandbox

An interactive component sandbox for `arc_ui`, built with
[Widgetbook](https://docs.widgetbook.io) — Flutter's equivalent of Storybook.

## Running it

```sh
cd widgetbook
flutter run -d macos     # recommended
flutter run -d chrome    # Liquid Glass falls back, see below
```

Or use the **arc_ui sandbox (widgetbook)** launch config in VS Code.

### Liquid Glass and Impeller

`liquid_glass_renderer` asserts rather than degrades when Impeller is off, and
Impeller is not the default for macOS on this toolchain — that is what the
`--enable-impeller` args in `.vscode/launch.json` are for. The sandbox sets
`FLTEnableImpeller` in `macos/Runner/Info.plist` instead, so it works under
`flutter run`, `flutter build` and Finder alike, with no flag.

On backends that genuinely cannot support it (web), `LiquidGlassGuard`
substitutes a "Needs Impeller" placeholder rather than letting the assert fire
once per widget per frame.

## Regenerating the navigation tree

Use cases are discovered from `@UseCase` annotations, so the tree has to be
regenerated whenever one is added, renamed or removed:

```sh
cd widgetbook
dart run build_runner build     # or: watch
```

That writes `lib/main.directories.g.dart`, which is checked in.

## The Design Language addon

`arc_ui`'s whole premise is that one widget renders in several design
languages, so the sandbox promotes `UIStyle` to a global toolbar control rather
than a per-use-case knob. `UIStyleAddon` (`lib/addons/ui_style_addon.dart`)
does two things:

1. Publishes the selected `UIStyle` through `ArcStyleScope`, so a use case
   reads `ArcStyleScope.of(context)` instead of hardcoding a style. Adding a
   widget to the sandbox therefore costs one use case, not one per style.
2. Installs the theme ancestors the factories reach for — `MacosTheme` for
   `PushButton`, `FluentTheme` for the Fluent widgets, `CupertinoTheme` for the
   iOS and Liquid Glass ones — and mirrors the Material theme's brightness into
   each, so switching Light/Dark moves all five styles together.

Because addons wrap use cases in list order, `MaterialThemeAddon` must stay
above `UIStyleAddon` in `main.dart`; otherwise the brightness it reads is the
default rather than the selected one.

## Adding a use case

```dart
@widgetbook.UseCase(name: 'Default', type: ArcCheckbox, path: '[Components]')
Widget buildArcCheckboxUseCase(BuildContext context) {
  return ArcCheckbox(
    value: context.knobs.boolean(label: 'Value'),
    style: ArcStyleScope.of(context),
  );
}
```

Drop it in `lib/use_cases/`, rerun `build_runner`, and it appears under
Components with the design language and theme controls already applied.

## What is covered

All five design languages are implemented for every component below.

| Component     | Use cases                    |
| ------------- | ---------------------------- |
| `ArcButton`   | Default, Types, Style Matrix |
| `ArcAppBar`   | Default, Style Matrix        |
| `ArcScaffold` | Default, Style Matrix        |
| `ArcCheckbox` | Default, Style Matrix        |
| `ArcSwitch`   | Default, Style Matrix        |
| `ArcSlider`   | Default, Style Matrix        |

`Style Matrix` deliberately ignores the toolbar selection and renders the
component against every `UIStyle` at once — it is the interactive version of
`example/lib/views/buttons.dart`. It is the fastest way to spot a style that
has drifted.

Controls that hold a value are wrapped in `ValueHarness` so they stay clickable
rather than being frozen at whatever the knob says.

## Tests

`test/use_case_test.dart` renders every `ArcButton` style/type pair through the
addon's own wrapper, so it fails if the addon stops providing a theme a factory
depends on.

```sh
cd widgetbook
flutter test
```

The headless test binding has no Impeller, so the Liquid Glass cases assert
that `LiquidGlassGuard` falls back cleanly instead of throwing. Verify the real
glass rendering by running the sandbox on macOS.
