import 'package:arc_ui/arc_ui.dart';
import 'package:example/views/native_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:macos_window_utils/macos/ns_visual_effect_view_material.dart';
import 'package:macos_window_utils/macos/ns_window_button_type.dart';
import 'package:macos_window_utils/window_manipulator.dart';

/// A live bench for tuning the default window chrome.
///
/// The window under test fills the left; every knob that affects its look sits
/// in the inspector on the right, so changes are visible without a restart.
/// Values that settle here can be promoted straight into
/// [ArcFloatingSidebarStyle]'s defaults.
class WindowBench extends StatefulWidget {
  const WindowBench({
    super.key,
    required this.brightness,
    required this.onBrightnessChanged,
  });

  final Brightness brightness;
  final ValueChanged<Brightness> onBrightnessChanged;

  @override
  State<WindowBench> createState() => _WindowBenchState();
}

class _WindowBenchState extends State<WindowBench> {
  UIStyle _style = UIStyle.macos;
  // Defaults now carry the macOS look, so the bench starts from them rather
  // than overriding: the panel reaches the top edge and the window buttons
  // sit on it, with contentTopInset holding the items clear.
  var _sidebar = const ArcFloatingSidebarStyle();

  double _windowRadius = 16;
  bool _customWindowShape = false;
  bool _tallTitlebar = true;
  ArcSearchPlacement? _searchPlacement;
  Offset? _buttonOffset;
  ArcWindowBackground _background = ArcWindowBackground.wallpaperTint;
  double _tintStrength = 0.10;
  bool _showSearch = true;
  bool _showMenus = true;

  /// Hands the content pane to the embedded SwiftUI view.
  ///
  /// Apple's own source list next to ours, at the same size, on the same
  /// display — which is the only way to settle the pixel questions the rest of
  /// this bench exists to ask.
  bool _showNative = false;
  int _selected = 0;
  String _query = '';

  /// Modelled on macOS Mail's source list: grouped sections, nested accounts,
  /// unread counts, and flag colours that survive selection.
  static const _accounts = ['Exchange', 'Work', 'iCloud', 'Personal'];

  static ArcDestination _flag(String name, Color color, [String? badge]) =>
      ArcDestination(
        label: name,
        icon: ArcIcon(ArcIcons.flag, color: color),
        badge: badge,
        group: 'Favorites',
      );

  static final _destinations = ArcNavSource.sections([
    ArcDestination(
      label: 'All Inboxes',
      icon: const ArcIcon(ArcIcons.inbox),
      group: 'Favorites',
      children: [
        ArcDestination(
          label: 'Exchange',
          icon: const ArcIcon(ArcIcons.inbox),
          badge: '124',
          // Nested two deep, as Mail does — an account with its own folders.
          children: const [
            ArcDestination(label: 'Focused', icon: ArcIcon(ArcIcons.inbox)),
            ArcDestination(label: 'Other', icon: ArcIcon(ArcIcons.inbox)),
          ],
        ),
        const ArcDestination(
          label: 'Work',
          icon: ArcIcon(ArcIcons.inbox),
          badge: '20',
        ),
        const ArcDestination(label: 'iCloud', icon: ArcIcon(ArcIcons.inbox)),
        const ArcDestination(
          label: 'Personal',
          icon: ArcIcon(ArcIcons.inbox),
          badge: '23',
        ),
      ],
    ),
    const ArcDestination(
      label: 'VIPs',
      icon: ArcIcon(ArcIcons.star, color: Color(0xFFF5C518)),
      group: 'Favorites',
      children: [
        ArcDestination(
          label: 'Lance Hartsman',
          icon: ArcIcon(ArcIcons.star, color: Color(0xFFF5C518)),
        ),
      ],
    ),
    ArcDestination(
      label: 'Flagged',
      icon: const ArcIcon(ArcIcons.flag),
      group: 'Favorites',
      children: [
        _flag('Orange', const Color(0xFFF09A34), '49'),
        _flag('Red', const Color(0xFFE8453C), '47'),
        _flag('Blue', const Color(0xFF41B7F0), '3'),
        _flag('Green', const Color(0xFF3DC451), '3'),
        _flag('Robotics', const Color(0xFF9199A1), '22'),
      ],
    ),
    ArcDestination(
      label: 'All Drafts',
      icon: const ArcIcon(ArcIcons.drafts),
      group: 'Favorites',
      children: [
        for (final account in _accounts)
          ArcDestination(
            label: account,
            icon: const ArcIcon(ArcIcons.drafts),
            badge:
                const {
                  'Exchange': '26',
                  'iCloud': '3',
                  'Personal': '6',
                }[account],
          ),
      ],
    ),
    ArcDestination(
      label: 'All Sent',
      icon: const ArcIcon(ArcIcons.send),
      group: 'Favorites',
      children: [
        for (final account in _accounts)
          ArcDestination(label: account, icon: const ArcIcon(ArcIcons.send)),
      ],
    ),
    const ArcDestination(
      label: 'Today',
      icon: ArcIcon(ArcIcons.star),
      group: 'Smart Mailboxes',
    ),
    const ArcDestination(
      label: 'Trash',
      icon: ArcIcon(ArcIcons.trash),
      group: 'On My Mac',
    ),
  ]);

  @override
  void initState() {
    super.initState();
    // Nothing to push: ArcMacosTitlebar applies and removes the toolbar with
    // its own lifetime, so it follows the selected design language for free.
  }

  @override
  Widget build(BuildContext context) {
    // A Scaffold, not a bare Row: MaterialApp.home supplies no Material
    // ancestor, and the inspector is built from Material widgets that assert
    // on one. It also gives ScaffoldMessenger somewhere to host snack bars,
    // and paints the surface the floating sidebar blurs against.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this the docked inspector would leave the window pane too
        // narrow to judge anything, and a fixed 300px pane overflows the Row
        // outright once the window is smaller than it. So it moves into a
        // drawer instead of shrinking into uselessness.
        final docked = constraints.maxWidth >= 720;
        return _scaffold(context, docked: docked);
      },
    );
  }

  Widget _scaffold(BuildContext context, {required bool docked}) {
    // Clipped at the root, above the inspector too — the window's corners are
    // the whole surface, not just the ArcWindow pane.
    return ArcWindowSurface(
      radius: _windowRadius,
      child: _body(context, docked: docked),
    );
  }

  Widget _body(BuildContext context, {required bool docked}) {
    final scaffold = _scaffoldFor(context, docked: docked);
    if (_background != ArcWindowBackground.wallpaperTint) return scaffold;
    return ArcWallpaperTintedSurface(
      color: Theme.of(context).colorScheme.surface,
      strength: _tintStrength,
      child: scaffold,
    );
  }

  Widget _scaffoldFor(BuildContext context, {required bool docked}) {
    return Scaffold(
      // Transparent for anything but opaque, or the Scaffold paints straight
      // over the native material and hides it everywhere except the sidebar,
      // which punches its own hole.
      backgroundColor:
          _background == ArcWindowBackground.opaque ? null : Colors.transparent,
      endDrawer: docked ? null : Drawer(width: 300, child: _inspector(context)),
      floatingActionButton:
          docked
              ? null
              : Builder(
                builder:
                    (context) => FloatingActionButton.small(
                      tooltip: 'Bench controls',
                      onPressed: Scaffold.of(context).openEndDrawer,
                      child: const Icon(Icons.tune),
                    ),
              ),
      body: Row(
        children: [
          Expanded(
            child: ArcWindowTheme(
              floatingSidebar: _sidebar,
              windowRadius: _windowRadius,
              tallTitlebar: _tallTitlebar,
              child: ArcWindow(
                style: _style,
                navigation: _destinations,
                selectedIndex: _selected,
                onDestinationSelected: (i) => setState(() => _selected = i),
                showSearch: _showSearch,
                searchPlacement: _searchPlacement,
                searchPlaceholder: 'Search mail',
                onSearchChanged: (q) => setState(() => _query = q),
                bodyBuilder: _buildPage,
                menus:
                    _showMenus
                        ? ArcMenus.standard(
                          appName: 'Arc Mail',
                          onNew: () => _toast('New'),
                          onOpen: () => _toast('Open'),
                          onSave: () => _toast('Save'),
                        )
                        : const [],
              ),
            ),
          ),
          if (docked) ...[
            const VerticalDivider(width: 1, thickness: 1),
            SizedBox(width: 300, child: _inspector(context)),
          ],
        ],
      ),
    );
  }

  /// Makes the whole window vibrant, not just the sidebar panel.
  ///
  /// Two halves are needed and neither works alone: the window's own
  /// NSVisualEffectView supplies the material, and the Flutter content above
  /// it has to stop painting an opaque background or it simply covers it up.
  Future<void> _setBackground(ArcWindowBackground mode) async {
    setState(() => _background = mode);
    // Only full vibrancy wants the window-level material to be the
    // see-through one; wallpaper tint supplies its own subview material, and
    // opaque hides whatever is behind it anyway.
    await WindowManipulator.setMaterial(
      mode == ArcWindowBackground.vibrant
          ? NSVisualEffectViewMaterial.underWindowBackground
          : NSVisualEffectViewMaterial.windowBackground,
    );
  }

  /// Repositions all three traffic lights to an exact offset.
  ///
  /// Unlike the toolbar — which only makes the titlebar taller, moving the
  /// buttons vertically by one of three fixed amounts — this sets x and y
  /// directly, so it can also pull them away from the left edge. Passing null
  /// restores AppKit's own placement.
  Future<void> _setButtonOffset(Offset? offset) async {
    setState(() => _buttonOffset = offset);
    for (final button in NSWindowButtonType.values) {
      await WindowManipulator.overrideStandardWindowButtonPosition(
        buttonType: button,
        offset: offset,
      );
    }
  }

  /// Swaps between AppKit masking the window and the content defining its
  /// shape.
  ///
  /// These are mutually exclusive: an empty mask image is what lets a clipped
  /// content tree become the window's real silhouette, but macos_window_utils
  /// documents that it also disables the NSVisualEffectView — so the vibrant
  /// sidebar and a custom corner radius cannot both be on. The shadow goes
  /// with it, since the docs warn an empty mask plus a shadow causes artifacts.
  Future<void> _setCustomWindowShape(bool on) async {
    setState(() => _customWindowShape = on);
    if (on) {
      await WindowManipulator.disableShadow();
      await WindowManipulator.addEmptyMaskImage();
    } else {
      await WindowManipulator.removeMaskImage();
      await WindowManipulator.enableShadow();
    }
  }

  void _toast(String label) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text('$label from the menu bar'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildPage(
    BuildContext context,
    ArcDestination destination,
    int index,
  ) {
    final theme = Theme.of(context);

    if (_showNative) {
      // Inset rather than full-bleed: an NSView is composited outside Flutter's
      // scene, so it would draw *over* the floating sidebar instead of sliding
      // under it, and none of the panel's blur would reach it.
      return Padding(
        padding: EdgeInsets.only(left: MediaQuery.paddingOf(context).left),
        child: const NativeSidebar(),
      );
    }

    // The content pane genuinely does get very narrow — the sidebar and the
    // inspector both eat into it — and watching the window cross its
    // breakpoints is the point of the bench, so the page has to survive any
    // width rather than assuming a comfortable one.
    return LayoutBuilder(
      builder: (context, constraints) {
        // The page runs full-bleed under the sidebar, so constraints.maxWidth
        // is the *window's* width, not the room actually left for content.
        // Sizing decisions have to subtract the inset, and it animates as the
        // panel slides — mid-collapse the two differ by the panel's whole
        // width, which is exactly when a leading widget stops fitting.
        final inset = MediaQuery.paddingOf(context).left;
        final width = (constraints.maxWidth - inset).clamp(
          0.0,
          double.infinity,
        );
        final padding = width < 320 ? 12.0 : 24.0;
        // A ListTile asserts once its leading widget plus content padding
        // consume the whole tile, so the avatar is dropped before that point
        // rather than being allowed to overflow.
        final showAvatar = width - padding * 2 > 200;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            padding + inset,
            padding,
            padding,
            padding,
          ),
          // Consumed here, so descendants do not apply it a second time. A
          // ListView with a null `padding` folds MediaQuery padding into its
          // own — so the rows below were being inset by the sidebar twice
          // while the heading above them was inset once.
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  destination.label,
                  style: theme.textTheme.headlineMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _query.isEmpty ? 'No search query' : 'Filtering by "$_query"',
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // maxWidth, not a fixed width: this must shrink rather than
                // overflow when the pane is narrower than 360.
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: const TextField(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Focus me, then try the Edit menu',
                      helperText: 'Undo / Cut / Copy / Paste use intents',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.separated(
                    itemCount: 12,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder:
                        (context, i) => ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: showAvatar ? 16 : 4,
                          ),
                          leading:
                              showAvatar
                                  ? CircleAvatar(child: Text('${i + 1}'))
                                  : null,
                          title: Text(
                            '${destination.label} message ${i + 1}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: const Text(
                            'Content sits directly on the window background',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _inspector(BuildContext context) {
    final theme = Theme.of(context);
    final isMacosChrome = _style == UIStyle.macos;

    return ColoredBox(
      color: theme.colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
        children: [
          Text('Window bench', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),

          _label(context, 'Design language'),
          DropdownButton<UIStyle>(
            isExpanded: true,
            value: _style,
            onChanged: (value) => setState(() => _style = value ?? _style),
            items: [
              for (final style in WindowStyleRegistry.availableStyles)
                DropdownMenuItem(value: style, child: Text(_styleLabel(style))),
            ],
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dark'),
            value: widget.brightness == Brightness.dark,
            onChanged:
                (on) => widget.onBrightnessChanged(
                  on ? Brightness.dark : Brightness.light,
                ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Search'),
            value: _showSearch,
            onChanged: (on) => setState(() => _showSearch = on),
          ),
          if (_showSearch) ...[
            _label(context, 'Search position'),
            DropdownButton<ArcSearchPlacement?>(
              isExpanded: true,
              value: _searchPlacement,
              onChanged: (v) => setState(() => _searchPlacement = v),
              items: const [
                DropdownMenuItem(value: null, child: Text('auto (by width)')),
                DropdownMenuItem(
                  value: ArcSearchPlacement.navigationLeading,
                  child: Text('Nav pane (Settings, App Store)'),
                ),
                DropdownMenuItem(
                  value: ArcSearchPlacement.windowTrailing,
                  child: Text('Top right (Mail, Finder)'),
                ),
              ],
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Menus'),
            value: _showMenus,
            onChanged: (on) => setState(() => _showMenus = on),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Native view'),
            subtitle: const Text('AppKit draws the content pane'),
            value: _showNative,
            onChanged:
                NativeSidebar.isSupported
                    ? (on) => setState(() => _showNative = on)
                    : null,
          ),

          const Divider(height: 32),
          _label(context, 'Window'),
          _label(context, 'Background'),
          DropdownButton<ArcWindowBackground>(
            isExpanded: true,
            value: _background,
            onChanged: (v) => _setBackground(v ?? _background),
            items: const [
              DropdownMenuItem(
                value: ArcWindowBackground.wallpaperTint,
                child: Text('Wallpaper tint'),
              ),
              DropdownMenuItem(
                value: ArcWindowBackground.vibrant,
                child: Text('Vibrant (translucent)'),
              ),
              DropdownMenuItem(
                value: ArcWindowBackground.opaque,
                child: Text('Opaque'),
              ),
            ],
          ),
          if (_background == ArcWindowBackground.wallpaperTint)
            _slider(
              context,
              'Tint strength',
              _tintStrength,
              0,
              1,
              (v) => setState(() => _tintStrength = v),
              fractionDigits: 2,
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Taller titlebar'),
            subtitle: Text(
              'Adds a unified NSToolbar — AppKit re-centres the window '
              'buttons in it. macOS style only; other styles remove it.',
              style: theme.textTheme.bodySmall,
            ),
            value: _tallTitlebar,
            onChanged: (on) => setState(() => _tallTitlebar = on),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Override button position'),
            subtitle: Text(
              'Sets x/y exactly — the only way to move them away from the '
              'left edge, which a taller titlebar cannot do',
              style: theme.textTheme.bodySmall,
            ),
            value: _buttonOffset != null,
            onChanged:
                (on) => _setButtonOffset(on ? const Offset(20, 20) : null),
          ),
          if (_buttonOffset != null) ...[
            _slider(
              context,
              'Buttons X',
              _buttonOffset!.dx,
              0,
              60,
              (v) => _setButtonOffset(Offset(v, _buttonOffset!.dy)),
            ),
            _slider(
              context,
              'Buttons Y',
              _buttonOffset!.dy,
              0,
              60,
              (v) => _setButtonOffset(Offset(_buttonOffset!.dx, v)),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Custom window shape'),
            subtitle: Text(
              _customWindowShape
                  ? 'Content defines the shape — radius slider is live, but '
                      'the sidebar loses its NSVisualEffectView'
                  : 'AppKit masks the window — vibrancy works, radius slider '
                      'has no effect',
              style: theme.textTheme.bodySmall,
            ),
            value: _customWindowShape,
            onChanged: _setCustomWindowShape,
          ),
          _slider(
            context,
            'Corner radius',
            _windowRadius,
            0,
            40,
            (v) => setState(() => _windowRadius = v),
          ),

          const Divider(height: 32),
          _label(context, 'Floating sidebar'),
          _label(context, 'Content layout'),
          DropdownButton<ArcSidebarContentLayout>(
            isExpanded: true,
            value: _sidebar.contentLayout,
            onChanged:
                (v) => setState(
                  () => _sidebar = _sidebar.copyWith(contentLayout: v),
                ),
            items: const [
              DropdownMenuItem(
                value: ArcSidebarContentLayout.inset,
                child: Text('inset (beside the panel)'),
              ),
              DropdownMenuItem(
                value: ArcSidebarContentLayout.bleed,
                child: Text('bleed (under the panel)'),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Collapsible'),
            subtitle: Text(
              'Shows a toggle that slides the panel away; the control moves '
              'into the titlebar so it can be reopened',
              style: theme.textTheme.bodySmall,
            ),
            value: _sidebar.collapsible,
            onChanged:
                (on) => setState(
                  () => _sidebar = _sidebar.copyWith(collapsible: on),
                ),
          ),
          if (!isMacosChrome)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Only the macOS style uses the floating surface.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          _slider(
            context,
            'Inset',
            _sidebar.inset,
            0,
            32,
            (v) => setState(() => _sidebar = _sidebar.copyWith(inset: v)),
          ),
          _slider(
            context,
            'Top inset',
            _sidebar.topInset,
            0,
            64,
            (v) => setState(() => _sidebar = _sidebar.copyWith(topInset: v)),
          ),
          _slider(
            context,
            'Content top',
            _sidebar.contentTopInset,
            0,
            64,
            (v) => setState(
              () => _sidebar = _sidebar.copyWith(contentTopInset: v),
            ),
          ),
          _slider(
            context,
            'Radius',
            _sidebar.radius,
            0,
            28,
            (v) => setState(() => _sidebar = _sidebar.copyWith(radius: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Vibrancy'),
            subtitle: Text(
              _sidebar.vibrancy
                  ? 'Native NSVisualEffectView — samples the desktop'
                  : 'BackdropFilter — blurs only the app\'s own pixels',
              style: theme.textTheme.bodySmall,
            ),
            value: _sidebar.vibrancy,
            onChanged:
                (on) =>
                    setState(() => _sidebar = _sidebar.copyWith(vibrancy: on)),
          ),
          _label(context, 'Panel material'),
          DropdownButton<NSVisualEffectViewMaterial>(
            isExpanded: true,
            value: _sidebar.material,
            onChanged:
                (v) => setState(
                  () => _sidebar = _sidebar.copyWith(material: v),
                ),
            items: const [
              DropdownMenuItem(
                value: NSVisualEffectViewMaterial.windowBackground,
                child: Text('windowBackground (matches window)'),
              ),
              DropdownMenuItem(
                value: NSVisualEffectViewMaterial.underWindowBackground,
                child: Text('underWindowBackground'),
              ),
              DropdownMenuItem(
                value: NSVisualEffectViewMaterial.sidebar,
                child: Text('sidebar (brighter)'),
              ),
              DropdownMenuItem(
                value: NSVisualEffectViewMaterial.contentBackground,
                child: Text('contentBackground'),
              ),
            ],
          ),
          _slider(
            context,
            'Vibrancy vs bleed',
            _sidebar.vibrancyAmount,
            0,
            1,
            (v) => setState(
              () => _sidebar = _sidebar.copyWith(vibrancyAmount: v),
            ),
            fractionDigits: 2,
          ),
          _slider(
            context,
            'Blur',
            _sidebar.blurSigma,
            0,
            60,
            (v) => setState(() => _sidebar = _sidebar.copyWith(blurSigma: v)),
          ),
          _slider(
            context,
            'Tint (inactive)',
            _sidebar.inactiveTintOpacity,
            0,
            0.4,
            (v) => setState(
              () => _sidebar = _sidebar.copyWith(inactiveTintOpacity: v),
            ),
            fractionDigits: 3,
          ),
          _slider(
            context,
            'Item fade (inactive)',
            _sidebar.inactiveContentOpacity,
            0.5,
            1,
            (v) => setState(
              () => _sidebar = _sidebar.copyWith(inactiveContentOpacity: v),
            ),
            fractionDigits: 2,
          ),
          _slider(
            context,
            'Tint (active)',
            _sidebar.tintOpacity,
            0,
            0.4,
            (v) => setState(() => _sidebar = _sidebar.copyWith(tintOpacity: v)),
            fractionDigits: 3,
          ),
          _slider(
            context,
            'Border',
            _sidebar.borderOpacity,
            0,
            0.4,
            (v) =>
                setState(() => _sidebar = _sidebar.copyWith(borderOpacity: v)),
            fractionDigits: 3,
          ),

          const Divider(height: 32),
          _label(context, 'Resolved chrome'),
          _readout(
            context,
            'Menu bar',
            WindowStyleRegistry.getFactory(
              _style,
            )!.resolveMenuPresentation(width: 900).name,
          ),
          _readout(
            context,
            'Search',
            WindowStyleRegistry.getFactory(
              _style,
            )!.resolveSearchPlacement(width: 900).name,
          ),
          _readout(
            context,
            'Sidebar size (OS)',
            ArcWindowTheme.sidebarItemSizeOf(context).name,
          ),
          _readout(
            context,
            'Scroll bars (OS)',
            ArcSystemPreferences.scrollbarVisibilityOf(context).name,
          ),
          _readout(
            context,
            'Track click (OS)',
            ArcSystemPreferences.scrollbarPagingOf(context).name,
          ),
          _readout(
            context,
            'Text scale',
            MediaQuery.textScalerOf(context).scale(1).toStringAsFixed(2),
          ),
          _readout(
            context,
            'Window focus',
            ArcWindowFocus.of(context) ? 'active' : 'inactive',
          ),
          _readout(
            context,
            'Sidebar tint',
            (ArcWindowFocus.of(context)
                    ? _sidebar.tintOpacity
                    : _sidebar.inactiveTintOpacity)
                .toStringAsFixed(2),
          ),
          _readout(
            context,
            'System menu bar',
            arcHasSystemMenuBar ? 'available' : 'unavailable',
          ),

          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => debugPrint(_asDartLiteral()),
            child: const Text('Print style to console'),
          ),
          const SizedBox(height: 8),
          Text(
            'Copy the printed literal into ArcFloatingSidebarStyle to make '
            'these the defaults.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _asDartLiteral() =>
      '// windowRadius: ${_windowRadius.toStringAsFixed(1)}\n'
      'const ArcFloatingSidebarStyle(\n'
      '  inset: ${_sidebar.inset.toStringAsFixed(1)},\n'
      '  topInset: ${_sidebar.topInset.toStringAsFixed(1)},\n'
      '  contentTopInset: ${_sidebar.contentTopInset.toStringAsFixed(1)},\n'
      '  radius: ${_sidebar.radius.toStringAsFixed(1)},\n'
      '  blurSigma: ${_sidebar.blurSigma.toStringAsFixed(1)},\n'
      '  vibrancyAmount: ${_sidebar.vibrancyAmount.toStringAsFixed(2)},\n'
      '  inactiveTintOpacity: ${_sidebar.inactiveTintOpacity.toStringAsFixed(3)},\n'
      '  inactiveContentOpacity: ${_sidebar.inactiveContentOpacity.toStringAsFixed(2)},\n'
      '  material: NSVisualEffectViewMaterial.${_sidebar.material.name},\n'
      '  tintOpacity: ${_sidebar.tintOpacity.toStringAsFixed(3)},\n'
      '  borderOpacity: ${_sidebar.borderOpacity.toStringAsFixed(3)},\n'
      ');';

  static String _styleLabel(UIStyle style) => switch (style) {
    UIStyle.material => 'Material',
    UIStyle.cupertino => 'Cupertino (iOS)',
    UIStyle.fluent => 'Fluent (Windows)',
    UIStyle.macos => 'macOS',
    UIStyle.liquid => 'Liquid Glass',
    UIStyle.windows11 => 'Windows 11',
    UIStyle.custom => 'Custom',
  };

  Widget _label(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );

  Widget _readout(BuildContext context, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(width: 8),
        // Flexible: values like "navigationLeading" are wider than the
        // inspector's remaining space.
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _slider(
    BuildContext context,
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    int fractionDigits = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              value.toStringAsFixed(fractionDigits),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            overlayShape: SliderComponentShape.noOverlay,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
