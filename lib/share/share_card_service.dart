import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/catalog.dart';
import '../l10n/app_strings.dart';

/// Renders the score card entirely with vector shapes into an in-memory PNG,
/// then hands that image to Android's native share sheet.
class ShareCardService {
  Future<bool> shareScore({
    required int score,
    required String skinId,
    required String languageCode,
  }) async {
    try {
      final AppStrings strings = AppStrings(languageCode);
      final Uint8List png = await _renderPng(score: score, skinId: skinId, strings: strings);
      final SkinDefinition skin = CosmeticCatalog.skinById(skinId);
      final ShareResult result = await SharePlus.instance.share(
        ShareParams(
          title: '${strings.text('app_name')} · ${strings.text('share_score')}',
          text: strings.text('share_message', <String, Object>{'value': score}),
          files: <XFile>[
            XFile.fromData(png, mimeType: 'image/png'),
          ],
          fileNameOverrides: const <String>['orbit-hop-score.png'],
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }

  Future<Uint8List> _renderPng({
    required int score,
    required String skinId,
    required AppStrings strings,
  }) async {
    const Size size = Size(1080, 1920);
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder, Offset.zero & size);
    final SkinDefinition skin = CosmeticCatalog.skinById(skinId);
    final Color accent = Color(skin.colorArgb);
    final Rect bounds = Offset.zero & size;

    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF10142D), Color(0xFF090B19), Color(0xFF171024)],
        ).createShader(bounds),
    );
    canvas.drawCircle(
      const Offset(540, 1030),
      690,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[accent.withValues(alpha: 0.18), Colors.transparent],
        ).createShader(const Rect.fromCircle(center: Offset(540, 1030), radius: 690)),
    );
    for (int i = 0; i < 90; i++) {
      final double x = ((i * 197 + 41) % 1060).toDouble() + 10;
      final double y = ((i * 317 + 137) % 1880).toDouble() + 20;
      final double radius = 1.2 + (i % 3) * 0.7;
      canvas.drawCircle(
        Offset(x, y),
        radius,
        Paint()..color = Colors.white.withValues(alpha: 0.28 + (i % 5) * 0.09),
      );
    }

    final Offset planetCenter = const Offset(540, 975);
    canvas.drawCircle(
      planetCenter,
      272,
      Paint()
        ..color = accent.withValues(alpha: 0.17)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 54),
    );
    canvas.drawCircle(
      planetCenter,
      245,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.34, -0.48),
          colors: <Color>[Color.lerp(Colors.white, accent, 0.35)!, accent, const Color(0xFF25254A)],
        ).createShader(const Rect.fromCircle(center: planetCenter, radius: 245)),
    );
    canvas.drawCircle(
      planetCenter,
      310,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      planetCenter,
      346,
      Paint()
        ..color = const Color(0xFF9DEEFF).withValues(alpha: 0.26)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    _drawBlob(canvas, const Offset(540, 625), 55, skin);

    _drawText(
      canvas,
      strings.text('app_name').toUpperCase(),
      540,
      190,
      78,
      const Color(0xFFF7F5FF),
      weight: FontWeight.w900,
      spacing: strings.languageCode == 'en' ? 9 : 0,
    );
    _drawText(
      canvas,
      strings.text('planets_reached'),
      540,
      1400,
      27,
      const Color(0xFFB8C3E7),
      weight: FontWeight.w800,
      spacing: strings.languageCode == 'en' ? 6 : 0,
    );
    _drawText(canvas, score.toString(), 540, 1555, 156, accent, weight: FontWeight.w900);
    _drawText(
      canvas,
      skin.name.toUpperCase(),
      540,
      1695,
      34,
      const Color(0xFFFFD86F),
      weight: FontWeight.w800,
      spacing: 4,
    );
    _drawText(
      canvas,
      strings.text('share_tagline'),
      540,
      1795,
      23,
      const Color(0xFFAAB2D0),
      weight: FontWeight.w600,
      spacing: strings.languageCode == 'en' ? 3 : 0,
    );
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final ByteData? data = await image.toByteData(format: ui.ImageByteFormat.png);
    picture.dispose();
    image.dispose();
    if (data == null) throw StateError('PNG encoding failed');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  void _drawText(
    Canvas canvas,
    String text,
    double centerX,
    double baselineY,
    double fontSize,
    Color color, {
    FontWeight weight = FontWeight.w700,
    double spacing = 0,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontFamily: 'sans-serif',
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: spacing,
          shadows: <Shadow>[Shadow(color: color.withValues(alpha: 0.24), blurRadius: 22)],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 1000);
    painter.paint(canvas, Offset(centerX - painter.width / 2, baselineY - painter.height / 2));
  }

  void _drawBlob(Canvas canvas, Offset center, double radius, SkinDefinition skin) {
    final Color color = Color(skin.colorArgb);
    final Rect bounds = Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 1.92);
    canvas.drawCircle(
      center,
      radius * 1.42,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 26),
    );
    canvas.drawOval(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.5),
          colors: <Color>[Colors.white, color, Color.lerp(color, Colors.black, 0.18)!],
        ).createShader(bounds),
    );
    final Paint eye = Paint()..color = const Color(0xFF182135);
    if (skin.face == 'cyclops') {
      canvas.drawCircle(center, radius * 0.16, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(center.dx + 2, center.dy), radius * 0.075, eye);
    } else {
      canvas.drawCircle(Offset(center.dx - radius * 0.38, center.dy - radius * 0.1), radius * 0.11, eye);
      if (skin.face != 'wink') {
        canvas.drawCircle(Offset(center.dx + radius * 0.38, center.dy - radius * 0.1), radius * 0.11, eye);
      } else {
        canvas.drawLine(
          Offset(center.dx + radius * 0.25, center.dy - radius * 0.1),
          Offset(center.dx + radius * 0.49, center.dy - radius * 0.06),
          Paint()..color = eye.color..strokeWidth = 5,
        );
      }
    }
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, center.dy + radius * 0.19), width: radius * 0.42, height: radius * 0.3),
      0.2,
      mathPi - 0.4,
      false,
      Paint()
        ..color = eye.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }
}

const double mathPi = 3.141592653589793;
