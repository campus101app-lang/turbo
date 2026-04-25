// lib/widgets/app_background.dart
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.6, -0.8),
          radius: 1.4,
          colors: isDark
              ? [
                  const Color(0xFF1E1812), // warm dark brown top-left
                  const Color(0xFF141009), // warm near-black center
                  const Color(0xFF0D0A06), // deepest warm dark bottom
                ]
              : [
                  const Color(0xFFEDE5D8), // warm parchment top-left
                  const Color(0xFFF3EDE4), // soft warm center
                  const Color(0xFFFAF7F4), // lightest warm bottom
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }
}