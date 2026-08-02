import 'package:arc_ui/arc_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The macOS sidebar floats *over* the window, so whether the body is given the
/// whole width or only the room beside the panel is a layout decision the body
/// cannot make for itself. Getting it wrong is invisible to a test that only
/// checks the body is present — it renders fine, just underneath the sidebar —
/// so these assert geometry rather than existence.

const _bodyKey = ValueKey('body');

Widget _window({
  required ArcSidebarContentLayout layout,
  required ArcNavBodyBuilder bodyBuilder,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Material(
      // Installs the MacosTheme ancestor the macOS factory requires.
      child: ArcTheme(
        child: ArcWindowTheme(
          floatingSidebar: ArcFloatingSidebarStyle(contentLayout: layout),
          // Off: it reaches for the host NSWindow, which does not exist here.
          tallTitlebar: false,
          child: ArcWindow(
            style: UIStyle.macos,
            navigation: ArcNavSource.sections(const [
              ArcDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
              ArcDestination(label: 'Sent', icon: Icon(Icons.send)),
            ]),
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            bodyBuilder: bodyBuilder,
          ),
        ),
      ),
    ),
  );
}

/// Fills whatever it is given, so its painted rect *is* the answer to "how much
/// room did the body actually get".
Widget _filling(BuildContext context, ArcDestination destination, int index) =>
    const SizedBox.expand(
      child: ColoredBox(key: _bodyKey, color: Color(0xFFFF0000)),
    );

void main() {
  const width = 1200.0;

  void sizeWindow(WidgetTester tester) {
    tester.view.physicalSize = const Size(width, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('a window with no theme at all insets its body', (tester) async {
    sizeWindow(tester);

    // No ArcWindowTheme: package defaults only. This is the reported case —
    // an existing layout dropped into bodyBuilder by someone who has not read
    // anything about sidebar insets — so it is asserted against the defaults
    // rather than against an explicit contentLayout.
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Material(
          child: ArcTheme(
            child: ArcWindow(
              style: UIStyle.macos,
              navigation: ArcNavSource.sections(const [
                ArcDestination(label: 'Inbox', icon: Icon(Icons.inbox)),
              ]),
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              bodyBuilder: _filling,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getRect(find.byKey(_bodyKey)).left, greaterThan(200));
  });

  testWidgets('inset: the body is laid out clear of the panel', (tester) async {
    sizeWindow(tester);

    await tester.pumpWidget(
      _window(
        layout: ArcSidebarContentLayout.inset,
        bodyBuilder: _filling,
      ),
    );
    await tester.pumpAndSettle();

    final body = tester.getRect(find.byKey(_bodyKey));

    // The reported bug: a body dropped in unmodified must not be drawn
    // underneath the sidebar.
    expect(
      body.left,
      greaterThan(200),
      reason: 'body should start beside the ~240px panel, not at the edge',
    );
    expect(body.right, moreOrLessEquals(width, epsilon: 1));
  });

  testWidgets('bleed: the body is given the whole window', (tester) async {
    sizeWindow(tester);

    await tester.pumpWidget(
      _window(
        layout: ArcSidebarContentLayout.bleed,
        bodyBuilder: _filling,
      ),
    );
    await tester.pumpAndSettle();

    final body = tester.getRect(find.byKey(_bodyKey));

    expect(body.left, moreOrLessEquals(0, epsilon: 1));
    expect(body.right, moreOrLessEquals(width, epsilon: 1));
  });

  /// Reads the padding from a `Builder` inside the body, which is where a
  /// caller has to read it — see below for why the bodyBuilder context cannot.
  Future<double> paddingInsideBody(
    WidgetTester tester,
    ArcSidebarContentLayout layout,
  ) async {
    late double seen;
    await tester.pumpWidget(
      _window(
        layout: layout,
        bodyBuilder: (context, destination, index) => Builder(
          builder: (context) {
            seen = MediaQuery.paddingOf(context).left;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return seen;
  }

  testWidgets('bleed publishes the footprint to the body', (tester) async {
    sizeWindow(tester);

    expect(
      await paddingInsideBody(tester, ArcSidebarContentLayout.bleed),
      greaterThan(200),
      reason: 'bleed must advertise the room the body has to keep clear',
    );
  });

  testWidgets('inset publishes nothing, having already taken the room out', (
    tester,
  ) async {
    sizeWindow(tester);

    // Zero rather than the footprint, so a body that defensively adds
    // paddingOf(context).left is correct under both layouts instead of being
    // inset twice under this one.
    expect(await paddingInsideBody(tester, ArcSidebarContentLayout.inset), 0);
  });

  testWidgets('the bodyBuilder context cannot see the inset', (tester) async {
    sizeWindow(tester);

    late double atBuilder;
    await tester.pumpWidget(
      _window(
        layout: ArcSidebarContentLayout.bleed,
        bodyBuilder: (context, destination, index) {
          atBuilder = MediaQuery.paddingOf(context).left;
          return const SizedBox.expand();
        },
      ),
    );
    await tester.pumpAndSettle();

    // Pinned deliberately. That context belongs to ArcNavigation, which sits
    // above the sidebar and so above the padding it installs — reading the
    // inset there reports 0 even in bleed, which looks exactly like the inset
    // "not working". The fix is a Builder inside the body, and this test is
    // here so the constraint is not silently reintroduced as a surprise.
    expect(atBuilder, 0);
  });
}
