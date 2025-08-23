import 'package:flutter/widgets.dart';

abstract class ActivityIndicator extends StatelessWidget {
  /// Creates a new activity indicator.
  const ActivityIndicator({super.key, this.animating = true, this.size = 20.0, this.color});

  /// Whether the activity indicator is animating.
  final bool animating;

  /// The size of the activity indicator.
  final double size;

  /// The color of the activity indicator.
  final Color? color;

  @override
  Widget build(BuildContext context);
}
