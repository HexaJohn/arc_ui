import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// The glass treatment shared by every Liquid Glass factory, so a tweak to the
/// look lands on buttons, app bars and scaffolds at once.
const kArcLiquidGlassSettings = LiquidGlassSettings(
  thickness: 10,
  glassColor: Color.fromARGB(116, 255, 255, 255),
  lightIntensity: 1.5,
  lightAngle: 0.25 * pi,
  blend: 40,
  blur: 2,
);
