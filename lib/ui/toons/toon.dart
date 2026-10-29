import 'dart:math' as math;

import 'package:flutter/material.dart';

/// کارتون‌های زنده: هر چیز و هر شخصیت بازی با کد کشیده می‌شود و همیشه جان دارد — نفس می‌کشد،
/// پلک می‌زند، تاب می‌خورد — و وقتی کاری می‌کند (چرخ می‌چرخد، آب می‌ریزد، چراغ روشن می‌شود)
/// حرکت خودش را دارد. هیچ تصویر ثابتی لازم نیست.
///
/// همه‌ی نقاشی‌ها روی یک بوم ۱۰۰×۱۰۰ تعریف می‌شوند؛ زمین (جای سایه) در y≈۹۴ است.

enum ToonMood {
  /// زندگی آرام: نفس، پلک، تاب.
  idle,

  /// مشغول کار خودش (ماشین می‌راند، چکش می‌زند، لامپ روشن است).
  act,

  /// خوشحال: می‌پرد و لبخند بزرگ می‌زند.
  happy,

  /// ناراحت/اشتباه: سر پایین، دهان کج.
  sad,
}

/// لحظه‌ای از زندگی یک کارتون.
class ToonPose {
  const ToonPose(this.t, {this.mood = ToonMood.idle, this.seed = 0});

  /// ثانیه از آغاز.
  final double t;
  final ToonMood mood;

  /// برای این‌که دو کارتون یکسان با هم پلک نزنند.
  final int seed;

  bool get act => mood == ToonMood.act;
  bool get happy => mood == ToonMood.happy;
  bool get sad => mood == ToonMood.sad;

  /// موج سینوسی با [hz] بار در ثانیه، بین -۱ و ۱.
  double wave(double hz, [double phase = 0]) => math.sin((t * hz + phase + seed * .37) * math.pi * 2);

  /// ۰ تا ۱، تکرارشونده.
  double cycle(double hz, [double phase = 0]) => ((t * hz + phase + seed * .37) % 1 + 1) % 1;

  /// پلک: هر چند ثانیه یک بار، ۰ باز و ۱ بسته.
  double get blink {
    final period = 3.1 + (seed % 5) * .37;
    final k = (t + seed * 1.3) % period;
    if (k > .16) return 0;
    return math.sin(k / .16 * math.pi);
  }

  /// پرش خوشحالی (۰ روی زمین).
  double get hop => happy ? (math.sin(t * math.pi * 3).abs()) : 0;

  /// نفس: ۰ تا ۱.
  double get breath => (math.sin((t + seed) * math.pi * 2 / 2.6) + 1) / 2;
}

typedef ToonPainter = void Function(Pen k, ToonPose p);

Color tint(Color c, [double a = .3]) => Color.lerp(c, Colors.white, a)!;
Color shade(Color c, [double a = .25]) => Color.lerp(c, Colors.black, a)!;

/// قلم نقاشی کارتون‌ها: شکل‌های نرم با سایه‌روشن، خط دور تیره‌تر و برق سفید، به سبک کارتون‌های کودک.
class Pen {
  Pen(this.c);

  final Canvas c;

  static const outline = 1.9;

  Paint _fill(Rect r, Color color) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [tint(color, .22), color, shade(color, .06)],
      stops: const [0, .5, 1],
    ).createShader(r);

  Paint _line(Color color, [double w = outline]) => Paint()
    ..color = shade(color, .55).withValues(alpha: .9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// شکل پر با حجم: رنگ پایه، سایه‌ی نرم لبه‌ی پایین و کنار (مثل نور از بالا-چپ)، برق نرم بالا،
  /// و خط دور تیره‌تر از همان رنگ.
  void blob(Path p, Color color, {bool line = true, bool flat = false, double lineWidth = outline}) {
    final r = p.getBounds();
    if (flat || r.isEmpty) {
      c.drawPath(p, Paint()..color = color);
    } else {
      c.drawPath(p, _fill(r, color));
      final big = r.longestSide;
      c.save();
      c.clipPath(p);
      // سایه‌ی هسته: از مرکز روشن بالا-چپ به لبه‌ی تیره
      final core = Offset(r.left + r.width * .38, r.top + r.height * .32);
      c.drawRect(
        r.inflate(2),
        Paint()
          ..shader = RadialGradient(
            center: Alignment.center,
            radius: .5,
            colors: [Colors.transparent, Colors.transparent, shade(color, .42).withValues(alpha: .75)],
            stops: const [0, .42, 1],
          ).createShader(Rect.fromCircle(center: core, radius: big * .8)),
      );
      // برق نرم
      c.drawOval(
        Rect.fromCenter(center: Offset(r.left + r.width * .34, r.top + r.height * .24), width: r.width * .5, height: r.height * .32),
        Paint()
          ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: .55), Colors.white.withValues(alpha: 0)]).createShader(
            Rect.fromCenter(center: Offset(r.left + r.width * .34, r.top + r.height * .24), width: r.width * .5, height: r.height * .32),
          ),
      );
      c.restore();
    }
    if (line) c.drawPath(p, _line(color, lineWidth));
  }

  void circle(double x, double y, double r, Color color, {bool line = true, bool flat = false}) => blob(
    Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r)),
    color,
    line: line,
    flat: flat,
  );

  void oval(double x, double y, double rx, double ry, Color color, {bool line = true, bool flat = false}) => blob(
    Path()..addOval(Rect.fromCenter(center: Offset(x, y), width: rx * 2, height: ry * 2)),
    color,
    line: line,
    flat: flat,
  );

  void rect(double x, double y, double w, double h, double r, Color color, {bool line = true, bool flat = false}) =>
      blob(Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r))), color, line: line, flat: flat);

  void poly(List<Offset> pts, Color color, {bool line = true, bool flat = false, bool smooth = false}) {
    final p = Path();
    if (smooth) {
      p.moveTo((pts.last.dx + pts.first.dx) / 2, (pts.last.dy + pts.first.dy) / 2);
      for (var i = 0; i < pts.length; i++) {
        final a = pts[i], b = pts[(i + 1) % pts.length];
        p.quadraticBezierTo(a.dx, a.dy, (a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      }
    } else {
      p.addPolygon(pts, true);
    }
    blob(p..close(), color, line: line, flat: flat);
  }

  /// خط ساده (نخ، دسته، پایه).
  void stroke(List<Offset> pts, Color color, double w, {bool smooth = true}) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (smooth && pts.length > 2) {
      for (var i = 1; i < pts.length - 1; i++) {
        final m = Offset.lerp(pts[i], pts[i + 1], .5)!;
        p.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
      }
      p.lineTo(pts.last.dx, pts.last.dy);
    } else {
      for (final o in pts.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
    }
    c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// برق سفید روی سطح.
  void shine(double x, double y, double rx, double ry, {double a = .6, double rot = -.5}) {
    c.save();
    c.translate(x, y);
    c.rotate(rot);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), Paint()..color = Colors.white.withValues(alpha: a));
    c.restore();
  }

  /// سایه‌ی نرم زیر کارتون (کوچک‌تر وقتی بالا پریده).
  void shadow(double x, double w, {double lift = 0, double y = 94}) {
    final k = 1 - lift.clamp(0, 1) * .4;
    c.save();
    c.translate(x, y);
    c.scale(1, .2);
    c.drawCircle(
      Offset.zero,
      w * k / 2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.black.withValues(alpha: .28 * k),
            Colors.black.withValues(alpha: .12 * k),
            Colors.transparent,
          ],
          stops: const [0, .6, 1],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: w * k / 2)),
    );
    c.restore();
  }

  /// هاله‌ی نور.
  void glow(double x, double y, double r, Color color, [double a = .6]) => c.drawCircle(
    Offset(x, y),
    r,
    Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: a),
          color.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: r)),
  );

  /// دو چشم بزرگ براق با پلک و نگاه.
  void eyes(double x, double y, double gap, double r, ToonPose p, {Offset look = Offset.zero, Color iris = const Color(0xFF2A2250)}) {
    final b = p.blink;
    for (final dx in [-gap / 2, gap / 2]) {
      final o = Offset(x + dx, y);
      if (p.happy) {
        // چشم‌های خندان: کمان رو به بالا
        stroke([o + Offset(-r * .8, r * .2), o + Offset(0, -r * .6), o + Offset(r * .8, r * .2)], iris, r * .45);
        continue;
      }
      final open = 1 - b * .92;
      c.drawOval(Rect.fromCenter(center: o, width: r * 2, height: r * 2 * open), Paint()..color = Colors.white);
      c.drawOval(
        Rect.fromCenter(center: o, width: r * 2, height: r * 2 * open),
        Paint()
          ..color = iris.withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .16,
      );
      if (open > .3) {
        final po = o + look * r * .35 + Offset(0, r * .08);
        c.drawOval(Rect.fromCenter(center: po, width: r * 1.2, height: r * 1.25 * open), Paint()..color = iris);
        c.drawCircle(po + Offset(-r * .22, -r * .28 * open), r * .26, Paint()..color = Colors.white);
        c.drawCircle(po + Offset(r * .2, r * .2 * open), r * .1, Paint()..color = Colors.white.withValues(alpha: .8));
      }
      if (p.sad) {
        stroke(
          [o + Offset(-r, -r * 1.1 + (dx < 0 ? r * .5 : -r * .1)), o + Offset(r, -r * 1.1 + (dx < 0 ? -r * .1 : r * .5))],
          iris,
          r * .3,
        );
      }
    }
  }

  /// دهان: لبخند، دهان باز وقتی کار می‌کند یا خوشحال است، و اخم وقتی ناراحت است.
  void mouth(double x, double y, double w, ToonPose p, {Color color = const Color(0xFF7A2E2E)}) {
    if (p.sad) {
      stroke([Offset(x - w / 2, y + w * .2), Offset(x, y - w * .1), Offset(x + w / 2, y + w * .2)], color, w * .14);
    } else if (p.happy || p.act) {
      final h = w * (p.happy ? .55 : .35 + p.wave(2) * .1);
      final path = Path()
        ..moveTo(x - w / 2, y)
        ..quadraticBezierTo(x, y + h * 2, x + w / 2, y)
        ..close();
      c.drawPath(path, Paint()..color = color);
      c.drawOval(Rect.fromCenter(center: Offset(x, y + h * .75), width: w * .45, height: h * .5), Paint()..color = const Color(0xFFFF8A9A));
    } else {
      stroke([Offset(x - w / 2, y), Offset(x, y + w * .3), Offset(x + w / 2, y)], color, w * .13);
    }
  }

  void cheeks(double x, double y, double gap, double r) {
    for (final dx in [-gap / 2, gap / 2]) {
      c.drawOval(Rect.fromCenter(center: Offset(x + dx, y), width: r * 2.2, height: r * 1.4), Paint()..color = const Color(0x66FF6F91));
    }
  }

  /// صورت کامل (چشم، گونه، دهان) برای چیزها.
  void face(double x, double y, double s0, ToonPose p, {Offset look = Offset.zero}) {
    final s = s0 * 1.2;
    eyes(x, y, s * 1.0, s * .28, p, look: look);
    cheeks(x, y + s * .36, s * 1.4, s * .14);
    mouth(x, y + s * .42, s * .44, p);
  }

  /// چرخ با پره‌هایی که می‌چرخند.
  void wheel(double x, double y, double r, double angle, {Color tire = const Color(0xFF3A3A48), Color hub = const Color(0xFFE0E0E8)}) {
    circle(x, y, r, tire);
    circle(x, y, r * .58, hub);
    c.save();
    c.translate(x, y);
    c.rotate(angle);
    final spoke = Paint()
      ..color = shade(hub, .35)
      ..strokeWidth = r * .14
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 4; k++) {
      final a = k * math.pi / 2;
      c.drawLine(Offset.zero, Offset(math.cos(a), math.sin(a)) * r * .5, spoke);
    }
    c.restore();
    c.drawCircle(Offset(x, y), r * .16, Paint()..color = shade(hub, .4));
  }

  void star(double x, double y, double r, Color color, {double rot = 0, bool line = true}) {
    final pts = <Offset>[
      for (var k = 0; k < 10; k++)
        Offset(x, y) +
            Offset(math.cos(rot - math.pi / 2 + k * math.pi / 5), math.sin(rot - math.pi / 2 + k * math.pi / 5)) * (k.isEven ? r : r * .48),
    ];
    poly(pts, color, line: line);
  }

  void heart(double x, double y, double s, Color color) {
    final p = Path()
      ..moveTo(x, y + s * .35)
      ..cubicTo(x - s * .9, y - s * .2, x - s * .4, y - s * .9, x, y - s * .35)
      ..cubicTo(x + s * .4, y - s * .9, x + s * .9, y - s * .2, x, y + s * .35)
      ..close();
    blob(p, color);
  }

  /// بخار پیچان که بالا می‌رود.
  void steam(double x, double y, ToonPose p, {double h = 22, int n = 3, double a = .55}) {
    for (var k = 0; k < n; k++) {
      final ph = p.cycle(.6, k / n);
      final yy = y - ph * h;
      final xx = x + (k - (n - 1) / 2) * 7 + math.sin(ph * math.pi * 2 + k) * 3;
      c.drawCircle(Offset(xx, yy), 3 + ph * 4, Paint()..color = Colors.white.withValues(alpha: a * (1 - ph)));
    }
  }

  /// بدن زنده: سایه، نفس (کمی له و کش)، پرش خوشحالی و خم شدن ناراحتی؛ [draw] در مختصات معمولی می‌کشد.
  void alive(ToonPose p, void Function() draw, {double shadowW = 60, double base = 92, double x = 50, double squash = .03}) {
    shadow(x, shadowW, lift: p.hop, y: base + 2);
    final b = (p.breath - .5) * squash;
    c.save();
    c.translate(x, base - p.hop * 12);
    c.scale(1 + b, 1 - b);
    if (p.sad) c.rotate(.06);
    c.translate(-x, -base);
    draw();
    c.restore();
  }

  /// کار در فضای چرخیده/جابه‌جا شده.
  void at(double x, double y, void Function() draw, {double rot = 0, double sx = 1, double sy = 1}) {
    c.save();
    c.translate(x, y);
    if (rot != 0) c.rotate(rot);
    if (sx != 1 || sy != 1) c.scale(sx, sy);
    draw();
    c.restore();
  }
}

/// بوم کارتون: [painter] را در بوم ۱۰۰×۱۰۰ به اندازه‌ی [Size] می‌کشد.
class ToonCanvas extends CustomPainter {
  ToonCanvas(this.painter, this.pose, {super.repaint});

  final ToonPainter painter;
  final ToonPose Function() pose;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    painter(Pen(canvas), pose());
    canvas.restore();
  }

  @override
  bool shouldRepaint(ToonCanvas old) => old.painter != painter;
}

/// کارتون زنده‌ی [painter] با یک ساعت درونی. با «حرکت کمتر» ثابت می‌ماند.
class ToonView extends StatefulWidget {
  const ToonView(this.painter, {super.key, required this.size, this.mood = ToonMood.idle, this.seed = 0});

  final ToonPainter painter;
  final double size;
  final ToonMood mood;
  final int seed;

  @override
  State<ToonView> createState() => _ToonViewState();
}

class _ToonViewState extends State<ToonView> with SingleTickerProviderStateMixin {
  // یک دور طولانی؛ زمان از مقدار کنترل‌گر و شمار دورها ساخته می‌شود تا حرکت‌ها پیوسته بمانند.
  static const _period = 60.0;
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 60));
  int _laps = 0;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _laps++;
        _c.forward(from: 0);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      size: Size.square(widget.size),
      painter: ToonCanvas(
        widget.painter,
        () => ToonPose((_laps + _c.value) * _period, mood: widget.mood, seed: widget.seed),
        repaint: _c,
      ),
    ),
  );
}
