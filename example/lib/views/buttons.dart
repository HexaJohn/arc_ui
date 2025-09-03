import 'package:arc_ui/arc_ui.dart';
import 'package:arc_ui/registry/button.dart';
import 'package:example/widgets/grid_painter.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart' as macos;

class Buttons extends StatelessWidget {
  const Buttons({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return macos.MacosTheme(
      data: macos.MacosThemeData(
        primaryColor: Colors.blue,
      ),
      child: fluent.FluentTheme(
        data: fluent.FluentThemeData(
          accentColor: fluent.Colors.blue,
        ),
        child: Scaffold(
          backgroundColor: Colors.grey[300],
          body: Stack(
            children: [
              // Background grid generator
              Builder(
                builder: (context) {
                  return CustomPaint(
                    size: MediaQuery.of(context).size,
                    painter: GridPainter(
                      gridStroke: 1,
                      gridColor: Colors.grey[400]!,
                    ),
                  );
                },
              ),
              Center(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ArcButton(
                            text: 'Fluent',
                            onPressed: () {},
                            style: UIStyle.fluent,
                          ),
                          ArcButton(
                            text: 'MacOS',
                            onPressed: () {},
                            style: UIStyle.macos,
                          ),
                          ArcButton(
                            text: 'Cupertino',
                            onPressed: () {},
                            style: UIStyle.cupertino,
                          ),
                          ArcButton(
                            text: 'Liquid Glass',
                            onPressed: () {},
                            style: UIStyle.liquid,
                          ),
                          ArcButton(
                            text: 'Material',
                            onPressed: () {},
                            style: UIStyle.material,
                          ),
                        ],
                      ),
                    ),
                    // ArcButton(text: 'Lorum Ipsum', onPressed: () {}),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
