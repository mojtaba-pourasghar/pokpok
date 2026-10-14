import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/models/models.dart';

/// کشیدن خط‌ها (نقطه‌ها نسبی‌اند، پس نقاشی در هر اندازه درست کشیده می‌شود).
void paintStrokes(Canvas canvas, Size size, Iterable<Stroke> strokes, Color background) {
  final u = size.shortestSide;
  for (final s in strokes) {
    final paint = Paint()
      ..color = s.eraser ? background : s.color
      ..strokeWidth = s.width * u
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
    final pts = [for (final p in s.points) Offset(p.dx * size.width, p.dy * size.height)];
    if (pts.isEmpty) continue;
    if (pts.length == 1) {
      canvas.drawCircle(pts.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
      continue;
    }
    // خط نرم: منحنی از میان نقطه‌های میانی
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length - 1; i++) {
      final mid = (pts[i] + pts[i + 1]) / 2;
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);
    canvas.drawPath(path, paint);
  }
}

class StrokesPainter extends CustomPainter {
  StrokesPainter(this.strokes, this.background, {this.revision = 0});

  final List<Stroke> strokes;
  final Color background;

  /// با هر تغییر فهرست یک واحد بالا می‌رود (فهرست درجا تغییر می‌کند).
  final int revision;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    paintStrokes(canvas, size, strokes, background);
  }

  @override
  bool shouldRepaint(StrokesPainter old) => old.revision != revision || old.background != background || old.strokes != strokes;
}

/// فقط خطی که همین حالا کشیده می‌شود؛ تا هر حرکت انگشت کل نقاشی را دوباره نکشد.
class LiveStrokePainter extends CustomPainter {
  LiveStrokePainter(this.stroke, this.background) : super(repaint: stroke);

  final ValueNotifier<Stroke?> stroke;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final s = stroke.value;
    if (s != null) paintStrokes(canvas, size, [s], background);
  }

  @override
  bool shouldRepaint(LiveStrokePainter old) => false;
}

/// خروجی PNG نقاشی در پوشه‌ی برنامه (فقط از بخش والدین صدا زده می‌شود).
Future<File> exportArtworkPng(Artwork a, {double width = 1200, double height = 900}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final size = Size(width, height);
  canvas.drawRect(Offset.zero & size, Paint()..color = Color(a.background));
  paintStrokes(canvas, size, a.strokes, Color(a.background));
  final img = await rec.endRecording().toImage(width.toInt(), height.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = await getApplicationDocumentsDirectory();
  final out = File('${dir.path}/popo_exports/popo_${a.id}.png');
  await out.parent.create(recursive: true);
  await out.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  return out;
}
