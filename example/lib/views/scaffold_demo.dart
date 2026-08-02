import 'package:arc_ui/arc_ui.dart';
import 'package:example/widgets/grid_painter.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart' as macos;

class _ScaffoldStyle {
  final String name;
  final UIStyle style;

  _ScaffoldStyle(this.name, this.style);
}

class Scaffolds extends StatelessWidget {
  const Scaffolds({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<_ScaffoldStyle> scaffoldTypes = [
      _ScaffoldStyle('Fluent', UIStyle.fluent),
      _ScaffoldStyle('MacOS', UIStyle.macos),
      _ScaffoldStyle('Cupertino', UIStyle.cupertino),
      _ScaffoldStyle('Liquid Glass', UIStyle.liquid),
      _ScaffoldStyle('Material', UIStyle.material),
    ];

    return macos.MacosTheme(
      data: macos.MacosThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.blue,
      ),
      child: fluent.FluentTheme(
        data: fluent.FluentThemeData(
          accentColor: fluent.Colors.blue,
        ),
        child: macos.MacosScaffold(
          toolBar: macos.ToolBar(
            title: const Text('Untitled Document'),
            titleWidth: 200.0,
            leading: macos.MacosBackButton(
              onPressed: () => debugPrint('click'),
              fillColor: Colors.transparent,
            ),
            actions: [
              macos.ToolBarIconButton(
                label: "Add",
                icon: const macos.MacosIcon(
                  CupertinoIcons.add_circled,
                ),
                onPressed: () => debugPrint("Add..."),
                showLabel: true,
              ),
              const macos.ToolBarSpacer(),
              macos.ToolBarIconButton(
                label: "Delete",
                icon: const macos.MacosIcon(
                  CupertinoIcons.trash,
                ),
                onPressed: () => debugPrint("Delete"),
                showLabel: false,
              ),
              macos.ToolBarPullDownButton(
                label: "Actions",
                icon: CupertinoIcons.ellipsis_circle,
                items: [
                  macos.MacosPulldownMenuItem(
                    label: "New Folder",
                    title: const Text("New Folder"),
                    onTap: () => debugPrint("Creating new folder..."),
                  ),
                  macos.MacosPulldownMenuItem(
                    label: "Open",
                    title: const Text("Open"),
                    onTap: () => debugPrint("Opening..."),
                  ),
                ],
              ),
            ],
          ),
          // appBar: AppBar(
          // title: Text('HELLO'),
          // elevation: 10,
          // ),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          children: [
            macos.ContentArea(
              builder:
                  (
                    BuildContext context,
                    ScrollController scrollController,
                  ) => Stack(
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
                            children: [
                              // scaffoldTypes.map((type) {
                              // return
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children:
                                    scaffoldTypes.map((scaffold) {
                                      return SizedBox(
                                        width: 240,
                                        height: 180,
                                        child: ArcScaffold(
                                          style: scaffold.style,
                                          appBar: ArcAppBar(
                                            title: Text(scaffold.name),
                                            style: scaffold.style,
                                          ),
                                          body: Center(child: Text('Test!')),
                                        ),
                                      );
                                    }).toList(),
                              ),
                              //;
                              // }).toList(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
