import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../ui/clay.dart';
import 'engine.dart';

const _done = Duration(milliseconds: 650);

/// چیدن/پیدا کردن: روی چیزهای درست بزن، نه روی بقیه.
class CollectEngine extends EngineView {
  const CollectEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CollectEngine> createState() => _CollectState();
}

class _CollectState extends ConsumerState<CollectEngine> with EngineSounds {
  late final int need = widget.host.scaled(widget.step.integer('count', 3));
  late final List<({String art, bool good, Offset at})> spots;
  final Set<int> taken = {};
  final Map<int, int> shakes = {};
  int burst = 0;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.step.say.hashCode);
    final distract = widget.step.list('distract');
    final arts = [
      for (var i = 0; i < need; i++) (widget.step.str('target'), true),
      for (var i = 0; i < math.min(need, 3) && distract.isNotEmpty; i++) (distract[i % distract.length], false),
    ]..shuffle(rnd);
    // جاها روی یک شبکه‌ی درهم تا روی هم نیفتند.
    final cols = arts.length <= 4 ? 2 : 3;
    final rows = (arts.length / cols).ceil();
    final cells = [
      for (var r = 0; r < rows; r++)
        for (var c = 0; c < cols; c++) (r, c),
    ]..shuffle(rnd);
    spots = [
      for (final (i, (a, g)) in arts.indexed)
        (
          art: a,
          good: g,
          at: Offset((cells[i].$2 + .5 + (rnd.nextDouble() - .5) * .4) / cols, (cells[i].$1 + .5 + (rnd.nextDouble() - .5) * .3) / rows),
        ),
    ];
  }

  void _tap(int i) {
    if (taken.contains(i)) return;
    final s = spots[i];
    if (!s.good) {
      setState(() => shakes[i] = (shakes[i] ?? 0) + 1);
      bad();
      return;
    }
    setState(() {
      taken.add(i);
      burst++;
    });
    good(widget.step.opt('sound'));
    if (taken.length == need) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight) / (spots.length <= 4 ? 2.6 : 3.4);
      final firstGood = spots.indexWhere((s) => s.good && !taken.contains(spots.indexOf(s)));
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            for (final (i, s) in spots.indexed)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInBack,
                left: s.at.dx * box.maxWidth - size / 2,
                top: taken.contains(i) ? -size * 2 : s.at.dy * box.maxHeight - size / 2,
                child: GestureDetector(
                  onTap: () => _tap(i),
                  child: Shake(
                    trigger: shakes[i] ?? 0,
                    child: HintGlow(
                      on: hint >= 1 && i == firstGood,
                      child: GameArt(s.art, size: size),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              child: CountChip(icon: Icons.check_circle_rounded, value: taken.length, color: G.green, label: 'پیدا شده'),
            ),
            if (hint >= 3 && firstGood >= 0)
              HintHand(from: Offset(spots[firstGood].at.dx * box.maxWidth, spots[firstGood].at.dy * box.maxHeight)),
            Positioned.fill(child: Sparkles(trigger: burst)),
          ],
        ),
      );
    },
  );
}

/// ضربه‌های پشت سر هم تا نوار پر شود (فشار دادن، ورز دادن، دوشیدن، میخ زدن).
class TapEngine extends EngineView {
  const TapEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<TapEngine> createState() => _TapState();
}

class _TapState extends ConsumerState<TapEngine> with EngineSounds {
  late final int need = widget.host.scaled(widget.step.integer('count', 5));
  int n = 0;

  void _tap() {
    if (n >= need) return;
    setState(() => n++);
    good(widget.step.opt('sound'));
    if (n == need) {
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
            GestureDetector(
              onTap: _tap,
              child: Bounce(
                trigger: n,
                child: HintGlow(
                  on: hint >= 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: GameArt(art, key: ValueKey(art), size: size),
                  ),
                ),
              ),
            ),
            Positioned(bottom: 8, left: 24, right: 24, child: _Meter(value: n / need)),
            if (hint >= 3) HintHand(from: Offset(box.maxWidth / 2, box.maxHeight / 2)),
            Positioned.fill(child: Sparkles(trigger: n >= need ? 1 : 0)),
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
    height: 22,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: G.soft()),
    padding: const EdgeInsets.all(4),
    child: Align(
      alignment: AlignmentDirectional.centerStart,
      child: AnimatedFractionallySizedBox(
        duration: const Duration(milliseconds: 200),
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(color: G.green, borderRadius: BorderRadius.circular(9)),
        ),
      ),
    ),
  );
}

/// چرخاندن انگشت دور شیء (هم زدن، کلید، پیچ، دسته‌ی چاه).
class RotateEngine extends EngineView {
  const RotateEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<RotateEngine> createState() => _RotateState();
}

class _RotateState extends ConsumerState<RotateEngine> with EngineSounds {
  late final int turns = math.max(1, widget.host.scaled(widget.step.integer('turns', 2)));
  double angle = 0;
  double? _last;
  int _soundTick = 0;
  bool finished = false;

  void _move(Offset local, Size size) {
    if (finished) return;
    final c = size.center(Offset.zero);
    final a = math.atan2(local.dy - c.dy, local.dx - c.dx);
    if (_last != null) {
      var d = a - _last!;
      if (d > math.pi) d -= math.pi * 2;
      if (d < -math.pi) d += math.pi * 2;
      setState(() => angle += d.abs());
      final tick = (angle / (math.pi / 2)).floor();
      if (tick != _soundTick) {
        _soundTick = tick;
        sfx(widget.step.opt('sound'));
        widget.host.right();
      }
      if (angle >= turns * math.pi * 2) {
        finished = true;
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
      final art = finished ? widget.step.str('result', widget.step.str('target')) : widget.step.str('target');
      final progress = (angle / (turns * math.pi * 2)).clamp(0.0, 1.0);
      return GestureDetector(
        onPanStart: (d) => _last = null,
        onPanUpdate: (d) => _move(d.localPosition, size),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: size,
                painter: _RingPainter(r: r, progress: progress, glow: hint >= 1),
              ),
              Transform.rotate(
                angle: angle * .25,
                child: GameArt(art, size: r * 1.2),
              ),
              Positioned(
                left: size.width / 2 + math.cos(angle) * r - 22,
                top: size.height / 2 + math.sin(angle) * r - 22,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: G.orange,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: G.soft(),
                  ),
                  child: const Icon(Icons.rotate_right_rounded, color: Colors.white),
                ),
              ),
              if (hint >= 3) _CircleHand(center: size.center(Offset.zero), r: r),
              Positioned.fill(child: Sparkles(trigger: finished ? 1 : 0)),
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
        ..strokeWidth = 18
        ..color = glow ? const Color(0xFFFFE066) : Colors.white.withValues(alpha: .8),
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      progress * math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 18
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

/// زمان درست: وقتی رنگ طلایی شد بزن (فر، گل، فوت).
class TimingEngine extends EngineView {
  const TimingEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<TimingEngine> createState() => _TimingState();
}

class _TimingState extends ConsumerState<TimingEngine> with EngineSounds, SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.host.age.minAge <= 2 ? 4200 : 3200),
  )..repeat();
  bool finished = false;
  int shake = 0;

  // پنجره‌ی درست، بزرگ‌تر برای کوچک‌ترها.
  double get lo => widget.host.age.minAge <= 2 ? .45 : .55;
  double get hi => widget.host.age.minAge <= 2 ? .85 : .78;

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
      final size = math.min(box.maxWidth, box.maxHeight) * .55;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final v = _c.value;
            final inZone = v >= lo && v <= hi;
            final art = finished ? widget.step.str('result', widget.step.str('target')) : widget.step.str('target');
            return Stack(
              alignment: Alignment.center,
              children: [
                Shake(
                  trigger: shake,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Color.lerp(Colors.white, v > hi ? const Color(0xFF8D6E63) : const Color(0xFFFFC83D), finished ? 0 : (v * .55))!,
                      BlendMode.modulate,
                    ),
                    child: GameArt(art, size: size),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 24,
                  right: 24,
                  child: SizedBox(
                    height: 34,
                    child: CustomPaint(
                      painter: _ZonePainter(v: v, lo: lo, hi: hi, glow: hint >= 1),
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  child: Pressable(
                    onTap: _tap,
                    color: inZone || finished ? G.green : G.orange,
                    sound: null,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    child: Text(widget.step.str('label', 'حالا!'), style: PText.button),
                  ),
                ),
                if (hint >= 3 && inZone)
                  const Positioned(
                    top: 30,
                    child: IgnorePointer(child: Text('👆', style: TextStyle(fontSize: 48))),
                  ),
                Positioned.fill(child: Sparkles(trigger: finished ? 1 : 0)),
              ],
            );
          },
        ),
      );
    },
  );
}

class _ZonePainter extends CustomPainter {
  _ZonePainter({required this.v, required this.lo, required this.hi, required this.glow});

  final double v, lo, hi;
  final bool glow;

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(17));
    canvas.drawRRect(r, Paint()..color = Colors.white);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s.width * lo, 4, s.width * (hi - lo), s.height - 8), const Radius.circular(13)),
      Paint()..color = glow ? const Color(0xFFFFE066) : const Color(0xFFB8F0C9),
    );
    canvas.drawCircle(Offset(s.width * v, s.height / 2), s.height / 2 - 3, Paint()..color = G.purple);
  }

  @override
  bool shouldRepaint(_ZonePainter old) => old.v != v || old.glow != glow;
}

/// بریدن: انگشت را روی خط نقطه‌چین بکش.
class CutEngine extends EngineView {
  const CutEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CutEngine> createState() => _CutState();
}

class _CutState extends ConsumerState<CutEngine> with EngineSounds {
  late final int lines = widget.step.integer('lines', 1).clamp(1, 3);
  int cut = 0;
  Offset? _start;
  double _minX = 1e9, _maxX = -1e9;

  double lineY(int i, Size s) => s.height * (lines == 1 ? .5 : .3 + .4 * i / (lines - 1));

  void _end(Size s) {
    if (_start == null || cut >= lines) return;
    final y = lineY(cut, s);
    final width = _maxX - _minX;
    if ((_start!.dy - y).abs() < 70 && width > s.width * .4) {
      setState(() => cut++);
      good('audio/sfx/snap.mp3');
      if (cut == lines) {
        widget.host.points(5);
        Future.delayed(_done, widget.host.done);
      }
    } else if (width > 30) {
      bad();
    }
    _start = null;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final size = math.min(s.width, s.height) * .7;
      final finished = cut >= lines;
      final art = finished ? widget.step.str('result', widget.step.str('target')) : widget.step.str('target');
      return GestureDetector(
        onPanStart: (d) {
          _start = d.localPosition;
          _minX = _maxX = d.localPosition.dx;
        },
        onPanUpdate: (d) {
          _minX = math.min(_minX, d.localPosition.dx);
          _maxX = math.max(_maxX, d.localPosition.dx);
        },
        onPanEnd: (_) => _end(s),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.transparent),
              Bounce(
                trigger: cut,
                child: GameArt(art, size: size),
              ),
              if (!finished)
                for (var i = cut; i < lines; i++)
                  Positioned(
                    top: lineY(i, s) - 3,
                    left: s.width * .08,
                    right: s.width * .08,
                    child: CustomPaint(
                      size: Size(s.width * .84, 6),
                      painter: _DashPainter(glow: hint >= 1 && i == cut),
                    ),
                  ),
              if (hint >= 3 && !finished) HintHand(from: Offset(s.width * .12, lineY(cut, s)), to: Offset(s.width * .85, lineY(cut, s))),
              Positioned.fill(child: Sparkles(trigger: cut)),
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
      ..color = glow ? const Color(0xFFFFB300) : G.purple
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (var x = 0.0; x < s.width; x += 22) {
      canvas.drawLine(Offset(x, s.height / 2), Offset(math.min(x + 12, s.width), s.height / 2), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.glow != glow;
}

/// شستن: گل‌ها را با انگشت پاک کن.
class ScrubEngine extends EngineView {
  const ScrubEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<ScrubEngine> createState() => _ScrubState();
}

class _ScrubState extends ConsumerState<ScrubEngine> with EngineSounds {
  static const grid = 8;
  final Set<int> clean = {};
  late final List<(int, double)> mud;
  bool finished = false;
  int _lastSound = 0;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(3);
    mud = [
      for (var i = 0; i < grid * grid; i++)
        if (rnd.nextDouble() < .55) (i, .6 + rnd.nextDouble() * .5),
    ];
  }

  void _wipe(Offset p, Size s) {
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
    setState(() {});
    if (clean.length - _lastSound > 6) {
      _lastSound = clean.length;
      sfx('audio/sfx/bubbles.mp3');
      widget.host.right();
    }
    final left = mud.where((m) => !clean.contains(m.$1)).length;
    if (left <= mud.length * .1) {
      finished = true;
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      return GestureDetector(
        onPanUpdate: (d) => _wipe(d.localPosition, s),
        onPanDown: (d) => _wipe(d.localPosition, s),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            alignment: Alignment.center,
            children: [
              Container(color: Colors.transparent),
              GameArt(widget.step.str('target'), size: math.min(s.width, s.height) * .8),
              CustomPaint(
                size: s,
                painter: _MudPainter(mud: mud, clean: clean, grid: grid),
              ),
              if (hint >= 3) HintHand(from: Offset(s.width * .2, s.height * .3), to: Offset(s.width * .8, s.height * .7)),
              Positioned.fill(
                child: Sparkles(trigger: finished ? 1 : 0, color: const Color(0xFF81D4FA)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MudPainter extends CustomPainter {
  _MudPainter({required this.mud, required this.clean, required this.grid});

  final List<(int, double)> mud;
  final Set<int> clean;
  final int grid;

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width / grid, h = s.height / grid;
    final p = Paint()..color = const Color(0xFF8D6E63).withValues(alpha: .85);
    for (final (i, k) in mud) {
      if (clean.contains(i)) continue;
      final c = Offset((i % grid + .5) * w, (i ~/ grid + .5) * h);
      canvas.drawCircle(c, math.min(w, h) * .55 * k, p);
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
  int burst = 0;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(widget.step.say.hashCode);
    at = [for (var i = 0; i < need; i++) Offset(.15 + rnd.nextDouble() * .7, .15 + rnd.nextDouble() * .7)];
  }

  void _move(Offset p, Size s) {
    setState(() => light = Offset(p.dx / s.width, p.dy / s.height));
    widget.host.touch();
  }

  void _tap(int i) {
    if (found.contains(i)) return;
    setState(() {
      found.add(i);
      burst++;
    });
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
      final radius = math.min(s.width, s.height) * .24;
      final lp = Offset(light.dx * s.width, light.dy * s.height);
      return GestureDetector(
        onPanDown: (d) => _move(d.localPosition, s),
        onPanUpdate: (d) => _move(d.localPosition, s),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) {
            final next = [for (var i = 0; i < need; i++) i].where((i) => !found.contains(i)).firstOrNull;
            return ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF26318A)),
                  for (final (i, o) in at.indexed)
                    if (!found.contains(i))
                      Positioned(
                        left: o.dx * s.width - size / 2,
                        top: o.dy * s.height - size / 2,
                        child: GestureDetector(
                          onTap: (lp - Offset(o.dx * s.width, o.dy * s.height)).distance < radius * 1.1 ? () => _tap(i) : null,
                          child: GameArt(widget.step.str('target'), size: size),
                        ),
                      ),
                  IgnorePointer(
                    child: CustomPaint(
                      size: s,
                      painter: _DarkPainter(
                        light: lp,
                        r: radius,
                        hint: hint >= 1 && next != null ? Offset(at[next].dx * s.width, at[next].dy * s.height) : null,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: CountChip(icon: Icons.flashlight_on_rounded, value: found.length, color: G.yellow, label: 'پیدا شده'),
                  ),
                  if (hint >= 3 && next != null) HintHand(from: lp, to: Offset(at[next].dx * s.width, at[next].dy * s.height)),
                  Positioned.fill(child: Sparkles(trigger: burst)),
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
  _DarkPainter({required this.light, required this.r, this.hint});

  final Offset light;
  final double r;
  final Offset? hint;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.saveLayer(Offset.zero & s, Paint());
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xF0101438));
    final clear = Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = const RadialGradient(
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, .6, 1],
      ).createShader(Rect.fromCircle(center: light, radius: r));
    canvas.drawCircle(light, r, clear);
    canvas.restore();
    if (hint != null) {
      canvas.drawCircle(hint!, 26, Paint()..color = const Color(0x66FFE066));
    }
  }

  @override
  bool shouldRepaint(_DarkPainter old) => old.light != light || old.hint != hint;
}

/// ریتم و حافظه: پوپو آهنگی می‌زند، کودک تکرار می‌کند.
class RhythmEngine extends EngineView {
  const RhythmEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<RhythmEngine> createState() => _RhythmState();
}

class _RhythmState extends ConsumerState<RhythmEngine> with EngineSounds {
  late final pads = widget.step.maps('pads');
  late final int rounds = math.max(1, widget.step.integer('rounds', 3) - (widget.host.age.minAge <= 2 ? 1 : 0));
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

  Future<void> _play() async {
    setState(() => listening = false);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    for (final p in pattern) {
      if (!mounted) return;
      setState(() => lit = p);
      sfx(pads[p]['sound'] as String);
      await Future<void>.delayed(const Duration(milliseconds: 520));
      if (!mounted) return;
      setState(() => lit = null);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (mounted) setState(() => listening = true);
    widget.host.touch();
  }

  void _tap(int i) {
    sfx(pads[i]['sound'] as String);
    setState(() => lit = i);
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
      final size = math.min(box.maxWidth / (pads.length + .5), box.maxHeight * .5);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StepDots(done: round, total: rounds),
            const SizedBox(height: 12),
            Text(listening ? 'حالا تو بزن!' : 'گوش کن...', style: PText.title.copyWith(color: G.purple)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pads.length; i++)
                  GestureDetector(
                    onTap: () => _tap(i),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 120),
                      scale: lit == i ? 1.18 : 1,
                      child: Container(
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: lit == i ? const Color(0xFFFFF3B0) : Colors.white,
                          boxShadow: [
                            ...G.soft(),
                            if (hint >= 1 && listening && pos < pattern.length && pattern[pos] == i)
                              BoxShadow(color: const Color(0xFFFFE066).withValues(alpha: .9), blurRadius: 24, spreadRadius: 6),
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
