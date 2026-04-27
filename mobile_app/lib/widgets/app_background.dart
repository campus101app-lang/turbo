// lib/widgets/app_background.dart
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CustomPaint(
      painter: _DotGridPainter(isDark: isDark),
      child: ColoredBox(
        color: isDark
            ? const Color(0xFF0D0D0D) // --color-bg dark
            : const Color(0xFFF9F7F4), // --color-bg light
        child: child,
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  final bool isDark;

  const _DotGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Web CSS: radial-gradient(var(--color-border) 0.75px, transparent 0.75px)
    // background-size: 22px 22px (light) / 24px 24px (dark)
    //
    // --color-border light: rgba(0,0,0, 0.08)
    // --color-border dark:  rgba(255,255,255, 0.08)
    final dotColor = isDark
        ? const Color(0x14FFFFFF) // rgba(255,255,255, 0.08)
        : const Color(0x14000000); // rgba(0,0,0, 0.08)

    final double spacing = isDark ? 24.0 : 22.0;
    const double radius = 0.75;

    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.isDark != isDark;
}