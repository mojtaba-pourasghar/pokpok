import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'clay.dart';

/// نوع ذره‌ها.
enum Fx {
  /// ستاره‌های طلایی که پخش می‌شوند (موفقیت).
  sparkle,

  /// کاغذرنگی که می‌ریزد (جشن).
  confetti,

  /// خرده‌ی نان و غذا (گاز زدن).
  crumbs,

  /// قطره‌های مایع (آب، آب‌میوه، رنگ) با جاذبه.
  drops,

  /// بخار که بالا می‌رود و بزرگ و کم‌رنگ می‌شود.
  steam,

  /// دود خاکستری اگزوز.
  smoke,

  /// نت‌های موسیقی که بالا می‌روند.
  notes,

  /// قلب (محبت، دوست خوشحال).
  hearts,

  /// حباب‌های صابون.
  bubbles,

  /// گرد و غبار و تراشه (چکش، اره).
  dust,

  /// جرقه‌ی کوتاه (فلز، برق).
  sparks,
}

class _Particle {
  _Particle(this.kind, this.p, this.v, this.life, this.size, this.color, this.spin, this.glyph);

  final Fx kind;
  Offset p;
  Offset v;
  double age = 0;
  final double life;
  final double size;
  final Color color;
  double angle = 0;
  final double spin;
  final int glyph;

  double get t => (age / life).clamp(0, 1);
}

class _Flight {
  _Flight(this.art, this.from, this.to, this.size, this.duration, this.arc, this.onLand, this.spin, this.endScale);

  final String art;
  final Offset from, to;
  final double size;
  final double duration;
  final double arc;
  final VoidCallback? onLand;
  final double spin;
  final double endScale;
  double age = 0;

  double get t => (age / duration).clamp(0, 1);

  Offset get pos {
    final e = Curves.easeInOutCubic.transform(t);
    final base = Offset.lerp(from, to, e)!;
    return base - Offset(0, math.sin(t * math.pi) * arc);
  }
}

/// لایه‌ی جلوه‌ها: ذره‌ها و چیزهایی که پرواز می‌کنند، روی همه‌ی صفحه‌ی بازی.
/// هر ابزارک زیرش با [FxScope.of] به آن دسترسی دارد و مختصات سراسری (global) می‌دهد.
class FxLayer extends StatefulWidget {
  const FxLayer({super.key, required this.child, this.reduced = false});

  final Widget child;

  /// حرکت کمتر (تنظیم دسترسی‌پذیری): ذره‌ها کم‌تعدادتر و کوتاه‌تر.
  final bool reduced;

  @override
  State<FxLayer> createState() => FxLayerState();
}

class FxLayerState extends State<FxLayer> with SingleTickerProviderStateMixin {
  static const _max = 260;
  final _rnd = math.Random();
  final List<_Particle> _parts = [];
  final List<_Flight> _flights = [];
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  final _key = GlobalKey();
  final _repaint = ValueNotifier<int>(0);

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  Offset _local(Offset global) {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? global : box.globalToLocal(global);
  }

  void _ensure() {
    if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = now;
    for (final p in _parts) {
      p.age += dt;
      final g = switch (p.kind) {
        Fx.steam || Fx.smoke || Fx.notes || Fx.hearts || Fx.bubbles => const Offset(0, -40),
        Fx.confetti => const Offset(0, 260),
        Fx.sparkle => const Offset(0, 120),
        _ => const Offset(0, 900),
      };
      final drag = switch (p.kind) {
        Fx.confetti || Fx.steam || Fx.smoke || Fx.bubbles => 1.6,
        Fx.notes || Fx.hearts => 1.2,
        _ => .4,
      };
      p.v = (p.v + g * dt) * (1 - drag * dt);
      if (p.kind == Fx.confetti || p.kind == Fx.bubbles) p.v += Offset(math.sin(p.age * 6 + p.glyph) * 30 * dt, 0);
      p.p += p.v * dt;
      p.angle += p.spin * dt;
    }
    _parts.removeWhere((p) => p.age >= p.life);
    final landed = <_Flight>[];
    for (final f in _flights) {
      f.age += dt;
      if (f.age >= f.duration) landed.add(f);
    }
    _flights.removeWhere(landed.contains);
    for (final f in landed) {
      f.onLand?.call();
    }
    if (_parts.isEmpty && _flights.isEmpty) _ticker.stop();
    if (landed.isNotEmpty || _flights.isNotEmpty) {
      setState(() {});
    } else {
      _repaint.value++;
    }
  }

  /// ذره‌ها در نقطه‌ی [global].
  void burst(Offset global, Fx kind, {int? count, Color? color, double spread = 1}) {
    final at = _local(global);
    var n = count ?? _defaultCount(kind);
    if (widget.reduced) n = (n / 3).ceil();
    for (var i = 0; i < n && _parts.length < _max; i++) {
      _parts.add(_make(kind, at, color, spread));
    }
    _ensure();
  }

  int _defaultCount(Fx k) => switch (k) {
    Fx.confetti => 46,
    Fx.sparkle => 14,
    Fx.crumbs => 12,
    Fx.drops => 14,
    Fx.steam => 6,
    Fx.smoke => 7,
    Fx.notes => 5,
    Fx.hearts => 6,
    Fx.bubbles => 10,
    Fx.dust => 12,
    Fx.sparks => 12,
  };

  _Particle _make(Fx k, Offset at, Color? color, double spread) {
    double r(double a, double b) => a + _rnd.nextDouble() * (b - a);
    final a = r(0, math.pi * 2);
    Offset dir(double speed) => Offset(math.cos(a), math.sin(a)) * speed * spread;
    switch (k) {
      case Fx.sparkle:
        return _Particle(k, at, dir(r(160, 340)), r(.5, .9), r(7, 13), color ?? G.yellow, r(-6, 6), 0);
      case Fx.confetti:
        final c = [G.pink, G.yellow, G.blue, G.green, G.orange, G.purple][_rnd.nextInt(6)];
        return _Particle(
          k,
          at + Offset(r(-30, 30), 0),
          Offset(r(-260, 260), r(-620, -280)) * spread,
          r(1.6, 2.6),
          r(7, 12),
          color ?? c,
          r(-9, 9),
          0,
        );
      case Fx.crumbs:
        return _Particle(
          k,
          at,
          Offset(r(-160, 160), r(-260, -60)) * spread,
          r(.7, 1.1),
          r(3, 7),
          color ?? const Color(0xFFD9A35B),
          r(-8, 8),
          0,
        );
      case Fx.drops:
        return _Particle(k, at, Offset(r(-170, 170), r(-320, -90)) * spread, r(.6, 1.0), r(4, 8), color ?? const Color(0xFF4FC3F7), 0, 0);
      case Fx.steam:
        return _Particle(
          k,
          at + Offset(r(-24, 24), 0),
          Offset(r(-14, 14), r(-70, -40)) * spread,
          r(1.4, 2.2),
          r(12, 20),
          color ?? Colors.white,
          0,
          0,
        );
      case Fx.smoke:
        return _Particle(
          k,
          at + Offset(r(-10, 10), 0),
          Offset(r(-90, -40), r(-60, -20)) * spread,
          r(1.0, 1.6),
          r(10, 18),
          color ?? const Color(0xFFB0BEC5),
          0,
          0,
        );
      case Fx.notes:
        final c = [G.purple, G.pink, G.blue, G.orange][_rnd.nextInt(4)];
        return _Particle(
          k,
          at + Offset(r(-30, 30), 0),
          Offset(r(-60, 60), r(-140, -80)) * spread,
          r(1.2, 1.8),
          r(22, 32),
          color ?? c,
          r(-1, 1),
          _rnd.nextInt(2),
        );
      case Fx.hearts:
        return _Particle(
          k,
          at + Offset(r(-20, 20), 0),
          Offset(r(-50, 50), r(-150, -90)) * spread,
          r(1.0, 1.6),
          r(12, 20),
          color ?? G.pink,
          r(-1, 1),
          0,
        );
      case Fx.bubbles:
        return _Particle(
          k,
          at + Offset(r(-30, 30), r(-10, 10)),
          Offset(r(-60, 60), r(-140, -60)) * spread,
          r(1.4, 2.4),
          r(8, 18),
          color ?? const Color(0xFFB3E5FC),
          0,
          _rnd.nextInt(10),
        );
      case Fx.dust:
        return _Particle(
          k,
          at,
          Offset(r(-200, 200), r(-220, -40)) * spread,
          r(.5, .9),
          r(3, 6),
          color ?? const Color(0xFFBCAAA4),
          r(-6, 6),
          0,
        );
      case Fx.sparks:
        return _Particle(k, at, dir(r(220, 420)), r(.25, .45), r(2, 4), color ?? const Color(0xFFFFE082), 0, 0);
    }
  }

  /// [art] از [from] تا [to] (سراسری) روی یک کمان پرواز می‌کند؛ بعد [onLand].
  void fly(
    String art,
    Offset from,
    Offset to, {
    double size = 90,
    double ms = 650,
    double arc = 120,
    double spin = 0,
    double endScale = .7,
    VoidCallback? onLand,
  }) {
    _flights.add(_Flight(art, _local(from), _local(to), size, (widget.reduced ? ms * .6 : ms) / 1000, arc, onLand, spin, endScale));
    _ensure();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => FxScope(
    state: this,
    child: Stack(
      key: _key,
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: RepaintBoundary(
            child: CustomPaint(painter: _FxPainter(_parts, _repaint), size: Size.infinite),
          ),
        ),
        for (final f in _flights)
          Positioned(
            left: f.pos.dx - f.size / 2,
            top: f.pos.dy - f.size / 2,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: f.spin * f.t * math.pi * 2,
                child: Transform.scale(
                  scale: 1 + (f.endScale - 1) * f.t,
                  child: GameArt(f.art, size: f.size),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class FxScope extends InheritedWidget {
  const FxScope({super.key, required this.state, required super.child});

  final FxLayerState state;

  /// لایه‌ی جلوه‌ها؛ اگر نباشد (مثلاً در آزمون یک ابزارک تنها) هیچ کاری نمی‌کند.
  static FxLayerState? of(BuildContext context) => context.getInheritedWidgetOfExactType<FxScope>()?.state;

  @override
  bool updateShouldNotify(FxScope oldWidget) => false;
}

extension FxContext on BuildContext {
  /// مرکز این ابزارک روی صفحه.
  Offset get globalCenter {
    final box = findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  void fx(Fx kind, {Offset? at, int? count, Color? color, double spread = 1}) =>
      FxScope.of(this)?.burst(at ?? globalCenter, kind, count: count, color: color, spread: spread);
}

class _FxPainter extends CustomPainter {
  _FxPainter(this.parts, Listenable repaint) : super(repaint: repaint);

  final List<_Particle> parts;
  static final _glyphs = <String, TextPainter>{};

  TextPainter _glyph(String s, double size, Color c) {
    final key = '$s${size.round()}${c.toARGB32()}';
    return _glyphs.putIfAbsent(key, () {
      if (_glyphs.length > 200) _glyphs.clear();
      return TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(fontSize: size, color: c, fontWeight: FontWeight.w900, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in parts) {
      final t = p.t;
      final fadeOut = t > .7 ? 1 - (t - .7) / .3 : 1.0;
      switch (p.kind) {
        case Fx.sparkle:
          paint.color = p.color.withValues(alpha: fadeOut);
          _star(canvas, p.p, p.size * (1 - t * .4), p.angle, paint);
        case Fx.confetti:
          paint.color = p.color.withValues(alpha: fadeOut);
          canvas.save();
          canvas.translate(p.p.dx, p.p.dy);
          canvas.rotate(p.angle);
          canvas.scale(1, math.cos(p.angle * 2).abs() * .8 + .2);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .6), const Radius.circular(2)),
            paint,
          );
          canvas.restore();
        case Fx.crumbs || Fx.dust:
          paint.color = p.color.withValues(alpha: fadeOut);
          canvas.save();
          canvas.translate(p.p.dx, p.p.dy);
          canvas.rotate(p.angle);
          canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * .8), paint);
          canvas.restore();
        case Fx.drops:
          paint.color = p.color.withValues(alpha: .9 * fadeOut);
          final stretch = (p.v.distance / 400).clamp(1.0, 2.2);
          canvas.save();
          canvas.translate(p.p.dx, p.p.dy);
          canvas.rotate(math.atan2(p.v.dy, p.v.dx) - math.pi / 2);
          canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * stretch), paint);
          canvas.restore();
        case Fx.steam || Fx.smoke:
          final r = p.size * (1 + t * 1.8);
          paint.shader = RadialGradient(
            colors: [
              p.color.withValues(alpha: (p.kind == Fx.steam ? .55 : .6) * (1 - t)),
              p.color.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: p.p, radius: r));
          canvas.drawCircle(p.p, r, paint);
          paint.shader = null;
        case Fx.notes:
          final g = _glyph(p.glyph == 0 ? '♪' : '♫', p.size, p.color.withValues(alpha: fadeOut));
          canvas.save();
          canvas.translate(p.p.dx, p.p.dy);
          canvas.rotate(math.sin(p.age * 4) * .3);
          g.paint(canvas, Offset(-g.width / 2, -g.height / 2));
          canvas.restore();
        case Fx.hearts:
          paint.color = p.color.withValues(alpha: fadeOut);
          _heart(canvas, p.p, p.size * (.6 + t * .5), paint);
        case Fx.bubbles:
          final r = p.size * (.7 + t * .5);
          paint
            ..color = p.color.withValues(alpha: .35 * fadeOut)
            ..style = PaintingStyle.fill;
          canvas.drawCircle(p.p, r, paint);
          paint
            ..color = Colors.white.withValues(alpha: .9 * fadeOut)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6;
          canvas.drawCircle(p.p, r, paint);
          paint.style = PaintingStyle.fill;
          canvas.drawCircle(p.p + Offset(-r * .35, -r * .35), r * .22, paint..color = Colors.white.withValues(alpha: .8 * fadeOut));
        case Fx.sparks:
          paint
            ..color = p.color.withValues(alpha: fadeOut)
            ..strokeWidth = p.size
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(p.p, p.p - p.v * .04, paint);
      }
    }
  }

  void _star(Canvas c, Offset o, double r, double rot, Paint p) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? r : r * .45;
      final a = k / 10 * math.pi * 2 - math.pi / 2 + rot;
      final pt = o + Offset(math.cos(a), math.sin(a)) * rr;
      k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), p);
  }

  void _heart(Canvas c, Offset o, double s, Paint p) {
    final path = Path()
      ..moveTo(o.dx, o.dy + s * .35)
      ..cubicTo(o.dx - s, o.dy - s * .3, o.dx - s * .4, o.dy - s, o.dx, o.dy - s * .45)
      ..cubicTo(o.dx + s * .4, o.dy - s, o.dx + s, o.dy - s * .3, o.dx, o.dy + s * .35);
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_FxPainter old) => true;
}

/// حرکت آرام همیشگی: بالا و پایین رفتن و کمی چرخش، با فاز تصادفی تا همه با هم تکان نخورند.
class Idle extends StatefulWidget {
  const Idle({super.key, required this.child, this.amount = 1, this.seed = 0, this.enabled = true});

  final Widget child;
  final double amount;
  final int seed;
  final bool enabled;

  @override
  State<Idle> createState() => _IdleState();
}

class _IdleState extends State<Idle> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1800 + (widget.seed * 137) % 900),
  );
  late final double _phase = (widget.seed * 0.618) % 1;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || MediaQuery.maybeDisableAnimationsOf(context) == true) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final a = (_c.value + _phase) * math.pi * 2;
        return Transform.translate(
          offset: Offset(0, math.sin(a) * 5 * widget.amount),
          child: Transform.rotate(angle: math.sin(a * .5) * .035 * widget.amount, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// ورود فنری: از کوچک به اندازه‌ی کامل با کمی جهش، بعد از [delay].
class PopIn extends StatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.from = .2});

  final Widget child;
  final Duration delay;
  final double from;

  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final v = Curves.elasticOut.transform(_c.value);
      return Opacity(
        opacity: _c.value.clamp(0, 1) == 0 ? 0 : (_c.value * 3).clamp(0.0, 1.0),
        child: Transform.scale(scale: widget.from + (1 - widget.from) * v, child: child),
      );
    },
    child: widget.child,
  );
}

/// له و کش شدن (squash & stretch) هر بار که [trigger] عوض شود: ضربه، فرود، فشار.
class Squash extends StatefulWidget {
  const Squash({super.key, required this.trigger, required this.child, this.amount = .22, this.alignment = Alignment.bottomCenter});

  final int trigger;
  final Widget child;
  final double amount;
  final Alignment alignment;

  @override
  State<Squash> createState() => _SquashState();
}

class _SquashState extends State<Squash> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Squash old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      // له: پهن و کوتاه، بعد کش: باریک و بلند، بعد آرام.
      final t = _c.value;
      final k = math.sin(t * math.pi * 2.5) * math.exp(-t * 4) * widget.amount;
      return Transform(alignment: widget.alignment, transform: Matrix4.diagonal3Values(1 + k, 1 - k, 1), child: child);
    },
    child: widget.child,
  );
}

/// لرزش کل صحنه (ضربه‌ی محکم، روشن شدن موتور).
class ShakeScene extends StatefulWidget {
  const ShakeScene({super.key, required this.trigger, required this.child, this.strength = 6});

  final int trigger;
  final Widget child;
  final double strength;

  @override
  State<ShakeScene> createState() => _ShakeSceneState();
}

class _ShakeSceneState extends State<ShakeScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(ShakeScene old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) {
      final d = (1 - _c.value) * widget.strength;
      return Transform.translate(offset: Offset(math.sin(_c.value * 60) * d, math.cos(_c.value * 47) * d * .6), child: child);
    },
    child: widget.child,
  );
}

/// سایه‌ی بیضی نرم زیر یک شیء، تا روی زمین صحنه بنشیند.
class GroundShadow extends StatelessWidget {
  const GroundShadow({super.key, required this.width, this.opacity = .22});

  final double width;
  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: width,
      height: width * .18,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.elliptical(width / 2, width * .09)),
        gradient: RadialGradient(
          colors: [
            Colors.black.withValues(alpha: opacity),
            Colors.transparent,
          ],
        ),
      ),
    ),
  );
}
