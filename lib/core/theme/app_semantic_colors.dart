import 'package:flutter/material.dart';

/// Theme-aware colors for meanings [ColorScheme] doesn't cover (a rising
/// price, a starred icon) — keeps them out of hardcoded `Colors.xyz` literals
/// so both light and dark themes stay legible and consistent.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color positive;
  final Color starred;

  const AppSemanticColors({required this.positive, required this.starred});

  static const light = AppSemanticColors(
    positive: Color(0xFF2E7D32),
    starred: Color(0xFFF9A825),
  );

  static const dark = AppSemanticColors(
    positive: Color(0xFF66BB6A),
    starred: Color(0xFFFFCA28),
  );

  @override
  AppSemanticColors copyWith({Color? positive, Color? starred}) {
    return AppSemanticColors(
      positive: positive ?? this.positive,
      starred: starred ?? this.starred,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      positive: Color.lerp(positive, other.positive, t)!,
      starred: Color.lerp(starred, other.starred, t)!,
    );
  }
}
