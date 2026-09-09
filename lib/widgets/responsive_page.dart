import 'dart:math' as math;

import 'package:flutter/widgets.dart';

EdgeInsets responsivePagePadding(
  BuildContext context, {
  double horizontal = 16,
  double vertical = 16,
  double maxWidth = 720,
}) {
  final side = math.max(
    horizontal,
    (MediaQuery.sizeOf(context).width - maxWidth) / 2,
  );
  return EdgeInsets.symmetric(horizontal: side, vertical: vertical);
}
