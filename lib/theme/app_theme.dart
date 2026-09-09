import 'package:flutter/material.dart';
import 'package:sc300_prep/core/constants/exam_constants.dart';

class AppTheme {
  static const Color seedColor = Color(0xFF0078D4); // Microsoft Entra Blue
  static const Color xpColor = Colors.amber;
  static const Color streakColor = Colors.deepOrange;

  static const List<Color> _domainPalette = [
    Colors.lightBlueAccent,
    Colors.tealAccent,
    Colors.indigoAccent,
    Colors.purpleAccent,
  ];

  static Color domainColor(String domain) {
    final index = ExamConstants.allDomains.indexOf(domain);
    if (index == -1) return Colors.blueGrey;
    return _domainPalette[index % _domainPalette.length];
  }

  /// Clearance to reserve below bottom-anchored primary action buttons so
  /// they don't sit inside the Android gesture-nav swallow zone.
  static double safeBottomInset(BuildContext context) {
    final mq = MediaQuery.of(context);
    final reported = mq.systemGestureInsets.bottom > mq.viewPadding.bottom
        ? mq.systemGestureInsets.bottom
        : mq.viewPadding.bottom;
    return reported + 24;
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0D1117),
      appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
    );
  }
}
