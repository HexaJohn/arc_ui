import 'package:arc_ui/src/arc/navigation.dart';
import 'package:arc_ui/src/arc/window.dart';
import 'package:flutter/cupertino.dart';

class CupertinoWindowFactory extends WindowFactory {
  @override
  String get styleName => 'Cupertino (iOS)';

  /// iOS has no menu bar and no analogue of one, so it is omitted outright
  /// rather than substituted. This is the case where the right adaptation is
  /// simply absence.
  @override
  ArcMenuPresentation resolveMenuPresentation({required double width}) =>
      ArcMenuPresentation.none;

  /// A sidebar can host search in its leading slot; a tab strip cannot, so it
  /// goes above the content instead — which is where iOS puts search anyway.
  @override
  ArcSearchPlacement resolveSearchPlacement({required double width}) =>
      width < 768
      ? ArcSearchPlacement.contentTop
      : ArcSearchPlacement.navigationLeading;

  @override
  Widget createWindow(ArcWindowSpec spec) {
    final search = CupertinoSearchTextField(
      controller: spec.searchController,
      placeholder: spec.searchPlaceholder,
      onChanged: spec.onSearchChanged,
    );

    final navigation = spec.buildNavigation(
      leading: spec.searchPlacement == ArcSearchPlacement.navigationLeading
          ? search
          : null,
    );

    if (spec.searchPlacement != ArcSearchPlacement.contentTop) {
      return navigation;
    }

    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: search,
          ),
        ),
        Expanded(child: navigation),
      ],
    );
  }
}

/// Reserved so a Liquid Glass window can share Cupertino's navigation shape
/// without importing the whole factory.
ArcNavPresentation cupertinoPresentationFor(double width) =>
    width < 768 ? ArcNavPresentation.bottomTabs : ArcNavPresentation.topTabs;
