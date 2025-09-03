import 'package:arc_ui/arc_ui.dart';
import 'package:arc_ui/registry/button.dart';
import 'package:example/widgets/grid_painter.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart' as macos;

class _ButtonStyle {
  final String name;
  final UIStyle style;

  _ButtonStyle(this.name, this.style);
}

class Buttons extends StatelessWidget {
  const Buttons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<_ButtonStyle> buttonStyles = [
      _ButtonStyle('Fluent', UIStyle.fluent),
      _ButtonStyle('MacOS', UIStyle.macos),
      _ButtonStyle('Cupertino', UIStyle.cupertino),
      _ButtonStyle('Liquid Glass', UIStyle.liquid),
      _ButtonStyle('Material', UIStyle.material),
    ];

    final buttonTypes = [
      ButtonType.primary,
      ButtonType.secondary,
      ButtonType.outlined,
      ButtonType.text,
    ];

    return macos.MacosTheme(
      data: macos.MacosThemeData(
        primaryColor: Colors.blue,
      ),
      child: fluent.FluentTheme(
        data: fluent.FluentThemeData(
          accentColor: fluent.Colors.blue,
        ),
        child: Scaffold(
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          body: Stack(
            children: [
              // Background grid generator
              Builder(
                builder: (context) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: GridPainter(
                      gridStroke: 1,
                      gridColor: Colors.grey[400]!.withAlpha(32),
                    ),
                  );
                },
              ),
              Center(
                child: SizedBox(
                  height: 400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children:
                        buttonTypes.map((type) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children:
                                buttonStyles.map((button) {
                                  return SizedBox(
                                    width: 200,
                                    height: 100,
                                    child: Center(
                                      child: ArcButton(
                                        text: button.name,
                                        onPressed: () {},
                                        style: button.style,
                                        type: type,
                                      ),
                                    ),
                                  );
                                }).toList(),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
