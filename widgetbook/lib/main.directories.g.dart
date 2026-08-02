// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:arc_widgetbook/use_cases/app_bar.dart'
    as _arc_widgetbook_use_cases_app_bar;
import 'package:arc_widgetbook/use_cases/button.dart'
    as _arc_widgetbook_use_cases_button;
import 'package:arc_widgetbook/use_cases/controls.dart'
    as _arc_widgetbook_use_cases_controls;
import 'package:arc_widgetbook/use_cases/navigation.dart'
    as _arc_widgetbook_use_cases_navigation;
import 'package:arc_widgetbook/use_cases/scaffold.dart'
    as _arc_widgetbook_use_cases_scaffold;
import 'package:arc_widgetbook/use_cases/window.dart'
    as _arc_widgetbook_use_cases_window;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookCategory(
    name: 'Components',
    children: [
      _widgetbook.WidgetbookComponent(
        name: 'ArcAppBar',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _arc_widgetbook_use_cases_app_bar.buildArcAppBarUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Matrix',
            builder:
                _arc_widgetbook_use_cases_app_bar.buildArcAppBarMatrixUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcButton',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _arc_widgetbook_use_cases_button.buildArcButtonUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Matrix',
            builder:
                _arc_widgetbook_use_cases_button.buildArcButtonMatrixUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Types',
            builder:
                _arc_widgetbook_use_cases_button.buildArcButtonTypesUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcCheckbox',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _arc_widgetbook_use_cases_controls.buildArcCheckboxUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Matrix',
            builder: _arc_widgetbook_use_cases_controls
                .buildArcCheckboxMatrixUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcNavigation',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'App Store',
            builder:
                _arc_widgetbook_use_cases_navigation.buildArcNavigationUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Data source',
            builder: _arc_widgetbook_use_cases_navigation
                .buildArcNavigationDataUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Overflow (More)',
            builder: _arc_widgetbook_use_cases_navigation
                .buildArcNavigationOverflowUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Support matrix',
            builder: _arc_widgetbook_use_cases_navigation
                .buildArcNavigationMatrixUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcScaffold',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _arc_widgetbook_use_cases_scaffold.buildArcScaffoldUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Matrix',
            builder: _arc_widgetbook_use_cases_scaffold
                .buildArcScaffoldMatrixUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcSlider',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _arc_widgetbook_use_cases_controls.buildArcSliderUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Matrix',
            builder:
                _arc_widgetbook_use_cases_controls.buildArcSliderMatrixUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcSwitch',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Default',
            builder: _arc_widgetbook_use_cases_controls.buildArcSwitchUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Style Matrix',
            builder:
                _arc_widgetbook_use_cases_controls.buildArcSwitchMatrixUseCase,
          ),
        ],
      ),
      _widgetbook.WidgetbookComponent(
        name: 'ArcWindow',
        useCases: [
          _widgetbook.WidgetbookUseCase(
            name: 'Chrome matrix',
            builder:
                _arc_widgetbook_use_cases_window.buildArcWindowMatrixUseCase,
          ),
          _widgetbook.WidgetbookUseCase(
            name: 'Mail',
            builder: _arc_widgetbook_use_cases_window.buildArcWindowUseCase,
          ),
        ],
      ),
    ],
  ),
];
