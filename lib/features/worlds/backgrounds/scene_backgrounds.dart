import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../app/theme/tokens.dart';

/// پس‌زمینه‌های مصورِ صحنه‌ها، کشیده با کد.
///
/// پس‌زمینه با همان مختصات نسبی اشیا (۰ تا ۱) کشیده می‌شود، پس کف اتاق، جاده و برکه در هر
/// اندازه و جهت صفحه دقیقاً زیر اشیای صحنه می‌مانند. هر شناسه در JSON صحنه‌ها («background»)
/// به یکی از این‌ها نگاشت می‌شود.
///
/// اگر تصویر ساخته‌شده‌ی `assets/art/backgrounds/<id>.webp` (Cloudflare، tools/art/generate_cf.py)
/// باشد، همان تصویر نشان داده می‌شود و فقط جاده/راه‌ها با کد رویش کشیده می‌شوند.
class SceneBackground extends ConsumerWidget {
  const SceneBackground({super.key, required this.id, this.paths = const {}, this.points = const []});

  final String id;
  final Map<String, List<Offset>> paths;

  /// نقطه‌های ویژه (مثلاً جای جهان‌ها روی نقشه) که پس‌زمینه باید راهی بینشان بکشد.
  final List<Offset> points;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final raster = 'art/backgrounds/$id.webp';
    if (!assets.exists(raster)) {
      return RepaintBoundary(
        child: CustomPaint(
          painter: SceneBackgroundPainter(id, paths: paths, points: points),
          size: Size.infinite,
        ),
      );
    }
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: assets.image(raster)!, fit: BoxFit.cover, gaplessPlayback: true, filterQuality: FilterQuality.medium),
          if (paths.isNotEmpty || points.isNotEmpty)
            CustomPaint(
              painter: SceneBackgroundPainter(id, paths: paths, points: points, overlayOnly: true),
              size: Size.infinite,
            ),
        ],
      ),
    );
  }
}

class SceneBackgroundPainter extends CustomPainter {
  SceneBackgroundPainter(this.id, {this.paths = const {}, this.points = const [], this.overlayOnly = false});

  final String id;
  final Map<String, List<Offset>> paths;
  final List<Offset> points;

  /// روی تصویر رستری فقط چیزهایی کشیده می‌شود که به مختصات بازی گره خورده‌اند (جاده، راه‌های نقشه).
  final bool overlayOnly;

  static const ids = [
    'living',
    'kitchen',
    'bedroom',
    'bathroom',
    'street',
    'park',
    'forest',
    'garden',
    'pond',
    'farm',
    'map',
    'splash',
    'studio',
    'music',
    'workshop',
    'meadow',
    'shop',
    'playroom',
  ];

  @override
  void paint(Canvas c, Size s) {
    if (overlayOnly) {
      if (paths['road'] != null) _road(c, s, paths['road']!);
      if (id == 'map') _mapPaths(c, s);
      return;
    }
    switch (id) {
      case 'living':
        _room(c, s, wall: const Color(0xFFFFE3C7), pattern: _Pattern.dots, floor: const Color(0xFFE2A66A), planks: true, window: true);
      case 'kitchen':
        _room(c, s, wall: const Color(0xFFD7F3F6), pattern: _Pattern.tiles, floor: const Color(0xFFFFD9A8), checker: true, window: true);
      case 'bedroom':
        _room(c, s, wall: const Color(0xFFE8DDFF), pattern: _Pattern.stars, floor: const Color(0xFFB7A3E6), carpet: true, window: true);
      case 'bathroom':
        _room(c, s, wall: const Color(0xFFE6F4FF), pattern: _Pattern.tiles, floor: const Color(0xFFB9E1F5), checker: true);
      case 'playroom':
        _room(c, s, wall: const Color(0xFFFFF0B8), pattern: _Pattern.stripes, floor: const Color(0xFFF2B5C9), carpet: true, window: true);
      case 'shop':
        _room(c, s, wall: const Color(0xFFE5F7D3), pattern: _Pattern.stripes, floor: const Color(0xFFF6E2BF), planks: true, shelves: true);
      case 'studio':
        _room(c, s, wall: const Color(0xFFFFE1EC), pattern: _Pattern.dots, floor: const Color(0xFFE2A66A), planks: true, window: true);
      case 'music':
        _stage(c, s);
      case 'street':
        _outdoor(c, s, ground: const Color(0xFF9ADB5E), skyline: true);
        _road(c, s, paths['road'] ?? const []);
      case 'park':
        _outdoor(c, s, ground: const Color(0xFF9ADB5E), treesBack: true);
        _footpath(c, s);
      case 'forest':
        _outdoor(c, s, ground: const Color(0xFF7FCB52), treesBack: true, dense: true);
      case 'garden':
        _outdoor(c, s, ground: const Color(0xFF9ADB5E), fence: true);
        _soil(c, s);
      case 'pond':
        _outdoor(c, s, ground: const Color(0xFF8ED45A), treesBack: true);
        _pond(c, s);
      case 'farm':
        _outdoor(c, s, ground: const Color(0xFFA8DB61), fence: true, field: true);
      case 'workshop':
        _outdoor(c, s, ground: const Color(0xFFE9C88F), skyline: true);
        _grid(c, s);
      case 'map':
        _map(c, s);
      case 'splash':
      case 'meadow':
      default:
        _outdoor(c, s, ground: const Color(0xFF8ED45A), treesBack: true);
        _flowers(c, s, .7, 1);
    }
  }

  // ── بیرون ────────────────────────────────────────────────────────────────
  void _sky(Canvas c, Size s, double horizon) {
    final r = Offset.zero & Size(s.width, s.height * horizon + 2);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9ED8FF), Color(0xFFE6F6FF)],
        ).createShader(r),
    );
    final u = math.min(s.width, s.height);
    // خورشید
    final sun = Offset(s.width * .86, s.height * horizon * .28);
    c.drawCircle(sun, u * .11, Paint()..color = PColors.yellow.withValues(alpha: .25));
    c.drawCircle(sun, u * .075, Paint()..color = PColors.yellow);
    // ابرها
    for (final (x, y, k) in [(.18, .16, 1.0), (.55, .1, .8), (.4, .3, .6)]) {
      _cloud(c, Offset(s.width * x, s.height * horizon * y * 2), u * .07 * k);
    }
  }

  void _cloud(Canvas c, Offset o, double r) {
    final p = Paint()..color = Colors.white.withValues(alpha: .95);
    c.drawCircle(o, r, p);
    c.drawCircle(o + Offset(r * 1.1, r * .2), r * .8, p);
    c.drawCircle(o + Offset(-r * 1.1, r * .25), r * .7, p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(o.dx - r * 1.7, o.dy, o.dx + r * 1.8, o.dy + r * .9), Radius.circular(r)), p);
  }

  void _hills(Canvas c, Size s, double horizon, Color color, double amp, double phase) {
    final y = s.height * horizon;
    final p = Path()..moveTo(0, y);
    for (var x = 0.0; x <= s.width; x += s.width / 40) {
      p.lineTo(x, y - amp * s.height * (.5 + .5 * math.sin(x / s.width * math.pi * 2.2 + phase)));
    }
    p
      ..lineTo(s.width, s.height)
      ..lineTo(0, s.height)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _outdoor(
    Canvas c,
    Size s, {
    required Color ground,
    bool skyline = false,
    bool treesBack = false,
    bool dense = false,
    bool fence = false,
    bool field = false,
  }) {
    const horizon = .5;
    _sky(c, s, horizon);
    _hills(c, s, horizon, const Color(0xFFB7E58C), .09, 0);
    _hills(c, s, horizon + .03, const Color(0xFF9BD86C), .06, 2);
    if (skyline) _skyline(c, s, horizon + .03);
    if (treesBack) _treeLine(c, s, horizon + .05, dense ? 14 : 8);
    final g = Rect.fromLTRB(0, s.height * (horizon + .04), s.width, s.height);
    c.drawRect(
      g,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PColors.tint(ground, .06), ground, PColors.shade(ground, .06)],
        ).createShader(g),
    );
    // تکه‌های چمن
    final blade = Paint()
      ..color = PColors.shade(ground, .12)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(id.hashCode);
    for (var i = 0; i < 60; i++) {
      final x = rnd.nextDouble() * s.width;
      final y = s.height * (horizon + .07 + rnd.nextDouble() * .9 * (1 - horizon - .07));
      c.drawLine(Offset(x, y), Offset(x - 3, y - 7), blade);
      c.drawLine(Offset(x, y), Offset(x + 3, y - 8), blade);
    }
    if (fence) _fence(c, s, horizon + .1);
    if (field) _field(c, s);
  }

  void _skyline(Canvas c, Size s, double base) {
    final rnd = math.Random(7);
    final colors = [
      const Color(0xFFB9C7FF),
      const Color(0xFFFFC9A8),
      const Color(0xFFA9E3E8),
      const Color(0xFFFFE08A),
      const Color(0xFFD2B8FF),
    ];
    var x = -10.0;
    var i = 0;
    while (x < s.width) {
      final w = s.width * (.08 + rnd.nextDouble() * .07);
      final h = s.height * (.1 + rnd.nextDouble() * .16);
      final r = Rect.fromLTWH(x, s.height * base - h, w, h + 4);
      c.drawRRect(
        RRect.fromRectAndCorners(r, topLeft: const Radius.circular(8), topRight: const Radius.circular(8)),
        Paint()..color = colors[i % colors.length],
      );
      final win = Paint()..color = Colors.white.withValues(alpha: .7);
      for (var wy = r.top + 10; wy < r.bottom - 14; wy += 18) {
        for (var wx = r.left + 8; wx < r.right - 12; wx += 16) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(wx, wy, 8, 10), const Radius.circular(2)), win);
        }
      }
      x += w + 4;
      i++;
    }
  }

  void _treeLine(Canvas c, Size s, double base, int n) {
    final rnd = math.Random(n);
    for (var i = 0; i < n; i++) {
      final x = s.width * (i + .5) / n + (rnd.nextDouble() - .5) * 20;
      final h = s.height * (.08 + rnd.nextDouble() * .06);
      final y = s.height * base;
      c.drawRect(Rect.fromLTWH(x - 4, y - h * .4, 8, h * .45), Paint()..color = const Color(0xFF9A6A43));
      final col = i.isEven ? const Color(0xFF5DBB46) : const Color(0xFF4FA83E);
      c.drawCircle(Offset(x, y - h * .6), h * .42, Paint()..color = col);
      c.drawCircle(Offset(x - h * .25, y - h * .45), h * .3, Paint()..color = col);
      c.drawCircle(Offset(x + h * .25, y - h * .45), h * .3, Paint()..color = col);
    }
  }

  void _fence(Canvas c, Size s, double y0) {
    final y = s.height * y0;
    final wood = Paint()..color = const Color(0xFFFFF4E3);
    final edge = Paint()
      ..color = const Color(0xFFD9B98F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rail = RRect.fromRectAndRadius(Rect.fromLTWH(0, y - 28, s.width, 8), const Radius.circular(4));
    c.drawRRect(rail, wood);
    c.drawRRect(rail, edge);
    for (var x = 8.0; x < s.width; x += 34) {
      final post = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y - 44, 16, 50),
        topLeft: const Radius.circular(8),
        topRight: const Radius.circular(8),
      );
      c.drawRRect(post, wood);
      c.drawRRect(post, edge);
    }
  }

  void _field(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFE8C66A).withValues(alpha: .55);
    for (var i = 0; i < 4; i++) {
      final y = s.height * (.66 + i * .07);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .55, y, s.width * .42, s.height * .025), const Radius.circular(8)), p);
    }
  }

  void _road(Canvas c, Size s, List<Offset> pts) {
    if (pts.length < 2) return;
    final u = math.min(s.width, s.height);
    final path = Path()..moveTo(pts.first.dx * s.width, pts.first.dy * s.height);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx * s.width, p.dy * s.height);
    }
    final roadW = u * .16;
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFE6E9F2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadW + 14
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF5B6280)
        ..style = PaintingStyle.stroke
        ..strokeWidth = roadW
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    // خط‌چین وسط
    final dash = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 30) {
        final a = m.getTangentForOffset(d)!.position;
        final b = m.getTangentForOffset(math.min(d + 14, m.length))!.position;
        c.drawLine(a, b, dash);
      }
    }
  }

  void _footpath(Canvas c, Size s) {
    final p = Path()
      ..moveTo(s.width * .45, s.height)
      ..quadraticBezierTo(s.width * .55, s.height * .75, s.width * .5, s.height * .58)
      ..quadraticBezierTo(s.width * .45, s.height * .54, s.width * .52, s.height * .54);
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFF2DDB3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(s.width, s.height) * .1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _soil(Canvas c, Size s) {
    for (var i = 0; i < 2; i++) {
      final r = Rect.fromLTWH(s.width * .08, s.height * (.7 + i * .14), s.width * .84, s.height * .06);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(20)), Paint()..color = const Color(0xFFA9714A));
      c.drawRRect(RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(16)), Paint()..color = const Color(0xFF8E5C3A));
    }
  }

  void _pond(Canvas c, Size s) {
    final r = Rect.fromCenter(center: Offset(s.width * .5, s.height * .76), width: s.width * .82, height: s.height * .3);
    c.drawOval(r.inflate(8), Paint()..color = const Color(0xFFD9C79E));
    c.drawOval(r, Paint()..shader = const RadialGradient(colors: [Color(0xFF8FDBFA), Color(0xFF4CB7E6)]).createShader(r));
    final ripple = Paint()
      ..color = Colors.white.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final (x, y, w) in [(.35, .72, .12), (.62, .8, .16), (.5, .7, .08)]) {
      c.drawArc(
        Rect.fromCenter(center: Offset(s.width * x, s.height * y), width: s.width * w, height: s.height * .025),
        math.pi,
        math.pi,
        false,
        ripple,
      );
    }
  }

  void _flowers(Canvas c, Size s, double y0, double y1) {
    final rnd = math.Random(3);
    final colors = [PColors.pink, PColors.yellow, PColors.purple, Colors.white];
    for (var i = 0; i < 26; i++) {
      final o = Offset(rnd.nextDouble() * s.width, s.height * (y0 + rnd.nextDouble() * (y1 - y0)));
      final col = colors[i % colors.length];
      for (var k = 0; k < 5; k++) {
        final a = k * math.pi * 2 / 5;
        c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * 5, 4, Paint()..color = col);
      }
      c.drawCircle(o, 3, Paint()..color = PColors.orange);
    }
  }

  void _grid(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .35)
      ..strokeWidth = 1.5;
    final top = s.height * .56;
    for (var x = 0.0; x < s.width; x += 40) {
      c.drawLine(Offset(x, top), Offset(x, s.height), p);
    }
    for (var y = top; y < s.height; y += 40) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  // ── داخل اتاق ─────────────────────────────────────────────────────────────
  void _room(
    Canvas c,
    Size s, {
    required Color wall,
    required _Pattern pattern,
    required Color floor,
    bool planks = false,
    bool checker = false,
    bool carpet = false,
    bool window = false,
    bool shelves = false,
  }) {
    const floorY = .6;
    final wallR = Rect.fromLTWH(0, 0, s.width, s.height * floorY);
    c.drawRect(
      wallR,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [PColors.tint(wall, .03), wall],
        ).createShader(wallR),
    );
    _wallPattern(c, wallR, wall, pattern);
    if (window) _window(c, s);
    if (shelves) _shelves(c, s);
    final fr = Rect.fromLTWH(0, s.height * floorY, s.width, s.height * (1 - floorY));
    c.drawRect(fr, Paint()..color = floor);
    if (planks) {
      final line = Paint()
        ..color = PColors.shade(floor, .08)
        ..strokeWidth = 2;
      for (var y = fr.top + 26; y < fr.bottom; y += 30) {
        c.drawLine(Offset(0, y), Offset(s.width, y), line);
      }
    }
    if (checker) {
      final t = Paint()..color = PColors.shade(floor, .06);
      const n = 40.0;
      for (var y = fr.top; y < fr.bottom; y += n) {
        for (var x = 0.0; x < s.width; x += n) {
          if (((x / n).round() + ((y - fr.top) / n).round()).isEven) c.drawRect(Rect.fromLTWH(x, y, n, n), t);
        }
      }
    }
    if (carpet) {
      final r = Rect.fromCenter(center: Offset(s.width * .5, s.height * .82), width: s.width * .8, height: s.height * .22);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(40)), Paint()..color = PColors.tint(floor, .08));
    }
    // قرنیز
    c.drawRect(Rect.fromLTWH(0, s.height * floorY - 10, s.width, 12), Paint()..color = Colors.white);
    c.drawRect(Rect.fromLTWH(0, s.height * floorY + 2, s.width, 3), Paint()..color = PColors.shade(floor, .12));
  }

  void _wallPattern(Canvas c, Rect r, Color wall, _Pattern p) {
    final ink = Paint()..color = PColors.shade(wall, .05);
    switch (p) {
      case _Pattern.dots:
        for (var y = r.top + 20; y < r.bottom - 20; y += 36) {
          for (var x = r.left + ((y ~/ 36).isEven ? 14 : 32); x < r.right; x += 36) {
            c.drawCircle(Offset(x, y), 4, ink);
          }
        }
      case _Pattern.stripes:
        for (var x = 0.0; x < r.width; x += 48) {
          c.drawRect(Rect.fromLTWH(x, r.top, 22, r.height), ink);
        }
      case _Pattern.tiles:
        final line = Paint()
          ..color = Colors.white.withValues(alpha: .8)
          ..strokeWidth = 2;
        for (var y = r.top + r.height * .45; y < r.bottom; y += 28) {
          c.drawLine(Offset(0, y), Offset(r.right, y), line);
        }
        for (var x = 0.0; x < r.right; x += 28) {
          c.drawLine(Offset(x, r.top + r.height * .45), Offset(x, r.bottom), line);
        }
      case _Pattern.stars:
        final star = Paint()..color = Colors.white.withValues(alpha: .8);
        final rnd = math.Random(5);
        for (var i = 0; i < 24; i++) {
          final o = Offset(rnd.nextDouble() * r.width, rnd.nextDouble() * r.height * .9);
          _star(c, o, 5 + rnd.nextDouble() * 4, star);
        }
    }
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * .45;
      final pt = o + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), p);
  }

  void _window(Canvas c, Size s) {
    final u = math.min(s.width, s.height);
    final r = Rect.fromCenter(center: Offset(s.width * .5, s.height * .22), width: u * .36, height: u * .3);
    final frame = RRect.fromRectAndRadius(r.inflate(8), const Radius.circular(18));
    c.drawRRect(frame, Paint()..color = Colors.white);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(12)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9ED8FF), Color(0xFFDDF4FF)],
        ).createShader(r),
    );
    _cloud(c, r.center + Offset(-r.width * .15, -r.height * .1), r.width * .1);
    c.drawRect(Rect.fromLTWH(r.left, r.bottom - r.height * .25, r.width, r.height * .25), Paint()..color = const Color(0xFF9ADB5E));
    final bar = Paint()
      ..color = Colors.white
      ..strokeWidth = 6;
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), bar);
    c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), bar);
  }

  void _shelves(Canvas c, Size s) {
    final colors = [PColors.danger, PColors.yellow, PColors.green, PColors.orange, PColors.purple, PColors.turquoise];
    for (var row = 0; row < 3; row++) {
      final y = s.height * (.14 + row * .14);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(s.width * .05, y + 26, s.width * .9, 8), const Radius.circular(4)),
        Paint()..color = const Color(0xFFD99A5B),
      );
      for (var i = 0; i < 12; i++) {
        final x = s.width * (.07 + i * .074);
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, y, s.width * .05, 26), const Radius.circular(6)),
          Paint()..color = colors[(i + row) % colors.length].withValues(alpha: .85),
        );
      }
    }
  }

  void _stage(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4FD8), Color(0xFFB394FF)],
        ).createShader(r),
    );
    // پرده‌ها
    final curtain = Paint()..color = const Color(0xFFE2558A);
    for (final left in [true, false]) {
      final p = Path();
      final x0 = left ? 0.0 : s.width;
      final dir = left ? 1.0 : -1.0;
      p.moveTo(x0, 0);
      p.lineTo(x0 + dir * s.width * .16, 0);
      p.quadraticBezierTo(x0 + dir * s.width * .06, s.height * .4, x0 + dir * s.width * .12, s.height * .7);
      p.lineTo(x0, s.height * .7);
      c.drawPath(p..close(), curtain);
    }
    // نورها
    for (final (x, col) in [(.3, PColors.yellow), (.5, PColors.turquoise), (.7, PColors.pink)]) {
      final p = Path()
        ..moveTo(s.width * x - 10, 0)
        ..lineTo(s.width * x + 10, 0)
        ..lineTo(s.width * (x + .12), s.height * .7)
        ..lineTo(s.width * (x - .12), s.height * .7)
        ..close();
      c.drawPath(p, Paint()..color = col.withValues(alpha: .16));
    }
    final floor = Rect.fromLTWH(0, s.height * .62, s.width, s.height * .38);
    c.drawRect(floor, Paint()..color = const Color(0xFF8E62D9));
    c.drawRect(Rect.fromLTWH(0, s.height * .62, s.width, 8), Paint()..color = const Color(0xFFFFD34F));
    final rnd = math.Random(2);
    for (var i = 0; i < 18; i++) {
      final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .5);
      _star(c, o, 4 + rnd.nextDouble() * 4, Paint()..color = Colors.white.withValues(alpha: .5));
    }
  }

  // ── نقشه ──────────────────────────────────────────────────────────────────
  void _map(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = const Color(0xFF7FD3F7));
    // موج‌ها
    final wave = Paint()
      ..color = Colors.white.withValues(alpha: .45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(11);
    for (var i = 0; i < 16; i++) {
      final o = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height);
      c.drawArc(Rect.fromCenter(center: o, width: 26, height: 10), math.pi, math.pi, false, wave);
    }
    // جزیره
    final island = RRect.fromRectAndRadius(
      Rect.fromLTRB(s.width * .04, s.height * .05, s.width * .96, s.height * .97),
      Radius.circular(math.min(s.width, s.height) * .2),
    );
    c.drawRRect(island.inflate(10), Paint()..color = const Color(0xFFF7E3B0));
    c.drawRRect(
      island,
      Paint()..shader = const RadialGradient(colors: [Color(0xFFB8E883), Color(0xFF8ED45A)], radius: .9).createShader(island.outerRect),
    );
    // رودخانه
    final river = Path()
      ..moveTo(s.width * .96, s.height * .44)
      ..cubicTo(s.width * .7, s.height * .5, s.width * .55, s.height * .36, s.width * .3, s.height * .5)
      ..cubicTo(s.width * .18, s.height * .56, s.width * .1, s.height * .52, s.width * .04, s.height * .58);
    c.drawPath(
      river,
      Paint()
        ..color = const Color(0xFF6CC9F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.min(s.width, s.height) * .05
        ..strokeCap = StrokeCap.round,
    );
    _mapPaths(c, s);
    // درخت‌ها
    _treesScatter(c, s, rnd);
  }

  void _mapPaths(Canvas c, Size s) {
    // راه‌های بین جهان‌ها
    if (points.length > 1) {
      final road = Paint()
        ..color = const Color(0xFFFFF4E3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;
      final dots = Paint()
        ..color = const Color(0xFFE6CFA0)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i + 1 < points.length; i++) {
        final a = Offset(points[i].dx * s.width, points[i].dy * s.height);
        final b = Offset(points[i + 1].dx * s.width, points[i + 1].dy * s.height);
        final mid = Offset((a.dx + b.dx) / 2 + (b.dy - a.dy) * .2, (a.dy + b.dy) / 2 - (b.dx - a.dx) * .2);
        final p = Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
        c.drawPath(p, road);
        for (final m in p.computeMetrics()) {
          for (var d = 10.0; d < m.length; d += 22) {
            c.drawCircle(m.getTangentForOffset(d)!.position, 2, dots);
          }
        }
      }
    }
  }

  void _treesScatter(Canvas c, Size s, math.Random rnd) {
    final u = math.min(s.width, s.height);
    for (var i = 0; i < 22; i++) {
      final o = Offset(s.width * (.08 + rnd.nextDouble() * .84), s.height * (.08 + rnd.nextDouble() * .86));
      if (points.any((p) => (Offset(p.dx * s.width, p.dy * s.height) - o).distance < u * .2)) continue;
      final r = u * (.025 + rnd.nextDouble() * .015);
      c.drawCircle(o + Offset(0, r * .9), r * .9, Paint()..color = Colors.black.withValues(alpha: .06));
      c.drawRect(Rect.fromCenter(center: o + Offset(0, r * .8), width: r * .35, height: r), Paint()..color = const Color(0xFF9A6A43));
      c.drawCircle(o, r, Paint()..color = i.isEven ? const Color(0xFF5DBB46) : const Color(0xFF4FA83E));
      c.drawCircle(o - Offset(r * .3, r * .3), r * .3, Paint()..color = Colors.white.withValues(alpha: .25));
    }
  }

  @override
  bool shouldRepaint(SceneBackgroundPainter old) =>
      old.id != id || old.paths != paths || old.points != points || old.overlayOnly != overlayOnly;
}

enum _Pattern { dots, stripes, tiles, stars }
