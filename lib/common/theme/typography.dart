import 'package:flutter/material.dart';

/// Shared font family for hero headers to mirror the SpeedView web branding.
const String speedViewHeadingFontFamily = 'Alphacorsa';

TextStyle speedViewHeadingStyle(
  BuildContext context, {
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
}) {
  final base = Theme.of(context).textTheme.headlineMedium ??
      const TextStyle(fontSize: 28, fontWeight: FontWeight.w700);
  return base.copyWith(
    fontFamily: speedViewHeadingFontFamily,
    fontSize: fontSize ?? base.fontSize,
    fontWeight: fontWeight ?? base.fontWeight,
    color: color ?? base.color ?? Colors.white,
    letterSpacing: letterSpacing ?? 1.1,
  );
}
