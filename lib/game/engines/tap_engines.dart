import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../ui/clay.dart';
import '../../ui/toons/toon.dart';
import '../../ui/fx.dart';
import 'engine.dart';
import 'props.dart';

const _done = Duration(milliseconds: 700);

/// رنگ ذره‌ها برای هر چیز (آب‌پرتقال نارنجی، آب آبی، …).
Color juiceColor(String id) => switch (id) {
  'orange' || 'orange_half' || 'juice' || 'juicer' => const Color(0xFFFFA726),
  'tomato' || 'light_red' => const Color(0xFFE53935),
  'milk' || 'cow' || 'bucket' => Colors.white,
  'fuel' => const Color(0xFFE53935),
  'clay' || 'clay_bowl' => const Color(0xFF8D6E63),
  _ => const Color(0xFF4FC3F7),
};

/// ذره‌ی مناسب ضربه به هر چیز.
Fx hitFx(String id) => switch (id) {
  'juicer' || 'orange' || 'orange_half' || 'cow' || 'bucket' => Fx.drops,
  'dough' || 'clay' || 'flour' => Fx.dust,
  'nail' || 'peg' || 'drill' || 'flashlight' => Fx.sparks,
  'egg' => Fx.crumbs,
  'empty_pot' => Fx.dust,
  _ => Fx.sparkle,
};

/// چیدن/پیدا کردن: چیزها روی درخت (یا در صحنه) آرام تکان می‌خورند؛ با لمس درست، در کمانی به سبد
/// پایین می‌پرند و سبد له و کش می‌شود. اشتباه می‌لرزد.
class CollectEngine extends EngineView {
  const CollectEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CollectEngine> createState() => _CollectState();
}

class _CollectState extends ConsumerState<CollectEngine> with EngineSounds {
  late final int need = widget.host.scaled(widget.step.integer('count', 3));
  late final String target = widget.step.str('target');
  late final List<({String art, bool good, Offset at})> spots;
  final Set<int> taken = {};
  final List<String> inBasket = [];
  final Map<int, int> shakes = {};
  final _basket = GlobalKey();
  int bump = 0;

  /// درخت برای میوه؛ برای بقیه (مرغ، کاه، آتش‌بازی…) صحنه‌ی آزاد.
  bool get tree => const {'orange', 'apple'}.contains(target);

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.step.say.hashCode);
    final distract = widget.step.list('distract');
    final arts = [
      for (var i = 0; i < need; i++) (target, true),
      for (var i = 0; i < math.min(need, 3) && distract.isNotEmpty; i++) (distract[i % distract.length], false),
    ]..shuffle(rnd);
    // جاها روی تاج درخت (بیضی) یا در نیمه‌ی بالای صحنه، بی‌هم‌پوشانی.
    final out = <Offset>[];
    var guard = 0;
    while (out.length < arts.length && guard++ < 600) {
      final a = rnd.nextDouble() * math.pi * 2, r = math.sqrt(rnd.nextDouble());
      final o = tree ? Offset(.5 + math.cos(a) * r * .36, .3 + math.sin(a) * r * .2) : Offset(.12 + rnd.nextDouble() * .76, .1 + rnd.nextDouble() * .45);
      if (out.every((q) => (q - o).distance > .17)) out.add(o);
    }
    while (out.length < arts.length) {
      out.add(Offset(.15 + out.length * .12 % .7, .2));
    }
    spots = [for (final (i, (a, g)) in arts.indexed) (art: a, good: g, at: out[i])];
  }

  void _tap(int i, BuildContext at) {
    if (taken.contains(i)) return;
    final s = spots[i];
    if (!s.good) {
      setState(() => shakes[i] = (shakes[i] ?? 0) + 1);
      bad();
      return;
    }
    setState(() => taken.add(i));
    good(widget.step.opt('sound'));
    final fx = FxScope.of(context);
    final from = at.globalCenter;
    final to = _basket.currentContext?.globalCenter ?? from;
    at.fx(Fx.sparkle, count: 8);
    if (tree) at.fx(Fx.dust, count: 5, color: const Color(0xFF66BB6A));
    void land() {
      if (!mounted) return;
      setState(() {
        inBasket.add(s.art);
        bump++;
      });
      _basket.currentContext?.fx(Fx.sparkle, count: 6);
      ui(UiSound.pop);
      if (inBasket.length == need) {
        widget.host.points(5);
        Future.delayed(_done, widget.host.done);
      }
    }

    if (fx == null) {
      land();
    } else {
      fx.fly(s.art, from, to - const Offset(0, 20), size: 90, ms: 700, arc: 90, spin: .5, endScale: .55, onLand: land);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight) / (spots.length <= 4 ? 3.2 : 4.2);
      final firstGood = [for (var i = 0; i < spots.length; i++) i].where((i) => spots[i].good && !taken.contains(i)).firstOrNull;
      final basketW = math.min(box.maxWidth * .4, 170.0);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            if (tree)
              Positioned(
                left: box.maxWidth * .08,
                right: box.maxWidth * .08,
                top: 0,
                height: box.maxHeight * .78,
                child: TreeProp(size: Size(box.maxWidth * .84, box.maxHeight * .78)),
              ),
            for (final (i, s) in spots.indexed)
              if (!taken.contains(i))
                Positioned(
                  left: s.at.dx * box.maxWidth - size / 2,
                  top: s.at.dy * box.maxHeight - size / 2,
                  child: Builder(
                    builder: (c) => GestureDetector(
                      onTap: () => _tap(i, c),
                      child: Shake(
                        trigger: shakes[i] ?? 0,
                        child: Idle(
                          seed: i,
                          amount: .8,
                          child: HintGlow(on: hint >= 1 && i == firstGood, child: PopIn(delay: Duration(milliseconds: 80 * i), child: GameArt(s.art, size: size))),
                        ),
                      ),
                    ),
                  ),
                ),
            Positioned(
              left: box.maxWidth / 2 - basketW / 2,
              bottom: 0,
              child: BasketProp(key: _basket, width: basketW, items: inBasket, bump: bump, label: '${fa(inBasket.length)}/${fa(need)}'),
            ),
            if (hint >= 3 && firstGood != null)
              HintHand(from: Offset(spots[firstGood].at.dx * box.maxWidth, spots[firstGood].at.dy * box.maxHeight)),
          ],
        ),
      );
    },
  );
}

/// ضربه‌های پشت سر هم (فشار دادن، ورز دادن، دوشیدن، میخ زدن): هر ضربه چیز را له و کش می‌کند،
/// ذره‌ی مناسبش می‌پرد و نوار پر می‌شود؛ آخرش با برق به نتیجه تبدیل می‌شود.
class TapEngine extends EngineView {
  const TapEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<TapEngine> createState() => _TapState();
}

class _TapState extends ConsumerState<TapEngine> with EngineSounds {
  late final int need = widget.host.scaled(widget.step.integer('count', 5));
  final _art = GlobalKey();
  int n = 0;

  void _tap() {
    if (n >= need) return;
    setState(() => n++);
    good(widget.step.opt('sound'));
    final id = widget.step.str('target');
    _art.currentContext?.fx(hitFx(id), count: 8, color: hitFx(id) == Fx.drops ? juiceColor(id) : null, spread: .8);
    if (n == need) {
      _art.currentContext?.fx(Fx.sparkle, count: 18);
      ui(UiSound.sparkle);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight) * .6;
      final art = n >= need ? widget.step.str('result', widget.step.str('target')) : widget.step.str('target');
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned(bottom: box.maxHeight * .14, child: GroundShadow(width: size * .7)),
            GestureDetector(
              onTap: _tap,
              child: Squash(
                key: _art,
                trigger: n,
                amount: .28,
                child: HintGlow(
                  on: hint >= 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (c, a) => ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.elasticOut), child: c),
                    child: GameArt(art, key: ValueKey(art), size: size, mood: n >= need ? ToonMood.happy : (n > 0 ? ToonMood.act : ToonMood.idle)),
                  ),
                ),
              ),
            ),
            Positioned(bottom: 4, left: 24, right: 24, child: _Meter(value: n / need)),
            if (n == 0) Positioned(top: 4, child: _Bubble(widget.step.str('label').isEmpty ? 'بزن، بزن، بزن!' : widget.step.str('label'))),
            if (hint >= 3) HintHand(from: Offset(box.maxWidth / 2, box.maxHeight / 2)),
          ],
        ),
      );
    },
  );
}

class _Meter extends StatelessWidget {
  const _Meter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => Container(
    height: 26,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: G.soft()),
    padding: const EdgeInsets.all(4),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF7BE495), G.green]),
            borderRadius: BorderRadius.circular(11),
          ),
        ),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => PopIn(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
      child: Text(text, style: PText.heading.copyWith(color: G.purple, fontSize: 16)),
    ),
  );
}

/// چرخاندن انگشت دور شیء (هم زدن، کلید، پیچ، دسته‌ی چاه): گرداب درون ظرف می‌چرخد، بخار و حباب
/// بالا می‌رود، خود شیء همراه انگشت می‌چرخد.
class RotateEngine extends EngineView {
  const RotateEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<RotateEngine> createState() => _RotateState();
}

class _RotateState extends ConsumerState<RotateEngine> with EngineSounds {
  late final int turns = math.max(1, widget.host.scaled(widget.step.integer('turns', 2)));
  late final String target = widget.step.str('target');
  final _art = GlobalKey();
  double angle = 0;
  double spin = 0;
  double? _last;
  int _soundTick = 0;
  bool finished = false;

  /// ظرف‌ها گرداب و بخار دارند؛ کلید و پیچ خودشان می‌چرخند.
  bool get vessel => const {'pot', 'bowl_mix', 'bucket', 'well', 'tube', 'pottery_wheel'}.contains(target);

  void _move(Offset local, Size size) {
    if (finished) return;
    final c = size.center(Offset.zero);
    final a = math.atan2(local.dy - c.dy, local.dx - c.dx);
    if (_last != null) {
      var d = a - _last!;
      if (d > math.pi) d -= math.pi * 2;
      if (d < -math.pi) d += math.pi * 2;
      setState(() {
        angle += d.abs();
        spin += d;
      });
      final tick = (angle / (math.pi / 2)).floor();
      if (tick != _soundTick) {
        _soundTick = tick;
        sfx(widget.step.opt('sound'));
        widget.host.right();
        _art.currentContext?.fx(target == 'pot' ? Fx.steam : (vessel ? Fx.bubbles : Fx.sparks), count: 3);
      }
      if (angle >= turns * math.pi * 2) {
        finished = true;
        _art.currentContext?.fx(Fx.sparkle, count: 18);
        widget.host.points(5);
        Future.delayed(_done, widget.host.done);
      }
    }
    _last = a;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = Size(box.maxWidth, box.maxHeight);
      final r = math.min(box.maxWidth, box.maxHeight) * .42;
      final art = finished ? widget.step.str('result', target) : target;
      final progress = (angle / (turns * math.pi * 2)).clamp(0.0, 1.0);
      final knob = size.center(Offset.zero) + Offset(math.cos(spin), math.sin(spin)) * r;
      return GestureDetector(
        onPanStart: (d) => _last = null,
        onPanUpdate: (d) => _move(d.localPosition, size),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.transparent),
              CustomPaint(size: size, painter: _RingPainter(r: r, progress: progress, glow: hint >= 1)),
              Transform.rotate(
                key: _art,
                angle: vessel ? math.sin(spin * 2) * .05 : spin,
                child: GameArt(art, size: r * 1.25, mood: finished ? ToonMood.happy : (progress > 0 ? ToonMood.act : ToonMood.idle)),
              ),
              if (vessel && !finished)
                IgnorePointer(
                  child: CustomPaint(
                    size: Size(r * .9, r * .9),
                    painter: SwirlPainter(angle: spin * 2, color: juiceColor(target) == Colors.white ? const Color(0xFFBDBDBD) : juiceColor(target), strength: (angle / 6).clamp(0.2, 1.0)),
                  ),
                ),
              Positioned(
                left: knob.dx - 26,
                top: knob.dy - 26,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: G.orange, border: Border.all(color: Colors.white, width: 5), boxShadow: G.soft()),
                  child: const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 28),
                ),
              ),
              if (hint >= 3) _CircleHand(center: size.center(Offset.zero), r: r),
            ],
          ),
        ),
      );
    },
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.r, required this.progress, required this.glow});

  final double r;
  final double progress;
  final bool glow;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..color = glow ? const Color(0xFFFFE066) : Colors.white.withValues(alpha: .75),
    );
    // نقطه‌چین راهنما روی حلقه
    final dot = Paint()..color = G.purple.withValues(alpha: .35);
    for (var k = 0; k < 24; k++) {
      final a = k / 24 * math.pi * 2;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 3, dot);
    }
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 20
        ..color = G.green,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress || old.glow != glow;
}

class _CircleHand extends StatefulWidget {
  const _CircleHand({required this.center, required this.r});

  final Offset center;
  final double r;

  @override
  State<_CircleHand> createState() => _CircleHandState();
}

class _CircleHandState extends State<_CircleHand> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final a = _c.value * math.pi * 2;
        return Stack(
          children: [
            Positioned(
              left: widget.center.dx + math.cos(a) * widget.r - 10,
              top: widget.center.dy + math.sin(a) * widget.r - 6,
              child: const Text('👆', style: TextStyle(fontSize: 48)),
            ),
          ],
        );
      },
    ),
  );
}

/// زمان درست (فر، گل، فوت): شیء کم‌کم رنگ می‌گیرد، بخار یا برق از آن بلند می‌شود؛ حلقه‌ی زمان دورش
/// می‌گردد و وقتی در ناحیه‌ی طلایی است باید زد. زود یا دیر = لرزش.
class TimingEngine extends EngineView {
  const TimingEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<TimingEngine> createState() => _TimingState();
}

class _TimingState extends ConsumerState<TimingEngine> with EngineSounds, SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.host.age.minAge <= 2 ? 4400 : 3400))..repeat();
  final _art = GlobalKey();
  bool finished = false;
  int shake = 0;
  int _puff = 0;

  double get lo => widget.host.age.minAge <= 2 ? .45 : .55;
  double get hi => widget.host.age.minAge <= 2 ? .85 : .78;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final k = (_c.value * 10).floor();
      if (k != _puff && !finished) {
        _puff = k;
        _art.currentContext?.fx(widget.step.str('target') == 'sprout' ? Fx.sparkle : Fx.steam, count: 1);
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    if (finished) return;
    final v = _c.value;
    if (v >= lo && v <= hi) {
      _c.stop();
      setState(() => finished = true);
      good(widget.step.opt('sound'));
      _art.currentContext?.fx(Fx.sparkle, count: 20);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    } else {
      setState(() => shake++);
      bad();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight) * .5;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            final inZone = v >= lo && v <= hi;
            final grow = widget.step.str('target') == 'sprout';
            final art = finished ? widget.step.str('result', widget.step.str('target')) : widget.step.str('target');
            return GestureDetector(
              onTap: _tap,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(color: Colors.transparent),
                  CustomPaint(size: Size.square(size * 1.45), painter: _ClockRing(v: v, lo: lo, hi: hi, glow: hint >= 1)),
                  Shake(
                    trigger: shake,
                    child: Transform.scale(
                      key: _art,
                      scale: grow && !finished ? .5 + v * .7 : 1,
                      child: ColorFiltered(
                        colorFilter: ColorFilter.mode(
                          Color.lerp(Colors.white, v > hi ? const Color(0xFF8D6E63) : const Color(0xFFFFC83D), finished ? 0 : (v * .55))!,
                          BlendMode.modulate,
                        ),
                        child: GameArt(art, size: size),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                      decoration: BoxDecoration(
                        color: inZone || finished ? G.green : G.orange,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [...G.soft(), if (inZone && hint >= 1) const BoxShadow(color: Color(0xEEFFE066), blurRadius: 22, spreadRadius: 4)],
                      ),
                      child: Text(inZone ? 'حالا! بزن!' : 'صبر کن...', style: PText.button.copyWith(fontSize: 22)),
                    ),
                  ),
                  if (hint >= 3 && inZone) const Positioned(bottom: 30, child: IgnorePointer(child: Text('👆', style: TextStyle(fontSize: 48)))),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _ClockRing extends CustomPainter {
  _ClockRing({required this.v, required this.lo, required this.hi, required this.glow});

  final double v, lo, hi;
  final bool glow;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 10;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: .35));
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..color = Colors.white.withValues(alpha: .8),
    );
    canvas.drawArc(
      rect,
      -math.pi / 2 + lo * math.pi * 2,
      (hi - lo) * math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..color = glow ? const Color(0xFFFFE066) : const Color(0xFFFFC83D),
    );
    final a = -math.pi / 2 + v * math.pi * 2;
    canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 13, Paint()..color = G.purple);
    canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r, 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ClockRing old) => old.v != v || old.glow != glow;
}

/// بریدن: انگشت را روی خط نقطه‌چین بکش. ردّ انگشت دیده می‌شود؛ با بریدن درست، شیء دو نیم می‌شود و
/// نیمه‌ها کمی از هم جدا می‌شوند و می‌چرخند، خرده یا قطره می‌پرد.
class CutEngine extends EngineView {
  const CutEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CutEngine> createState() => _CutState();
}

class _CutState extends ConsumerState<CutEngine> with EngineSounds {
  late final int lines = widget.step.integer('lines', 1).clamp(1, 3);
  final _art = GlobalKey();
  int cut = 0;
  Offset? _start;
  final List<Offset> trail = [];
  double _minX = 1e9, _maxX = -1e9;

  double lineY(int i, Size s) => s.height * (lines == 1 ? .48 : .3 + .36 * i / (lines - 1));

  void _end(Size s) {
    if (_start == null || cut >= lines) {
      setState(trail.clear);
      return;
    }
    final y = lineY(cut, s);
    final width = _maxX - _minX;
    if ((_start!.dy - y).abs() < 80 && width > s.width * .38) {
      setState(() => cut++);
      good('audio/sfx/snap.mp3');
      final id = widget.step.str('target');
      _art.currentContext?.fx(hitFx(id) == Fx.drops || id == 'orange' ? Fx.drops : Fx.crumbs, count: 12, color: juiceColor(id));
      if (cut == lines) {
        widget.host.points(5);
        Future.delayed(const Duration(milliseconds: 900), widget.host.done);
      }
    } else if (width > 30) {
      bad();
    }
    _start = null;
    setState(trail.clear);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final size = math.min(s.width, s.height) * .66;
      final finished = cut >= lines;
      final id = widget.step.str('target');
      final gap = finished ? 1.0 : cut / lines * .4;
      return GestureDetector(
        onPanStart: (d) {
          _start = d.localPosition;
          _minX = _maxX = d.localPosition.dx;
          trail
            ..clear()
            ..add(d.localPosition);
        },
        onPanUpdate: (d) {
          _minX = math.min(_minX, d.localPosition.dx);
          _maxX = math.max(_maxX, d.localPosition.dx);
          setState(() => trail.add(d.localPosition));
        },
        onPanEnd: (_) => _end(s),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.transparent),
              Positioned(bottom: s.height * .12, child: GroundShadow(width: size * .8)),
              // دو نیمه: بالا و پایین، که با هر برش کمی از هم دور می‌شوند
              SizedBox(
                key: _art,
                width: size,
                height: size,
                child: Stack(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(end: gap),
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutBack,
                      builder: (context, g, _) => Stack(
                        children: [
                          Transform.translate(
                            offset: Offset(-g * 18, -g * 22),
                            child: Transform.rotate(angle: -g * .12, child: ClipRect(child: Align(alignment: Alignment.topCenter, heightFactor: .5, child: GameArt(finished ? widget.step.str('result', id) : id, size: size)))),
                          ),
                          Positioned(
                            top: size / 2,
                            child: Transform.translate(
                              offset: Offset(g * 18, g * 22),
                              child: Transform.rotate(angle: g * .12, child: ClipRect(child: Align(alignment: Alignment.bottomCenter, heightFactor: .5, child: GameArt(finished ? widget.step.str('result', id) : id, size: size)))),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!finished)
                for (var i = cut; i < lines; i++)
                  Positioned(
                    top: lineY(i, s) - 4,
                    left: s.width * .06,
                    right: s.width * .06,
                    child: CustomPaint(size: Size(s.width * .88, 8), painter: _DashPainter(glow: hint >= 1 && i == cut)),
                  ),
              if (trail.length > 1) IgnorePointer(child: CustomPaint(size: s, painter: _TrailPainter(trail))),
              if (hint >= 3 && !finished) HintHand(from: Offset(s.width * .1, lineY(cut, s)), to: Offset(s.width * .88, lineY(cut, s))),
            ],
          ),
        ),
      );
    },
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter({required this.glow});

  final bool glow;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = glow ? const Color(0xFFFFB300) : Colors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final shadow = Paint()
      ..color = Colors.black26
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < s.width; x += 24) {
      canvas.drawLine(Offset(x, s.height / 2 + 2), Offset(math.min(x + 13, s.width), s.height / 2 + 2), shadow);
      canvas.drawLine(Offset(x, s.height / 2), Offset(math.min(x + 13, s.width), s.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.glow != glow;
}

/// ردّ انگشت هنگام بریدن (مثل برق چاقو).
class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 1; i < points.length; i++) {
      final t = i / points.length;
      canvas.drawLine(
        points[i - 1],
        points[i],
        Paint()
          ..color = Colors.white.withValues(alpha: t * .9)
          ..strokeWidth = 4 + t * 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

/// شستن: لکه‌های گل را با انگشت پاک کن؛ زیر انگشت کف و حباب درست می‌شود و آخرش برق می‌زند.
class ScrubEngine extends EngineView {
  const ScrubEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<ScrubEngine> createState() => _ScrubState();
}

class _ScrubState extends ConsumerState<ScrubEngine> with EngineSounds {
  static const grid = 9;
  final Set<int> clean = {};
  late final List<(int, double)> mud;
  final _art = GlobalKey();
  bool finished = false;
  int _lastSound = 0;
  final List<Offset> foam = [];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(3);
    mud = [
      for (var i = 0; i < grid * grid; i++)
        if (rnd.nextDouble() < .55) (i, .6 + rnd.nextDouble() * .5),
    ];
  }

  void _wipe(Offset p, Size s, Offset global) {
    if (finished) return;
    final c = (p.dx / s.width * grid).floor(), r = (p.dy / s.height * grid).floor();
    var changed = false;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final rr = r + dr, cc = c + dc;
        if (rr < 0 || cc < 0 || rr >= grid || cc >= grid) continue;
        changed |= clean.add(rr * grid + cc);
      }
    }
    if (!changed) return;
    setState(() {
      foam.add(p);
      if (foam.length > 30) foam.removeAt(0);
    });
    if (clean.length - _lastSound > 6) {
      _lastSound = clean.length;
      sfx('audio/sfx/bubbles.mp3');
      FxScope.of(context)?.burst(global, Fx.bubbles, count: 4);
      widget.host.right();
    }
    final left = mud.where((m) => !clean.contains(m.$1)).length;
    if (left <= mud.length * .1) {
      finished = true;
      _art.currentContext?.fx(Fx.sparkle, count: 24, color: Colors.white);
      ui(UiSound.sparkle);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanUpdate: (d) => _wipe(d.localPosition, s, d.globalPosition),
        onPanDown: (d) => _wipe(d.localPosition, s, d.globalPosition),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.transparent),
              SizedBox(key: _art, child: GameArt(widget.step.str('target'), size: math.min(s.width, s.height) * .8)),
              IgnorePointer(child: CustomPaint(size: s, painter: _MudPainter(mud: mud, clean: clean, grid: grid, foam: foam))),
              if (hint >= 3) HintHand(from: Offset(s.width * .2, s.height * .3), to: Offset(s.width * .8, s.height * .7)),
            ],
          ),
        ),
      );
    },
  );
}

class _MudPainter extends CustomPainter {
  _MudPainter({required this.mud, required this.clean, required this.grid, required this.foam});

  final List<(int, double)> mud;
  final Set<int> clean;
  final int grid;
  final List<Offset> foam;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width / grid, h = s.height / grid;
    final p = Paint()..color = const Color(0xFF8D6E63).withValues(alpha: .88);
    final p2 = Paint()..color = const Color(0xFF6D4C41).withValues(alpha: .7);
    for (final (i, k) in mud) {
      if (clean.contains(i)) continue;
      final c = Offset((i % grid + .5) * w, (i ~/ grid + .5) * h);
      canvas.drawCircle(c, math.min(w, h) * .62 * k, p);
      canvas.drawCircle(c + Offset(w * .15, -h * .1), math.min(w, h) * .25 * k, p2);
    }
    final f = Paint()..color = Colors.white.withValues(alpha: .85);
    for (final (i, o) in foam.indexed) {
      canvas.drawCircle(o, 6 + (i % 4) * 3.0, f);
    }
  }

  @override
  bool shouldRepaint(_MudPainter old) => true;
}

/// تاریکی: با نور (انگشت) چیزهای پنهان را پیدا کن.
class DarkEngine extends EngineView {
  const DarkEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<DarkEngine> createState() => _DarkState();
}

class _DarkState extends ConsumerState<DarkEngine> with EngineSounds {
  late final int need = widget.host.scaled(widget.step.integer('count', 3));
  late final List<Offset> at;
  final Set<int> found = {};
  Offset light = const Offset(.5, .5);

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.step.say.hashCode);
    at = [];
    var guard = 0;
    while (at.length < need && guard++ < 400) {
      final o = Offset(.12 + rnd.nextDouble() * .76, .12 + rnd.nextDouble() * .7);
      if (at.every((q) => (q - o).distance > .2)) at.add(o);
    }
  }

  void _move(Offset p, Size s) {
    setState(() => light = Offset(p.dx / s.width, p.dy / s.height));
    widget.host.touch();
  }

  void _tap(int i, BuildContext c) {
    if (found.contains(i)) return;
    setState(() => found.add(i));
    c.fx(Fx.sparkle, count: 14);
    good('audio/ui/sparkle.mp3');
    if (found.length == need) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final size = math.min(s.width, s.height) * .2;
      final radius = math.min(s.width, s.height) * .25;
      final lp = Offset(light.dx * s.width, light.dy * s.height);
      return GestureDetector(
        onPanDown: (d) => _move(d.localPosition, s),
        onPanUpdate: (d) => _move(d.localPosition, s),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) {
            final next = [for (var i = 0; i < at.length; i++) i].where((i) => !found.contains(i)).firstOrNull;
            return ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF26318A)),
                  for (final (i, o) in at.indexed)
                    Positioned(
                      left: o.dx * s.width - size / 2,
                      top: o.dy * s.height - size / 2,
                      child: Builder(
                        builder: (c) => GestureDetector(
                          onTap: found.contains(i) || (lp - Offset(o.dx * s.width, o.dy * s.height)).distance < radius * 1.1 ? () => _tap(i, c) : null,
                          child: AnimatedScale(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.elasticOut,
                            scale: found.contains(i) ? 1.3 : 1,
                            child: Idle(seed: i, child: GameArt(widget.step.str('target'), size: size)),
                          ),
                        ),
                      ),
                    ),
                  IgnorePointer(
                    child: CustomPaint(
                      size: s,
                      painter: _DarkPainter(light: lp, r: radius, found: [for (final i in found) Offset(at[i].dx * s.width, at[i].dy * s.height)], hint: hint >= 1 && next != null ? Offset(at[next].dx * s.width, at[next].dy * s.height) : null),
                    ),
                  ),
                  Positioned(top: 8, left: 8, child: CountChip(icon: Icons.flashlight_on_rounded, value: found.length, color: G.yellow, label: 'پیدا شده')),
                  if (hint >= 3 && next != null) HintHand(from: lp, to: Offset(at[next].dx * s.width, at[next].dy * s.height)),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _DarkPainter extends CustomPainter {
  _DarkPainter({required this.light, required this.r, required this.found, this.hint});

  final Offset light;
  final double r;
  final List<Offset> found;
  final Offset? hint;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.saveLayer(Offset.zero & s, Paint());
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xF0101438));
    final clear = Paint()..blendMode = BlendMode.dstOut;
    void hole(Offset c, double radius) {
      clear.shader = const RadialGradient(colors: [Colors.black, Colors.black, Colors.transparent], stops: [0, .6, 1]).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, clear);
    }

    hole(light, r);
    // چیزهای پیدا‌شده خودشان کمی روشن می‌مانند
    for (final f in found) {
      hole(f, r * .45);
    }
    canvas.restore();
    canvas.drawCircle(light, r, Paint()..shader = const RadialGradient(colors: [Color(0x33FFF3B0), Color(0x00FFF3B0)]).createShader(Rect.fromCircle(center: light, radius: r)));
    if (hint != null) canvas.drawCircle(hint!, 28, Paint()..color = const Color(0x66FFE066));
  }

  @override
  bool shouldRepaint(_DarkPainter old) => old.light != light || old.hint != hint || old.found.length != found.length;
}

/// ریتم و حافظه: پوپو آهنگی می‌زند (پدها روشن می‌شوند و نت می‌پرد)، کودک تکرار می‌کند.
class RhythmEngine extends EngineView {
  const RhythmEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<RhythmEngine> createState() => _RhythmState();
}

class _RhythmState extends ConsumerState<RhythmEngine> with EngineSounds {
  late final pads = widget.step.maps('pads');
  late final int rounds = math.max(1, widget.step.integer('rounds', 3) - (widget.host.age.minAge <= 2 ? 1 : 0));
  late final _keys = List.generate(pads.length, (_) => GlobalKey());
  final List<int> hits = List.filled(8, 0);
  final rnd = math.Random(5);
  List<int> pattern = [];
  int pos = 0;
  int round = 0;
  int? lit;
  bool listening = false;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _next();
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _next() {
    pattern = [for (var i = 0; i < round + 2; i++) rnd.nextInt(pads.length)];
    pos = 0;
    _play();
  }

  void _flash(int p) {
    sfx(pads[p]['sound'] as String);
    _keys[p].currentContext?.fx(Fx.notes, count: 2);
    setState(() {
      lit = p;
      hits[p]++;
    });
  }

  Future<void> _play() async {
    setState(() => listening = false);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    for (final p in pattern) {
      if (!mounted) return;
      _flash(p);
      await Future<void>.delayed(const Duration(milliseconds: 540));
      if (!mounted) return;
      setState(() => lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) setState(() => listening = true);
    widget.host.touch();
  }

  void _tap(int i) {
    _flash(i);
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => lit = null);
    });
    if (!listening) return;
    if (pattern[pos] != i) {
      widget.host.wrong();
      ui(UiSound.softNo);
      pos = 0;
      _play();
      return;
    }
    widget.host.right();
    pos++;
    if (pos == pattern.length) {
      round++;
      widget.host.points(5);
      FxScope.of(context)?.burst(context.globalCenter, Fx.sparkle);
      if (round >= rounds) {
        setState(() => listening = false);
        Future.delayed(_done, widget.host.done);
      } else {
        _next();
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth / (pads.length + .5), box.maxHeight * .45);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StepDots(done: round, total: rounds),
            const SizedBox(height: 12),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _Bubble(listening ? 'حالا تو بزن!' : 'گوش کن...', key: ValueKey(listening)),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pads.length; i++)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: Squash(
                      key: _keys[i],
                      trigger: hits[i],
                      alignment: Alignment.center,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lit == i ? const Color(0xFFFFF3B0) : Colors.white,
                          boxShadow: [
                            ...G.soft(),
                            if (lit == i) const BoxShadow(color: Color(0xCCFFE066), blurRadius: 30, spreadRadius: 8),
                            if (hint >= 1 && listening && pos < pattern.length && pattern[pos] == i) BoxShadow(color: const Color(0xFFFFE066).withValues(alpha: .9), blurRadius: 24, spreadRadius: 6),
                          ],
                        ),
                        child: GameArt(pads[i]['art'] as String, size: size),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

/// برای موتورهای دیگر: یک تیکر ساده که هر فریم [onTick] را با فاصله‌ی زمانی صدا می‌زند.
mixin FrameTicker<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late final Ticker _ft = createTicker(_onFrame);
  Duration _last = Duration.zero;

  void onTick(double dt);

  void startTicker() => _ft.start();

  void _onFrame(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, .05);
    _last = now;
    onTick(dt);
  }

  @override
  void dispose() {
    _ft.dispose();
    super.dispose();
  }
}
