import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../ui/clay.dart';
import '../../ui/fx.dart';
import 'engine.dart';
import 'props.dart';

const _done = Duration(milliseconds: 750);

/// یک شیء کشیدنی که اگر جای درست رها نشود با فنر برمی‌گردد؛ هنگام کشیدن کمی بزرگ و کج می‌شود.
class _Draggable extends StatelessWidget {
  const _Draggable({super.key, required this.data, required this.child, this.onStart});

  final String data;
  final Widget child;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Draggable<String>(
    data: data,
    onDragStarted: onStart,
    feedback: Transform.rotate(angle: -.08, child: Transform.scale(scale: 1.18, child: child)),
    childWhenDragging: Opacity(opacity: .2, child: child),
    child: child,
  );
}

/// برچسب شماره‌ی بزرگ که با هر دانه می‌پرد («۱!»، «۲!»…).
class _CountPop extends StatelessWidget {
  const _CountPop(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => PopIn(
    key: ValueKey(n),
    from: .3,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      decoration: BoxDecoration(
        color: G.orange,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: G.soft(),
      ),
      child: Text(fa(n), style: PText.display.copyWith(color: Colors.white, fontSize: 34)),
    ),
  );
}

/// جدا کردن: چیزها روی نوار نقاله می‌آیند؛ هر کدام را در سطل درست بینداز.
class SortEngine extends EngineView {
  const SortEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<SortEngine> createState() => _SortState();
}

class _SortState extends ConsumerState<SortEngine> with EngineSounds, SingleTickerProviderStateMixin {
  late final List<(String, bool)> queue;
  late final AnimationController _belt = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  final _goodBin = GlobalKey();
  final _badBin = GlobalKey();
  final List<String> goodIn = [];
  int i = 0;
  int shake = 0;
  int goodBump = 0;
  int badBump = 0;

  @override
  void initState() {
    super.initState();
    queue = [for (final g in widget.step.list('good')) (g, true), for (final b in widget.step.list('bad')) (b, false)]
      ..shuffle(math.Random(2));
    _belt.forward();
  }

  @override
  void dispose() {
    _belt.dispose();
    super.dispose();
  }

  void _drop(bool toGood) {
    final (art, isGood) = queue[i];
    if (isGood != toGood) {
      setState(() => shake++);
      bad();
      return;
    }
    good(isGood ? null : 'audio/sfx/thunk.mp3');
    final bin = toGood ? _goodBin : _badBin;
    bin.currentContext?.fx(toGood ? Fx.sparkle : Fx.dust, count: 12);
    setState(() {
      if (toGood) {
        goodIn.add(art);
        goodBump++;
      } else {
        badBump++;
      }
      i++;
    });
    if (i == queue.length) {
      bin.currentContext?.fx(Fx.confetti, count: 30);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    } else {
      ui(UiSound.whoosh);
      _belt.forward(from: 0);
    }
  }

  Widget _bin(Key key, String label, bool isGood, Color color, bool glow, int bump) => DragTarget<String>(
    onAcceptWithDetails: (_) => _drop(isGood),
    builder: (context, cand, _) => Stack(
      key: key,
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        BinProp(
          label: label,
          color: color,
          icon: isGood ? Icons.shopping_basket_rounded : Icons.delete_rounded,
          bump: bump,
          highlight: cand.isNotEmpty,
          glow: glow,
        ),
        // چیزهای خوب از لبه‌ی سبد پیداست.
        if (isGood)
          for (final (k, a) in goodIn.reversed.take(4).indexed)
            Positioned(top: -26 - (k.isOdd ? 6 : 0), left: 6.0 + k * 30, child: GameArt(a, size: 46)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight) * .34;
      final current = i < queue.length ? queue[i] : null;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // نوار نقاله
                      Positioned(
                        left: 0,
                        right: 0,
                        top: box.maxHeight * .1 + size * .9,
                        height: 34,
                        child: AnimatedBuilder(
                          animation: _belt,
                          builder: (context, _) => CustomPaint(painter: _BeltPainter(_belt.value)),
                        ),
                      ),
                      if (current != null)
                        Positioned(
                          top: box.maxHeight * .1,
                          child: AnimatedBuilder(
                            animation: _belt,
                            builder: (context, child) => Transform.translate(
                              offset: Offset((1 - Curves.easeOutBack.transform(_belt.value)) * box.maxWidth * .7, 0),
                              child: child,
                            ),
                            child: Shake(
                              trigger: shake,
                              child: _Draggable(
                                key: ValueKey(i),
                                data: current.$1,
                                onStart: widget.host.touch,
                                child: Idle(
                                  seed: i,
                                  child: GameArt(current.$1, size: size),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bin(_goodBin, widget.step.str('goodLabel', 'خوب'), true, G.green, hint >= 1 && current?.$2 == true, goodBump),
                    _bin(_badBin, widget.step.str('badLabel', 'خراب'), false, G.red, hint >= 1 && current?.$2 == false, badBump),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (hint >= 3 && current != null)
              HintHand(
                from: Offset(box.maxWidth / 2, box.maxHeight * .1 + size / 2),
                to: Offset(current.$2 ? box.maxWidth * .75 : box.maxWidth * .25, box.maxHeight - 70),
              ),
          ],
        ),
      );
    },
  );
}

class _BeltPainter extends CustomPainter {
  _BeltPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height / 2));
    canvas.drawRRect(r, Paint()..color = const Color(0xFF6D6A85));
    canvas.save();
    canvas.clipRRect(r.deflate(5));
    canvas.drawRRect(r.deflate(5), Paint()..color = const Color(0xFF8E8BA8));
    final stripe = Paint()
      ..color = const Color(0xFF6D6A85)
      ..strokeWidth = 5;
    // نوار به سمت چپ حرکت می‌کند (همراه چیزی که می‌آید).
    final shift = -(Curves.easeOut.transform(t) * 120) % 30;
    for (var x = shift - 30; x < s.width + 30; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x + 12, s.height), stripe);
    }
    canvas.restore();
    for (final x in [s.height / 2, s.width - s.height / 2]) {
      canvas.drawCircle(Offset(x, s.height / 2), s.height * .32, Paint()..color = const Color(0xFFBDBACB));
    }
  }

  @override
  bool shouldRepaint(_BeltPainter old) => old.t != t;
}

/// سوار کردن: هر تکه را روی سایه‌اش بگذار؛ تکه با ضربه می‌نشیند و آخرش کل چیز جان می‌گیرد.
class AssembleEngine extends EngineView {
  const AssembleEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<AssembleEngine> createState() => _AssembleState();
}

class _AssembleState extends ConsumerState<AssembleEngine> with EngineSounds {
  late final parts = widget.step.maps('parts');
  final Set<int> placed = {};
  final _base = GlobalKey();
  final _slots = <int, GlobalKey>{};
  int bump = 0;
  int quake = 0;
  bool get finished => placed.length == parts.length;

  GlobalKey _slot(int i) => _slots.putIfAbsent(i, GlobalKey.new);

  void _place(int i) {
    setState(() {
      placed.add(i);
      bump++;
      quake++;
    });
    good('audio/sfx/snap.mp3');
    _slot(i).currentContext?.fx(Fx.sparks, count: 14);
    _slot(i).currentContext?.fx(Fx.dust, count: 6);
    if (finished) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _base.currentContext?.fx(Fx.confetti, count: 40);
        ui(UiSound.sparkle);
      });
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1100), widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final area = Size(box.maxWidth, box.maxHeight - 124);
      final base = math.min(area.width, area.height) * .8;
      final part = math.min(area.width, area.height) * .3;
      final next = [for (var i = 0; i < parts.length; i++) i].where((i) => !placed.contains(i)).firstOrNull;
      Offset slot(int i) => Offset((parts[i]['x'] as num).toDouble() * area.width, (parts[i]['y'] as num).toDouble() * area.height);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Positioned.fill(
              bottom: 124,
              child: ShakeScene(
                trigger: quake,
                strength: 4,
                child: Stack(
                  children: [
                    Positioned(
                      left: (area.width - base) / 2,
                      top: (area.height - base) / 2,
                      child: Squash(
                        key: _base,
                        trigger: bump,
                        amount: .08,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 500),
                          transitionBuilder: (c, a) => ScaleTransition(
                            scale: CurvedAnimation(parent: a, curve: Curves.elasticOut),
                            child: c,
                          ),
                          child: finished
                              ? Idle(
                                  key: const ValueKey('r'),
                                  amount: 1.4,
                                  child: GameArt(widget.step.str('result'), size: base),
                                )
                              : Opacity(
                                  key: const ValueKey('b'),
                                  opacity: .25,
                                  child: GameArt(widget.step.str('base'), size: base),
                                ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < parts.length; i++)
                      Positioned(
                        key: _slot(i),
                        left: slot(i).dx - part / 2,
                        top: slot(i).dy - part / 2,
                        child: placed.contains(i)
                            ? (finished
                                  ? SizedBox(width: part, height: part)
                                  : PopIn(from: 1.5, child: GameArt(parts[i]['art'] as String, size: part)))
                            : DragTarget<String>(
                                onWillAcceptWithDetails: (d) => d.data == '$i' || d.data == parts[i]['art'],
                                onAcceptWithDetails: (_) => _place(i),
                                builder: (context, cand, _) => AnimatedScale(
                                  duration: const Duration(milliseconds: 160),
                                  scale: cand.isNotEmpty ? 1.15 : 1,
                                  child: HintGlow(
                                    on: hint >= 1 && i == next,
                                    child: Container(
                                      width: part,
                                      height: part,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(alpha: cand.isNotEmpty ? .85 : .45),
                                        border: Border.all(color: G.purple.withValues(alpha: .5), width: 4),
                                      ),
                                      child: Opacity(opacity: .22, child: GameArt(parts[i]['art'] as String, size: part)),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShelfProp(
                height: 118,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < parts.length; i++)
                      if (!placed.contains(i))
                        _Draggable(
                          data: '$i',
                          onStart: widget.host.touch,
                          child: Idle(seed: i + 3, child: GameArt(parts[i]['art'] as String, size: 90)),
                        ),
                  ],
                ),
              ),
            ),
            if (hint >= 3 && next != null) HintHand(from: Offset(box.maxWidth / 2, box.maxHeight - 60), to: slot(next)),
          ],
        ),
      );
    },
  );
}

/// شمردن: [count] تا را در ظرف بگذار (بکش یا بزن تا بپرد)؛ با هر دانه عدد بزرگ بالا می‌پرد.
class CountEngine extends EngineView {
  const CountEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CountEngine> createState() => _CountState();
}

class _CountState extends ConsumerState<CountEngine> with EngineSounds {
  late final int need = widget.step.integer('count', 3);
  late final int tray = need + 2;
  final Set<int> used = {};
  final Set<int> flying = {};
  final _into = GlobalKey();
  int landed = 0;

  void _drop(int i) {
    if (landed >= need || used.contains(i)) return;
    setState(() {
      used.add(i);
      landed++;
    });
    good(widget.step.opt('sound'));
    _into.currentContext?.fx(Fx.sparkle, count: 10);
    if (landed == need) {
      _into.currentContext?.fx(Fx.confetti, count: 34);
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1000), widget.host.done);
    }
  }

  void _tap(int i, BuildContext c) {
    if (used.contains(i) || flying.contains(i) || landed + flying.length >= need) return;
    widget.host.touch();
    final fx = FxScope.of(context);
    final to = _into.currentContext?.globalCenter;
    if (fx == null || to == null) return _drop(i);
    setState(() => flying.add(i));
    ui(UiSound.whoosh);
    fx.fly(
      widget.step.str('target'),
      c.globalCenter,
      to,
      size: 70,
      ms: 560,
      arc: 110,
      spin: .4,
      endScale: .6,
      onLand: () {
        if (!mounted) return;
        flying.remove(i);
        _drop(i);
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final big = math.min(box.maxWidth, box.maxHeight - 140) * .6;
      final small = math.min(76.0, (box.maxWidth - 30) / tray - 6);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: DragTarget<String>(
                    onAcceptWithDetails: (d) => _drop(int.parse(d.data)),
                    builder: (context, cand, _) => Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Squash(
                            key: _into,
                            trigger: landed,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 160),
                              scale: cand.isNotEmpty ? 1.08 : 1,
                              child: HintGlow(
                                on: hint >= 1,
                                child: GameArt(widget.step.str('into'), size: big),
                              ),
                            ),
                          ),
                          // دانه‌ها داخل ظرف
                          for (var k = 0; k < landed; k++)
                            Positioned(
                              bottom: big * .18 + (k ~/ 4) * big * .14,
                              left: null,
                              child: Transform.translate(
                                offset: Offset(((k % 4) - 1.5) * big * .17, 0),
                                child: PopIn(from: 1.6, child: GameArt(widget.step.str('target'), size: big * .24)),
                              ),
                            ),
                          if (landed > 0) Positioned(top: -10, child: _CountPop(landed)),
                          Positioned(
                            bottom: -6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(color: G.purple, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
                              child: Text('${fa(landed)} از ${fa(need)}', style: PText.button.copyWith(fontSize: 22)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ShelfProp(
                  height: 104,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (var i = 0; i < tray; i++)
                        if (used.contains(i) || flying.contains(i))
                          SizedBox(width: small, height: small)
                        else
                          Builder(
                            builder: (c) => GestureDetector(
                              onTap: () => _tap(i, c),
                              child: _Draggable(
                                data: '$i',
                                onStart: widget.host.touch,
                                child: Idle(
                                  seed: i,
                                  amount: .6,
                                  child: GameArt(widget.step.str('target'), size: small),
                                ),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
            ),
            if (hint >= 3)
              HintHand(from: Offset(box.maxWidth / 2, box.maxHeight - 50), to: Offset(box.maxWidth / 2, (box.maxHeight - 120) / 2)),
          ],
        ),
      );
    },
  );
}

/// ترتیب: به ترتیب بزن (بزرگ به کوچک، رنگ‌های چراغ، لایه‌های ساندویچ)؛ هر چیز به جای خودش پرواز می‌کند.
class OrderEngine extends EngineView {
  const OrderEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<OrderEngine> createState() => _OrderState();
}

class _OrderState extends ConsumerState<OrderEngine> with EngineSounds {
  late final items = widget.step.list('items');

  /// اگر همه یکی‌اند، اندازه ترتیب را تعیین می‌کند.
  late final bool bySize = items.toSet().length == 1;
  late final List<int> shuffled = [for (var i = 0; i < items.length; i++) i]..shuffle(math.Random(9));
  late final List<GlobalKey> slots = [for (final _ in items) GlobalKey()];
  final List<int> picked = [];
  final List<int> landed = [];
  final Map<int, int> shakes = {};

  double scaleOf(int i) => bySize ? 1 - i * (.5 / items.length) : 1;

  void _tap(int i, BuildContext c) {
    if (picked.contains(i)) return;
    // دو چیز یکسان (نان اول و آخر ساندویچ) هر کدام می‌تواند جای بعدی باشد.
    final want = picked.length;
    if (i != want && items[i] != items[want]) {
      setState(() => shakes[i] = (shakes[i] ?? 0) + 1);
      bad();
      return;
    }
    setState(() => picked.add(i));
    good(widget.step.opt('sound'));
    final slot = slots[want];
    void land() {
      if (!mounted) return;
      setState(() => landed.add(i));
      slot.currentContext?.fx(Fx.sparkle, count: 10);
      ui(UiSound.pop);
      if (landed.length == items.length) {
        for (final k in slots) {
          k.currentContext?.fx(Fx.confetti, count: 10);
        }
        widget.host.points(5);
        Future.delayed(_done, widget.host.done);
      }
    }

    final fx = FxScope.of(context);
    final to = slot.currentContext?.globalCenter;
    if (fx == null || to == null) return land();
    fx.fly(items[i], c.globalCenter, to, size: 80 * scaleOf(i), ms: 520, arc: 80, endScale: 1, onLand: land);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth / (items.length + .6), box.maxHeight * .3);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) {
          final want = picked.length;
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var k = 0; k < items.length; k++)
                        Container(
                          key: slots[k],
                          width: size,
                          height: size * 1.1,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: k == want && hint >= 1 ? .95 : .6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: k == want ? G.orange : G.purple.withValues(alpha: .3), width: k == want ? 4 : 3),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: k < landed.length
                              ? PopIn(
                                  from: 1.4,
                                  child: Transform.scale(
                                    scale: scaleOf(landed[k]),
                                    alignment: Alignment.bottomCenter,
                                    child: GameArt(items[landed[k]], size: size),
                                  ),
                                )
                              : Center(
                                  child: Text(fa(k + 1), style: PText.display.copyWith(color: G.purple.withValues(alpha: .3))),
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              ShelfProp(
                height: size + 26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final i in shuffled)
                      picked.contains(i)
                          ? SizedBox(width: size, height: size)
                          : Builder(
                              builder: (c) => GestureDetector(
                                onTap: () => _tap(i, c),
                                child: Shake(
                                  trigger: shakes[i] ?? 0,
                                  child: Idle(
                                    seed: i,
                                    amount: .6,
                                    child: HintGlow(
                                      on: hint >= 1 && want < items.length && (i == want || items[i] == items[want]),
                                      child: Transform.scale(
                                        scale: scaleOf(i),
                                        alignment: Alignment.bottomCenter,
                                        child: GameArt(items[i], size: size),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// ریختن: ظرف را نگه دار تا کج شود و مایع با موج تا خط بالا بیاید، بعد رها کن.
class PourEngine extends EngineView {
  const PourEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<PourEngine> createState() => _PourState();
}

class _PourState extends ConsumerState<PourEngine> with EngineSounds, SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _glass = GlobalKey();
  double level = 0;
  double phase = 0;
  bool pouring = false;
  bool finished = false;
  int shake = 0;
  Duration _last = Duration.zero;
  double _splash = 0;
  static const line = .72;
  double get tol => widget.host.age.minAge <= 2 ? .14 : .09;
  late final Color color = G.hex(widget.step.str('color', '#4FC3F7'));

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, .05);
    _last = now;
    setState(() {
      phase += dt * (pouring ? 9 : 3);
      if (pouring) {
        level = math.min(1, level + dt * .3);
        _splash += dt;
        if (_splash > .12) {
          _splash = 0;
          final g = _glass.currentContext;
          if (g != null) {
            final box = g.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              final top = box.localToGlobal(Offset(box.size.width / 2, box.size.height * (1 - level)));
              FxScope.of(context)?.burst(top, Fx.drops, count: 3, color: color, spread: .4);
            }
          }
        }
        if (level >= 1) _stop();
      }
    });
  }

  void _start() {
    if (finished) return;
    setState(() => pouring = true);
    sfx(widget.step.opt('sound') ?? 'audio/sfx/pour.mp3');
    widget.host.touch();
  }

  void _stop() {
    if (!pouring || finished) return;
    setState(() => pouring = false);
    if ((level - line).abs() <= tol) {
      setState(() => finished = true);
      _glass.currentContext?.fx(Fx.confetti, count: 30);
      good('audio/ui/success.mp3');
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    } else if (level > line + tol) {
      // سر رفت: می‌ریزد و دوباره از اول.
      _glass.currentContext?.fx(Fx.drops, count: 24, color: color);
      sfx('audio/sfx/splash.mp3');
      setState(() {
        shake++;
        level = 0;
      });
      bad();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final h = math.min(box.maxHeight * .58, 260.0);
      final w = h * .7;
      final srcSize = h * .55;
      final srcRight = box.maxWidth * .1;
      final glassLeft = box.maxWidth / 2 - w / 2;
      final glassTop = box.maxHeight - 30 - h * .82;
      final liquidTop = glassTop + h * .82 * (1 - level);
      final spoutX = box.maxWidth - srcRight - srcSize * .9;
      final spoutY = srcSize * .55;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            // جریان مایع از لوله تا سطح
            if (pouring)
              Positioned(
                left: spoutX - 9,
                top: spoutY,
                child: CustomPaint(size: Size(18, math.max(0, liquidTop - spoutY)), painter: _StreamPainter(color, phase)),
              ),
            Positioned(
              left: glassLeft,
              top: glassTop,
              child: Shake(
                trigger: shake,
                child: Squash(
                  trigger: finished ? 1 : 0,
                  child: Container(
                    key: _glass,
                    width: w,
                    height: h * .82,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .5),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30), top: Radius.circular(10)),
                      border: Border.all(color: Colors.white, width: 5),
                      boxShadow: G.soft(),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: LiquidPainter(level: level, color: color, phase: phase, radius: 26),
                          ),
                        ),
                        Align(
                          alignment: const Alignment(0, 1 - line * 2),
                          child: Row(
                            children: [
                              Expanded(child: Container(height: 5, color: hint >= 1 ? const Color(0xFFFFB300) : G.purple)),
                              const Icon(Icons.flag_rounded, color: G.red, size: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: glassLeft - w * .3,
              bottom: 0,
              child: Opacity(opacity: .9, child: GroundShadow(width: w * 1.6)),
            ),
            Positioned(
              top: 0,
              right: srcRight,
              child: Listener(
                onPointerDown: (_) => _start(),
                onPointerUp: (_) => _stop(),
                onPointerCancel: (_) => _stop(),
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutBack,
                  turns: pouring ? -.14 : 0,
                  child: HintGlow(
                    on: hint >= 1 && !finished,
                    child: Idle(
                      enabled: !pouring,
                      child: GameArt(widget.step.str('source'), size: srcSize),
                    ),
                  ),
                ),
              ),
            ),
            if (finished)
              Positioned(
                left: glassLeft + w * .55,
                top: glassTop - h * .3,
                child: PopIn(child: GameArt(widget.step.str('into'), size: h * .4)),
              ),
            Positioned(
              bottom: 0,
              left: 8,
              child: Text(
                finished ? 'آفرین!' : (pouring ? 'نگه دار... تا خط!' : 'نگه دار و رها کن'),
                style: PText.heading.copyWith(color: G.purple),
              ),
            ),
            if (hint >= 3 && !finished) HintHand(from: Offset(box.maxWidth - srcRight - srcSize / 2, srcSize * .5)),
          ],
        ),
      );
    },
  );
}

class _StreamPainter extends CustomPainter {
  _StreamPainter(this.color, this.phase);

  final Color color;
  final double phase;

  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(s.width * .2, 0);
    for (var y = 0.0; y <= s.height; y += 6) {
      p.lineTo(s.width * .2 + math.sin(y / 14 + phase) * 2, y);
    }
    for (var y = s.height; y >= 0; y -= 6) {
      p.lineTo(s.width * .8 + math.sin(y / 14 + phase) * 2, y);
    }
    canvas.drawPath(p..close(), Paint()..color = color.withValues(alpha: .9));
    canvas.drawLine(
      Offset(s.width * .42, 0),
      Offset(s.width * .42, s.height),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_StreamPainter old) => true;
}

/// ترکیب رنگ: دو رنگ درست را در کاسه بریز، بعد با انگشت هم بزن تا رنگ تازه پیدا شود.
class MixEngine extends EngineView {
  const MixEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<MixEngine> createState() => _MixState();
}

class _MixState extends ConsumerState<MixEngine> with EngineSounds, SingleTickerProviderStateMixin {
  late final a = G.hex(widget.step.str('a'));
  late final b = G.hex(widget.step.str('b'));
  late final result = G.hex(widget.step.str('result'));
  late final List<Color> pots = [a, b, const Color(0xFF9C27B0), const Color(0xFF795548)]..shuffle(math.Random(4));
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  final _bowl = GlobalKey();
  final List<Color> inBowl = [];
  Color? tilting;
  bool finished = false;
  int shake = 0;
  double stir = 0;
  double angle = 0;
  double? _lastA;
  int _stirTick = 0;

  bool get stirring => inBowl.length == 2 && !finished;

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  void _add(Color c) {
    if (finished || inBowl.contains(c) || inBowl.length >= 2 || tilting != null) return;
    if (c != a && c != b) {
      setState(() {
        shake++;
        inBowl.clear();
      });
      bad();
      return;
    }
    // کوزه کج می‌شود و رنگ می‌ریزد.
    setState(() => tilting = c);
    sfx('audio/sfx/pour.mp3');
    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        tilting = null;
        inBowl.add(c);
      });
      good('audio/sfx/splash.mp3');
      _bowl.currentContext?.fx(Fx.drops, count: 14, color: c);
      widget.host.touch();
    });
  }

  void _stir(Offset local, Size size) {
    if (!stirring) return;
    final c = size.center(Offset.zero);
    final ang = math.atan2(local.dy - c.dy, local.dx - c.dx);
    if (_lastA != null) {
      var d = ang - _lastA!;
      if (d > math.pi) d -= math.pi * 2;
      if (d < -math.pi) d += math.pi * 2;
      setState(() {
        angle += d;
        stir = math.min(1, stir + d.abs() / (math.pi * 4));
      });
      final tick = (stir * 8).floor();
      if (tick != _stirTick) {
        _stirTick = tick;
        sfx('audio/sfx/stir.mp3');
        _bowl.currentContext?.fx(Fx.bubbles, count: 4, color: Color.lerp(a, result, stir));
        widget.host.touch();
      }
      if (stir >= 1) {
        setState(() => finished = true);
        _bowl.currentContext?.fx(Fx.confetti, count: 40);
        good('audio/ui/success.mp3');
        widget.host.points(5);
        Future.delayed(const Duration(milliseconds: 1400), widget.host.done);
      }
    }
    _lastA = ang;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final bowl = math.min(box.maxWidth, box.maxHeight) * .5;
      final mixed = inBowl.isEmpty ? Colors.white : (inBowl.length == 1 ? inBowl.first : Color.lerp(Color.lerp(a, b, .5), result, stir)!);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Shake(
                      trigger: shake,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onPanStart: (d) => _lastA = null,
                            onPanUpdate: (d) => _stir(d.localPosition, Size(bowl, bowl * .62)),
                            child: Squash(
                              key: _bowl,
                              trigger: inBowl.length + (finished ? 1 : 0),
                              amount: .12,
                              child: AnimatedBuilder(
                                animation: _wave,
                                builder: (context, _) => SizedBox(
                                  width: bowl,
                                  height: bowl * .62,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                            bottom: Radius.circular(bowl * .4),
                                            top: const Radius.circular(14),
                                          ),
                                          border: Border.all(color: Colors.white, width: 8),
                                          boxShadow: G.soft(),
                                        ),
                                      ),
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: CustomPaint(
                                            painter: LiquidPainter(
                                              level: inBowl.isEmpty ? 0 : (inBowl.length == 1 ? .45 : .8),
                                              color: mixed,
                                              phase: _wave.value * math.pi * 2,
                                              radius: bowl * .36,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // قبل از هم زدن: دو رنگ هنوز جدا پیداست.
                                      if (stirring)
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: SwirlPainter(
                                              angle: angle,
                                              color: stir < .5 ? b : Colors.white,
                                              strength: 1 - stir * .6,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (finished)
                            PopIn(child: SectionPill(widget.step.str('resultName'), color: result))
                          else if (stirring)
                            PopIn(
                              child: Text('با انگشت هم بزن! 🌀', style: PText.title.copyWith(color: G.purple)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (final (k, c) in pots.indexed)
                      GestureDetector(
                        onTap: () => _add(c),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 250),
                          turns: tilting == c ? -.12 : 0,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 200),
                            opacity: inBowl.contains(c) ? .3 : 1,
                            child: Idle(
                              seed: k,
                              amount: .5,
                              child: HintGlow(
                                on: hint >= 1 && (c == a || c == b) && !inBowl.contains(c),
                                child: _Jar(color: c),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
            if (hint >= 3 && stirring) Positioned(left: box.maxWidth / 2 - 30, top: box.maxHeight * .25, child: const _CircleHint()),
          ],
        ),
      );
    },
  );
}

class _Jar extends StatelessWidget {
  const _Jar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 40,
        height: 14,
        decoration: BoxDecoration(color: G.shade(color, .25), borderRadius: BorderRadius.circular(6)),
      ),
      Container(
        width: 64,
        height: 74,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [G.tint(color, .25), color, G.shade(color, .1)]),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(14), bottom: Radius.circular(26)),
          border: Border.all(color: Colors.white, width: 5),
          boxShadow: G.soft(),
        ),
      ),
    ],
  );
}

/// دستی که دایره می‌کشد (برای هم زدن).
class _CircleHint extends StatefulWidget {
  const _CircleHint();

  @override
  State<_CircleHint> createState() => _CircleHintState();
}

class _CircleHintState extends State<_CircleHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

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
        return Transform.translate(
          offset: Offset(math.cos(a) * 50, math.sin(a) * 26),
          child: const Text('👆', style: TextStyle(fontSize: 50)),
        );
      },
    ),
  );
}

/// رنگ کردن: قلم‌مو را در رنگ بزن و روی لکه‌ها بزن؛ رنگ پاشیده می‌شود و لکه با فنر پهن می‌شود.
class PaintEngine extends EngineView {
  const PaintEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<PaintEngine> createState() => _PaintState();
}

class _PaintState extends ConsumerState<PaintEngine> with EngineSounds {
  static const palette = [Color(0xFFF44336), Color(0xFFFF9800), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0)];
  late final int areas = widget.step.integer('areas', 4);
  late final List<Offset> spots = [
    for (var i = 0; i < areas; i++)
      Offset(.5 + math.cos(i / areas * math.pi * 2 - math.pi / 2) * .3, .5 + math.sin(i / areas * math.pi * 2 - math.pi / 2) * .3),
  ];
  final Map<int, Color> painted = {};
  final _art = GlobalKey();
  Color brush = palette.first;
  int dip = 0;

  void _paint(int i, BuildContext c) {
    final again = painted.containsKey(i);
    setState(() => painted[i] = brush);
    c.fx(Fx.drops, count: 12, color: brush);
    if (again) {
      ui(UiSound.pop);
      return;
    }
    good('audio/sfx/rustle.mp3');
    if (painted.length == areas) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _art.currentContext?.fx(Fx.confetti, count: 40);
        ui(UiSound.sparkle);
      });
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1100), widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight - 96);
      final dot = s * .22;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) {
          final next = [for (var i = 0; i < areas; i++) i].where((i) => !painted.containsKey(i)).firstOrNull;
          return Column(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: s,
                    height: s,
                    child: Stack(
                      children: [
                        Center(
                          child: Squash(
                            key: _art,
                            trigger: painted.length == areas ? 1 : 0,
                            child: Idle(
                              enabled: painted.length == areas,
                              amount: 1.5,
                              child: GameArt(widget.step.str('target'), size: s * .72),
                            ),
                          ),
                        ),
                        for (var i = 0; i < areas; i++)
                          Positioned(
                            left: spots[i].dx * s - dot / 2,
                            top: spots[i].dy * s - dot / 2,
                            child: Builder(
                              builder: (c) => GestureDetector(
                                onTap: () => _paint(i, c),
                                child: HintGlow(
                                  on: hint >= 1 && i == next,
                                  child: painted.containsKey(i)
                                      ? PopIn(
                                          key: ValueKey(painted[i]),
                                          from: .2,
                                          child: CustomPaint(size: Size(dot, dot), painter: _SplatPainter(painted[i]!, i)),
                                        )
                                      : Container(
                                          width: dot,
                                          height: dot,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: .7),
                                            border: Border.all(color: Colors.white, width: 4),
                                            boxShadow: G.soft(),
                                          ),
                                          child: Icon(Icons.brush_rounded, color: brush, size: dot * .45),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        if (hint >= 3 && next != null) HintHand(from: Offset(spots[next].dx * s, spots[next].dy * s)),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in palette)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          brush = c;
                          dip++;
                        });
                        ui(UiSound.tap);
                        widget.host.touch();
                      },
                      child: Squash(
                        trigger: c == brush ? dip : 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutBack,
                          width: c == brush ? 60 : 46,
                          height: c == brush ? 60 : 46,
                          margin: EdgeInsets.fromLTRB(4, c == brush ? 2 : 14, 4, 10),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(center: const Alignment(-.3, -.4), colors: [G.tint(c, .35), c]),
                            border: Border.all(color: Colors.white, width: c == brush ? 6 : 3),
                            boxShadow: G.soft(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

/// لکه‌ی رنگ با لبه‌های نامنظم و چند قطره‌ی دور.
class _SplatPainter extends CustomPainter {
  _SplatPainter(this.color, this.seed);

  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size s) {
    final rnd = math.Random(seed * 7 + 1);
    final c = s.center(Offset.zero);
    final r = s.width * .42;
    final p = Path();
    const n = 14;
    for (var k = 0; k <= n; k++) {
      final a = k / n * math.pi * 2;
      final rr = r * (k.isEven ? .85 + rnd.nextDouble() * .2 : .65 + rnd.nextDouble() * .15);
      final o = c + Offset(math.cos(a), math.sin(a)) * rr;
      k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    final paint = Paint()..color = color;
    canvas.drawPath(p..close(), paint);
    for (var k = 0; k < 4; k++) {
      final a = rnd.nextDouble() * math.pi * 2;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 1.1, r * (.08 + rnd.nextDouble() * .08), paint);
    }
    canvas.drawCircle(c + Offset(-r * .3, -r * .3), r * .16, Paint()..color = Colors.white.withValues(alpha: .45));
  }

  @override
  bool shouldRepaint(_SplatPainter old) => old.color != color;
}

/// پازل: تکه‌های تصویر را سر جایشان بگذار؛ هر تکه با تق می‌نشیند و آخرش تصویر جان می‌گیرد.
class PuzzleEngine extends EngineView {
  const PuzzleEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<PuzzleEngine> createState() => _PuzzleState();
}

class _PuzzleState extends ConsumerState<PuzzleEngine> with EngineSounds {
  late final (int, int) grid = switch (widget.host.age.minAge) {
    <= 2 => (2, 2),
    <= 4 => (2, 3),
    _ => (3, 3),
  };
  int get n => grid.$1 * grid.$2;
  late final List<int> tray = [for (var i = 0; i < n; i++) i]..shuffle(math.Random(6));
  late final List<GlobalKey> cells = [for (var i = 0; i < n; i++) GlobalKey()];
  final _board = GlobalKey();
  final Set<int> placed = {};
  bool get finished => placed.length == n;

  Widget _piece(int i, double cell) {
    final (rows, cols) = grid;
    final r = i ~/ cols, c = i % cols;
    return SizedBox(
      width: cell,
      height: cell,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cell * .08),
        child: OverflowBox(
          maxWidth: cell * cols,
          maxHeight: cell * rows,
          alignment: Alignment(cols == 1 ? 0 : -1 + 2 * c / (cols - 1), rows == 1 ? 0 : -1 + 2 * r / (rows - 1)),
          child: GameArt(widget.step.str('target'), size: cell * math.max(rows, cols)),
        ),
      ),
    );
  }

  void _place(int i) {
    setState(() => placed.add(i));
    good('audio/sfx/snap.mp3');
    cells[i].currentContext?.fx(Fx.sparkle, count: 10);
    if (finished) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        _board.currentContext?.fx(Fx.confetti, count: 40);
        ui(UiSound.sparkle);
      });
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1100), widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final (rows, cols) = grid;
      final cell = math.min((box.maxWidth - 20) / cols, (box.maxHeight - 130) / rows) * .9;
      final small = math.min(78.0, (box.maxWidth - 30) / n - 6);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) {
          final next = tray.where((i) => !placed.contains(i)).firstOrNull;
          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Squash(
                        key: _board,
                        trigger: finished ? 1 : 0,
                        amount: .1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: G.soft(),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: Stack(
                            children: [
                              // سایه‌ی کم‌رنگ کل تصویر برای راهنمایی
                              Positioned.fill(
                                child: Opacity(
                                  opacity: .12,
                                  child: FittedBox(child: GameArt(widget.step.str('target'), size: cell * math.max(rows, cols))),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var r = 0; r < rows; r++)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        for (var c = 0; c < cols; c++)
                                          DragTarget<String>(
                                            key: cells[r * cols + c],
                                            onWillAcceptWithDetails: (d) => d.data == '${r * cols + c}',
                                            onAcceptWithDetails: (_) => _place(r * cols + c),
                                            builder: (context, cand, rejected) {
                                              final i = r * cols + c;
                                              return AnimatedContainer(
                                                duration: const Duration(milliseconds: 150),
                                                width: cell,
                                                height: cell,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: hint >= 1 && i == next
                                                        ? const Color(0xFFFFB300)
                                                        : (finished ? Colors.transparent : G.line),
                                                    width: hint >= 1 && i == next ? 4 : 2,
                                                  ),
                                                  color: rejected.isNotEmpty ? G.tint(G.red, .7) : Colors.transparent,
                                                ),
                                                child: placed.contains(i) ? PopIn(from: 1.3, child: _piece(i, cell)) : null,
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  ShelfProp(
                    height: small + 30,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        for (final i in tray)
                          if (!placed.contains(i))
                            Draggable<String>(
                              data: '$i',
                              onDragStarted: widget.host.touch,
                              onDraggableCanceled: (_, _) => ui(UiSound.softNo),
                              feedback: Transform.rotate(angle: -.06, child: _piece(i, cell)),
                              childWhenDragging: SizedBox(width: small, height: small),
                              child: Idle(
                                seed: i,
                                amount: .4,
                                child: FittedBox(child: _piece(i, small)),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hint >= 3 && next != null)
                HintHand(
                  from: Offset(box.maxWidth / 2, box.maxHeight - 50),
                  to: Offset(
                    box.maxWidth / 2 + (next % cols - (cols - 1) / 2) * cell,
                    (box.maxHeight - 110) / 2 + (next ~/ cols - (rows - 1) / 2) * cell,
                  ),
                ),
            ],
          );
        },
      );
    },
  );
}

/// دنبال کردن مسیر: شیء را با انگشت روی جاده ببر؛ پشت سرش گرد و خاک و برق می‌ماند.
class TraceEngine extends EngineView {
  const TraceEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<TraceEngine> createState() => _TraceState();
}

class _TraceState extends ConsumerState<TraceEngine> with EngineSounds {
  final _area = GlobalKey();
  double progress = 0;
  bool finished = false;
  int _tick = 0;
  double heading = 0;

  Offset _at(double t, Size s) {
    final x = s.width * (.9 - .8 * t);
    final y = switch (widget.step.str('shape', 'wave')) {
      'zigzag' => s.height * (.5 + ((t * 4) % 1 < .5 ? (t * 4 % 1) * 2 - .5 : 1.5 - (t * 4 % 1) * 2) * .5),
      _ => s.height * (.5 + math.sin(t * math.pi * 2) * .28),
    };
    return Offset(x, y);
  }

  void _drag(Offset p, Size s) {
    if (finished) return;
    // نزدیک‌ترین نقطه‌ی جلوتر روی مسیر (تا کمی جلوتر از جای فعلی).
    var best = progress, bestD = double.infinity;
    for (var t = progress; t <= math.min(1, progress + .12); t += .005) {
      final d = (p - _at(t, s)).distance;
      if (d < bestD) {
        bestD = d;
        best = t;
      }
    }
    if (bestD < 74 && best > progress) {
      final from = _at(progress, s), to = _at(best, s);
      setState(() {
        progress = best;
        if ((to - from).distance > .5) heading = math.atan2(to.dy - from.dy, from.dx - to.dx);
      });
      final box = _area.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) FxScope.of(context)?.burst(box.localToGlobal(from), Fx.dust, count: 2, spread: .3);
      final tick = (progress * 10).floor();
      if (tick != _tick) {
        _tick = tick;
        widget.host.right();
        sfx('audio/ui/pop.mp3');
        if (box != null) FxScope.of(context)?.burst(box.localToGlobal(to), Fx.sparkle, count: 5);
      }
      if (progress >= .98) {
        finished = true;
        if (box != null) FxScope.of(context)?.burst(box.localToGlobal(_at(1, s)), Fx.confetti, count: 40);
        ui(UiSound.success);
        widget.host.points(5);
        Future.delayed(_done, widget.host.done);
      }
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final pos = _at(progress, s);
      const size = 96.0;
      return GestureDetector(
        key: _area,
        onPanUpdate: (d) => _drag(d.localPosition, s),
        onPanDown: (d) => _drag(d.localPosition, s),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            children: [
              Container(color: Colors.transparent),
              CustomPaint(
                size: s,
                painter: _PathPainter(at: (t) => _at(t, s), progress: progress, glow: hint >= 1),
              ),
              Positioned(
                left: _at(1, s).dx - 30,
                top: _at(1, s).dy - 56,
                child: Squash(
                  trigger: finished ? 1 : 0,
                  child: const Icon(Icons.flag_rounded, color: G.red, size: 60),
                ),
              ),
              Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                child: HintGlow(
                  on: hint >= 1 && progress == 0,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 120),
                    turns: (heading.clamp(-.6, .6)) / (math.pi * 2),
                    child: Idle(amount: .6, child: GameArt(widget.step.str('target'), size: size)),
                  ),
                ),
              ),
              if (hint >= 3 && !finished) HintHand(from: pos, to: _at(math.min(1, progress + .25), s)),
            ],
          ),
        ),
      );
    },
  );
}

class _PathPainter extends CustomPainter {
  _PathPainter({required this.at, required this.progress, required this.glow});

  final Offset Function(double) at;
  final double progress;
  final bool glow;

  @override
  void paint(Canvas canvas, Size s) {
    Path path(double from, double to) {
      final p = Path()..moveTo(at(from).dx, at(from).dy);
      for (var t = from + .01; t <= to + .0001; t += .01) {
        p.lineTo(at(t).dx, at(t).dy);
      }
      return p;
    }

    Paint stroke(Color c, double w) => Paint()
      ..color = c
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final all = path(0, 1);
    canvas.drawPath(all, stroke(const Color(0xFF9CCC65), 70));
    canvas.drawPath(all, stroke(const Color(0xFFBCAAA4), 54));
    canvas.drawPath(all, stroke(const Color(0xFFD7CCC8), 44));
    // خط‌چین وسط جاده
    final dots = Paint()..color = glow ? const Color(0xFFFFB300) : Colors.white;
    for (var t = progress; t <= 1; t += .04) {
      canvas.drawCircle(at(t), glow ? 7 : 5, dots);
    }
    if (progress > 0) canvas.drawPath(path(0, progress), stroke(G.green, 16));
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.progress != progress || old.glow != glow;
}
