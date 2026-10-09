import 'dart:math' as math;

import 'package:flutter/material.dart';

class OrbitColors {
  OrbitColors._();

  static const Color background = Color(0xFF0A0B16);
  static const Color panel = Color(0xFF171A2D);
  static const Color panelLight = Color(0xFF20243C);
  static const Color cyan = Color(0xFF8DEBFF);
  static const Color violet = Color(0xFFB995FF);
  static const Color gold = Color(0xFFFFD66F);
  static const Color pink = Color(0xFFFF80B7);
  static const Color text = Color(0xFFF6F6FF);
  static const Color muted = Color(0xFFA9B0CF);
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFF10152B), OrbitColors.background, Color(0xFF110D20)],
          ),
        ),
        child: Stack(
          children: <Widget>[
            Positioned(
              top: -130,
              left: -100,
              child: _GlowOrb(color: OrbitColors.cyan.withValues(alpha: 0.13), size: 310),
            ),
            Positioned(
              bottom: -170,
              right: -120,
              child: _GlowOrb(color: OrbitColors.violet.withValues(alpha: 0.11), size: 360),
            ),
            child,
          ],
        ),
      );
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: <Color>[color, Colors.transparent]),
          ),
        ),
      );
}

class NeonPanel extends StatelessWidget {
  const NeonPanel({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.borderColor});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: OrbitColors.panel.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: (borderColor ?? Colors.white).withValues(alpha: borderColor == null ? 0.08 : 0.42)),
          boxShadow: <BoxShadow>[
            BoxShadow(color: (borderColor ?? Colors.black).withValues(alpha: borderColor == null ? 0.13 : 0.1), blurRadius: 22, offset: const Offset(0, 9)),
          ],
        ),
        child: child,
      );
}

class NeonButton extends StatelessWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = OrbitColors.cyan,
    this.secondary = false,
    this.compact = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool secondary;
  final bool compact;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Color active = enabled ? color : OrbitColors.muted;
    return SizedBox(
      height: compact ? 43 : 54,
      child: Material(
        color: secondary ? Colors.transparent : active.withValues(alpha: enabled ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(17),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: compact ? 15 : 22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: active.withValues(alpha: secondary ? 0.35 : 0.64), width: 1.2),
              gradient: secondary
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[active.withValues(alpha: 0.24), active.withValues(alpha: 0.08)],
                    ),
              boxShadow: secondary || !enabled
                  ? const <BoxShadow>[]
                  : <BoxShadow>[BoxShadow(color: active.withValues(alpha: 0.16), blurRadius: 17, spreadRadius: 0.5)],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(icon, color: active, size: compact ? 17 : 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: enabled ? OrbitColors.text : OrbitColors.muted,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 11 : 13,
                    letterSpacing: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CurrencyPill extends StatelessWidget {
  const CurrencyPill({super.key, required this.icon, required this.value, required this.color});

  final IconData icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
        decoration: BoxDecoration(
          color: OrbitColors.panelLight.withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, color: color, size: 15),
            const SizedBox(width: 6),
            Text(value, style: const TextStyle(color: OrbitColors.text, fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, required this.onBack, this.trailing});

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          IconButton.filledTonal(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            style: IconButton.styleFrom(backgroundColor: OrbitColors.panelLight, foregroundColor: OrbitColors.cyan),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title, style: const TextStyle(color: OrbitColors.text, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Expanded(
            child: Text(title, style: const TextStyle(color: OrbitColors.text, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class ProgressMeter extends StatelessWidget {
  const ProgressMeter({super.key, required this.value, this.color = OrbitColors.cyan, this.height = 8});

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LinearProgressIndicator(
          minHeight: height,
          value: value.clamp(0, 1).toDouble(),
          color: color,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
        ),
      );
}

class BlobPreview extends StatelessWidget {
  const BlobPreview({super.key, required this.color, this.size = 52, this.shape = 'round'});

  final Color color;
  final double size;
  final String shape;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _BlobPreviewPainter(color: color, shape: shape),
      );
}

class _BlobPreviewPainter extends CustomPainter {
  const _BlobPreviewPainter({required this.color, required this.shape});

  final Color color;
  final String shape;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = size.width * 0.35;
    canvas.drawCircle(center, radius * 1.4, Paint()..color = color.withValues(alpha: 0.14)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    if (shape == 'star') {
      final Path path = Path();
      for (int i = 0; i < 10; i++) {
        final double angle = -1.57079632679 + i * 0.62831853072;
        final double r = i.isEven ? radius * 1.25 : radius * 0.76;
        final Offset point = center + Offset(r * math.cos(angle), r * math.sin(angle));
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color);
    } else if (shape == 'squircle') {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCircle(center: center, radius: radius), Radius.circular(radius * 0.48)), Paint()..color = color);
    } else {
      canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2.25, height: radius * 1.95), Paint()..shader = RadialGradient(colors: <Color>[Colors.white, color]).createShader(Rect.fromCircle(center: center, radius: radius * 1.3)));
    }
    canvas.drawCircle(Offset(center.dx - radius * 0.3, center.dy - radius * 0.06), radius * 0.1, Paint()..color = const Color(0xFF182135));
    canvas.drawCircle(Offset(center.dx + radius * 0.3, center.dy - radius * 0.06), radius * 0.1, Paint()..color = const Color(0xFF182135));
    canvas.drawArc(Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.22), width: radius * 0.43, height: radius * 0.28), 0.2, 2.74, false, Paint()..color = const Color(0xFF182135)..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _BlobPreviewPainter oldDelegate) => color != oldDelegate.color || shape != oldDelegate.shape;
}
