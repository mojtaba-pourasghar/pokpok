import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../data/models/models.dart';
import '../../ui/clay.dart';
import '../../ui/fx.dart';
import 'engine.dart';
import 'props.dart';
import 'tap_engines.dart';

/// بازی‌های پرتحرک: گرفتن، غذا دادن، روی هم چیدن، فوت کردن، رانندگی، وصل کردن نقطه‌ها، کارت حافظه، ضربه‌ی سریع.

const _done = Duration(milliseconds: 900);

bool _small(EngineHost h) => h.age == AgeBand.toddler;

Offset _globalOf(GlobalKey k, Offset local) {
  final box = k.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.hasSize) return local;
  return box.localToGlobal(local);
}

/// گرفتن: چیزها از بالا می‌افتند؛ سبد را با انگشت جابه‌جا کن و فقط چیزهای درست را بگیر.
class CatchEngine extends EngineView {
  const CatchEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CatchEngine> createState() => _CatchState();
}

class _Faller {
  _Faller(this.art, this.good, this.x, this.speed, this.spin);

  final String art;
  final bool good;
  final double x;
  final double speed;
  final double spin;
  double y = -.1;
}

class _CatchState extends ConsumerState<CatchEngine> with EngineSounds, TickerProviderStateMixin, FrameTicker {
  late final int need = widget.host.scaled(widget.step.integer('count', 5));
  late final String target = widget.step.str('target');
  late final List<String> distract = widget.step.list('distract');
  final _area = GlobalKey();
  final _rnd = math.Random(11);
  final List<_Faller> falling = [];
  final List<String> caught = [];
  double basket = .5;
  double _spawn = .3;
  double time = 0;
  int bump = 0;
  int shake = 0;
  bool finished = false;

  static const line = .8;

  @override
  void initState() {
    super.initState();
    startTicker();
  }

  @override
  void onTick(double dt) {
    if (finished) return;
    time += dt;
    _spawn -= dt;
    final slow = _small(widget.host) ? .7 : 1.0;
    if (_spawn <= 0 && falling.length < 3) {
      _spawn = (_small(widget.host) ? 1.5 : 1.1) + _rnd.nextDouble() * .4;
      final good = distract.isEmpty || _rnd.nextDouble() < .65;
      final x = .12 + _rnd.nextDouble() * .76;
      falling.add(
        _Faller(
          good ? target : distract[_rnd.nextInt(distract.length)],
          good,
          x,
          (.22 + _rnd.nextDouble() * .1) * slow,
          _rnd.nextDouble() * 2 - 1,
        ),
      );
    }
    final size = (_area.currentContext?.findRenderObject() as RenderBox?)?.size;
    for (final f in [...falling]) {
      final before = f.y;
      f.y += f.speed * dt;
      if (before < line && f.y >= line && (f.x - basket).abs() < .15) {
        falling.remove(f);
        _caught(f, size);
      } else if (f.y > 1.1) {
        falling.remove(f);
      }
    }
    setState(() {});
  }

  void _caught(_Faller f, Size? size) {
    final at = size == null ? null : _globalOf(_area, Offset(basket * size.width, line * size.height));
    if (!f.good) {
      shake++;
      if (at != null) FxScope.of(context)?.burst(at, Fx.dust, count: 10);
      bad();
      return;
    }
    caught.add(f.art);
    bump++;
    if (at != null) FxScope.of(context)?.burst(at, Fx.sparkle, count: 10);
    good(widget.step.opt('sound'));
    if (caught.length >= need) {
      finished = true;
      if (at != null) FxScope.of(context)?.burst(at, Fx.confetti, count: 40);
      ui(UiSound.success);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  void _move(double localX, double width) {
    widget.host.touch();
    setState(() => basket = (localX / width).clamp(.1, .9));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final item = math.min(w, h) * .17;
      final bw = math.min(w * .32, 160.0);
      final nextGood = falling.where((f) => f.good).fold<_Faller?>(null, (a, f) => a == null || f.y > a.y ? f : a);
      return GestureDetector(
        key: _area,
        behavior: HitTestBehavior.opaque,
        onPanDown: (d) => _move(d.localPosition.dx, w),
        onPanUpdate: (d) => _move(d.localPosition.dx, w),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => Stack(
            clipBehavior: Clip.none,
            children: [
              for (final f in falling)
                Positioned(
                  left: f.x * w - item / 2,
                  top: f.y * h - item / 2,
                  child: Transform.rotate(
                    angle: f.spin * time * 2,
                    child: HintGlow(
                      on: hint >= 1 && f == nextGood,
                      child: GameArt(f.art, size: item),
                    ),
                  ),
                ),
              Positioned(
                left: basket * w - bw / 2,
                top: line * h - bw * .35,
                child: Shake(
                  trigger: shake,
                  child: BasketProp(width: bw, items: caught.take(8).toList(), bump: bump, label: '${fa(caught.length)}/${fa(need)}'),
                ),
              ),
              if (caught.isEmpty && hint < 3)
                Positioned(
                  left: basket * w - 25,
                  top: line * h + bw * .45,
                  child: const IgnorePointer(child: _SideArrows()),
                ),
              if (hint >= 3 && nextGood != null)
                HintHand(from: Offset(basket * w, line * h + 20), to: Offset(nextGood.x * w, line * h + 20)),
            ],
          ),
        ),
      );
    },
  );
}

class _SideArrows extends StatelessWidget {
  const _SideArrows();

  @override
  Widget build(BuildContext context) => const Idle(amount: 2, child: Text('⬅️ ➡️', style: TextStyle(fontSize: 26)));
}

/// غذا دادن: دوست چیزی می‌خواهد؛ همان را از بشقاب به دهانش ببر (بکش یا بزن). هر لقمه ملچ‌ملوچ و قلب.
class FeedEngine extends EngineView {
  const FeedEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<FeedEngine> createState() => _FeedState();
}

class _FeedState extends ConsumerState<FeedEngine> with EngineSounds {
  late final List<String> wants = () {
    final f = widget.step.list('food');
    final n = widget.host.scaled(widget.step.integer('count', math.max(3, f.length)));
    return [for (var i = 0; i < n; i++) f.isEmpty ? widget.step.str('target') : f[i % f.length]];
  }();
  late final List<String> plate = [...wants.toSet(), ...widget.step.list('distract')]..shuffle(math.Random(3));
  final _mouth = GlobalKey();
  int fed = 0;
  int chew = 0;
  int no = 0;
  bool open = false;
  bool flying = false;

  String? get want => fed < wants.length ? wants[fed] : null;

  void _eat(String id) {
    final w = want;
    if (w == null) return;
    if (id != w) {
      setState(() => no++);
      bad();
      return;
    }
    setState(() {
      fed++;
      chew++;
      open = false;
    });
    good(widget.host.data.items[id]?.sound ?? widget.step.opt('sound') ?? 'audio/sfx/crunch.mp3');
    _mouth.currentContext?.fx(Fx.crumbs, count: 12);
    _mouth.currentContext?.fx(Fx.hearts, count: 4);
    if (fed == wants.length) {
      _mouth.currentContext?.fx(Fx.hearts, count: 16);
      ui(UiSound.success);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  void _tap(String id, BuildContext at) {
    if (flying || want == null) return;
    widget.host.touch();
    final fx = FxScope.of(context);
    final to = _mouth.currentContext?.globalCenter;
    if (fx == null || to == null) return _eat(id);
    setState(() {
      flying = true;
      open = true;
    });
    ui(UiSound.whoosh);
    fx.fly(
      id,
      at.globalCenter,
      to,
      size: 80,
      ms: 520,
      arc: 100,
      endScale: .4,
      onLand: () {
        if (!mounted) return;
        flying = false;
        _eat(id);
      },
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      final friend = widget.step.str('friend', 'popo');
      final small = math.min(84.0, (box.maxWidth - 40) / math.max(plate.length, 1) - 8);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Column(
          children: [
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  DragTarget<String>(
                    onWillAcceptWithDetails: (_) {
                      setState(() => open = true);
                      return true;
                    },
                    onLeave: (_) => setState(() => open = false),
                    onAcceptWithDetails: (d) => _eat(d.data),
                    builder: (context, cand, _) => Shake(
                      trigger: no,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // چیزی که می‌خواهد
                          if (want != null)
                            PopIn(
                              key: ValueKey(fed),
                              child: Idle(
                                amount: 1.2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: hint >= 1 ? const Color(0xFFFFB300) : Colors.white, width: 3),
                                    boxShadow: G.soft(),
                                  ),
                                  child: GameArt(want!, size: s * .16),
                                ),
                              ),
                            )
                          else
                            PopIn(
                              child: Icon(Icons.favorite_rounded, color: G.pink, size: s * .14),
                            ),
                          const SizedBox(height: 6),
                          Squash(
                            key: _mouth,
                            trigger: chew,
                            amount: .3,
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 180),
                              scale: open || cand.isNotEmpty ? 1.12 : 1,
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: [
                                  Idle(amount: .8, child: GameArt(friend, size: s * .46)),
                                  if (open || cand.isNotEmpty)
                                    const Positioned(
                                      top: -10,
                                      right: -10,
                                      child: PopIn(child: Text('😋', style: TextStyle(fontSize: 40))),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          GroundShadow(width: s * .3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ShelfProp(
              height: small + 30,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (k, id) in plate.indexed)
                    Builder(
                      builder: (c) => GestureDetector(
                        onTap: () => _tap(id, c),
                        child: Draggable<String>(
                          data: id,
                          onDragStarted: widget.host.touch,
                          feedback: Transform.rotate(angle: -.1, child: GameArt(id, size: small * 1.2)),
                          childWhenDragging: Opacity(opacity: .3, child: GameArt(id, size: small)),
                          child: Idle(
                            seed: k,
                            amount: .5,
                            child: HintGlow(
                              on: hint >= 1 && id == want,
                              child: GameArt(id, size: small),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// روی هم چیدن: جرثقیل تکه را چپ و راست می‌برد؛ وقتی بالای برج است بزن تا بیفتد.
class StackEngine extends EngineView {
  const StackEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<StackEngine> createState() => _StackState();
}

class _StackState extends ConsumerState<StackEngine> with EngineSounds, TickerProviderStateMixin, FrameTicker {
  late final int need = widget.host.scaled(widget.step.integer('count', 5));
  late final String block = widget.step.str('target');
  final _area = GlobalKey();
  final List<double> tower = [];
  double t = 0;
  double hook = .5;
  double? dropX;
  double dropY = 0;
  double? missX;
  double missY = 0;
  double missRot = 0;
  int bump = 0;
  bool finished = false;

  double get speed => _small(widget.host) ? 1.1 : 1.6;
  double get tol => _small(widget.host) ? .2 : .14;

  @override
  void initState() {
    super.initState();
    startTicker();
  }

  @override
  void onTick(double dt) {
    t += dt;
    if (dropX == null && !finished) hook = .5 + math.sin(t * speed) * .32;
    if (dropX != null) dropY += dt * 2.6;
    if (missX != null) {
      missY += dt * 2;
      missRot += dt * 6;
      if (missY > 1.4) missX = null;
    }
    setState(() {});
  }

  void _drop() {
    if (dropX != null || finished) return;
    widget.host.touch();
    ui(UiSound.whoosh);
    setState(() {
      dropX = hook;
      dropY = 0;
    });
  }

  /// تکه به بالای برج رسید.
  void _land(Size s, double blockH) {
    final x = dropX!;
    final top = tower.isEmpty ? .5 : tower.last;
    final at = _globalOf(_area, Offset(x * s.width, s.height - 10 - (tower.length + .5) * blockH));
    if ((x - top).abs() > tol) {
      missX = x;
      missY = 0;
      missRot = 0;
      dropX = null;
      FxScope.of(context)?.burst(at, Fx.dust, count: 10);
      bad();
      return;
    }
    tower.add(top + (x - top) * .6);
    dropX = null;
    bump++;
    FxScope.of(context)?.burst(at, Fx.dust, count: 8);
    FxScope.of(context)?.burst(at, Fx.sparkle, count: 6);
    good(widget.step.opt('sound') ?? 'audio/sfx/thunk.mp3');
    if (tower.length >= need) {
      finished = true;
      FxScope.of(context)?.burst(at, Fx.confetti, count: 40);
      ui(UiSound.success);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final bs = math.min(s.width * .24, s.height * .17);
      final bh = bs * .78;
      // اگر برج بلند شد، صحنه پایین می‌رود تا بالای برج پیدا باشد.
      final scroll = math.max(0.0, (tower.length + 2) * bh - s.height * .62);
      final towerTop = s.height - 10 - tower.length * bh + scroll;
      final hookY = bs * .9;
      if (dropX != null) {
        final y = hookY + dropY * s.height;
        if (y + bh >= towerTop) WidgetsBinding.instance.addPostFrameCallback((_) => dropX != null ? _land(s, bh) : null);
      }
      final fallingY = dropX == null ? null : math.min(hookY + dropY * s.height, towerTop - bh);
      return GestureDetector(
        key: _area,
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _drop(),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) {
            final over = ((hook - (tower.isEmpty ? .5 : tower.last)).abs() < tol);
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // زمین
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -scroll - 20,
                  height: 30,
                  child: Container(
                    decoration: BoxDecoration(color: const Color(0xFF8BC34A), borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                // برج
                for (final (k, x) in tower.indexed)
                  Positioned(
                    left: x * s.width - bs / 2,
                    top: s.height - 10 - (k + 1) * bh + scroll,
                    child: k == tower.length - 1
                        ? Squash(
                            trigger: bump,
                            child: GameArt(block, size: bs),
                          )
                        : GameArt(block, size: bs),
                  ),
                // ریل و قلاب
                Positioned(left: 0, right: 0, top: 4, height: 10, child: Container(color: const Color(0xFF6D6A85))),
                Positioned(
                  left: hook * s.width - 2,
                  top: 10,
                  child: Container(width: 4, height: hookY - 14, color: const Color(0xFF6D6A85)),
                ),
                Positioned(
                  left: hook * s.width - 18,
                  top: 0,
                  child: Container(
                    width: 36,
                    height: 22,
                    decoration: BoxDecoration(color: G.orange, borderRadius: BorderRadius.circular(8), boxShadow: G.soft()),
                  ),
                ),
                if (dropX == null && !finished)
                  Positioned(
                    left: hook * s.width - bs / 2,
                    top: hookY - 6,
                    child: HintGlow(
                      on: hint >= 1 && over,
                      child: GameArt(block, size: bs),
                    ),
                  ),
                if (fallingY != null)
                  Positioned(
                    left: dropX! * s.width - bs / 2,
                    top: fallingY,
                    child: GameArt(block, size: bs),
                  ),
                if (missX != null)
                  Positioned(
                    left: missX! * s.width - bs / 2 + missY * 80,
                    top: towerTop - bh + missY * s.height * .6,
                    child: Transform.rotate(
                      angle: missRot,
                      child: Opacity(
                        opacity: (1.4 - missY).clamp(0, 1) / 1.4,
                        child: GameArt(block, size: bs),
                      ),
                    ),
                  ),
                // راهنمای جای برج
                if (!finished)
                  Positioned(
                    left: (tower.isEmpty ? .5 : tower.last) * s.width - bs / 2,
                    top: towerTop - 4,
                    child: Container(
                      width: bs,
                      height: 6,
                      decoration: BoxDecoration(
                        color: (over ? G.green : Colors.white).withValues(alpha: .8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: G.purple, borderRadius: BorderRadius.circular(999)),
                    child: Text('${fa(tower.length)}/${fa(need)}', style: PText.button),
                  ),
                ),
                if (tower.isEmpty && dropX == null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 40,
                    child: Center(child: _Tip(over ? 'حالا! بزن!' : 'صبر کن... وقتی بالای خط سبز بود بزن')),
                  ),
                if (hint >= 3 && over && dropX == null) HintHand(from: Offset(s.width / 2, s.height / 2)),
              ],
            );
          },
        ),
      );
    },
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
    child: Text(
      text,
      style: PText.heading.copyWith(color: G.purple),
      textAlign: TextAlign.center,
    ),
  );
}

/// فوت کردن: دکمه را نگه دار تا پوپو فوت کند؛ شمع خاموش می‌شود، فرفره می‌چرخد یا بادکنک باد می‌شود.
class BlowEngine extends EngineView {
  const BlowEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<BlowEngine> createState() => _BlowState();
}

class _BlowState extends ConsumerState<BlowEngine> with EngineSounds, TickerProviderStateMixin, FrameTicker {
  late final String mode = widget.step.str('mode', 'out');
  late final int need = widget.host.scaled(widget.step.integer('count', mode == 'out' ? 3 : 1));
  late final List<GlobalKey> keys = [for (var i = 0; i < need; i++) GlobalKey()];
  int current = 0;
  double power = 0;
  bool holding = false;
  double t = 0;
  double spin = 0;
  double _puff = 0;
  double _steam = 0;
  final Set<int> doneSet = {};

  @override
  void initState() {
    super.initState();
    startTicker();
  }

  @override
  void onTick(double dt) {
    t += dt;
    if (current < need) {
      if (holding) {
        power = math.min(1, power + dt * (_small(widget.host) ? .75 : .55));
        _puff -= dt;
        if (_puff <= 0) {
          _puff = .12;
          keys[current].currentContext?.fx(
            mode == 'music' ? Fx.notes : Fx.dust,
            count: 2,
            color: mode == 'music' ? null : Colors.white,
            spread: .6,
          );
        }
        if (power >= 1) _complete();
      } else {
        power = math.max(0, power - dt * .25);
      }
    }
    // سوپ داغ: بخار تا وقتی خنک نشده بالا می‌رود.
    if (mode == 'cool' && current < need) {
      _steam -= dt;
      if (_steam <= 0) {
        _steam = .25 + power * .5;
        keys[current].currentContext?.fx(Fx.steam, count: 2);
      }
    }
    spin += dt * (mode == 'spin' ? 1.5 + power * 22 + (doneSet.isNotEmpty ? 14 : 0) : 0);
    setState(() {});
  }

  void _complete() {
    final k = keys[current];
    doneSet.add(current);
    power = 0;
    switch (mode) {
      case 'out':
        k.currentContext?.fx(Fx.smoke, count: 10);
        good('audio/sfx/rustle.mp3');
      case 'inflate':
        k.currentContext?.fx(Fx.confetti, count: 30);
        good('audio/sfx/bloop.mp3');
      case 'music':
        k.currentContext?.fx(Fx.notes, count: 14);
        good(widget.step.opt('sound') ?? 'audio/instruments/flute.mp3');
      case 'cool':
        k.currentContext?.fx(Fx.sparkle, count: 14);
        good('audio/ui/chime.mp3');
      default:
        k.currentContext?.fx(Fx.sparkle, count: 14);
        good('audio/sfx/gear.mp3');
    }
    current++;
    if (current >= need) {
      holding = false;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        for (final k in keys) {
          k.currentContext?.fx(Fx.confetti, count: 12);
        }
        ui(UiSound.success);
      });
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1300), widget.host.done);
    }
  }

  void _hold(bool on) {
    if (current >= need) return;
    if (on) {
      widget.host.touch();
      ui(UiSound.whoosh);
    }
    setState(() => holding = on);
  }

  Widget _target(int i, double size) {
    final art = GameArt(
      doneSet.contains(i) && mode == 'inflate' ? widget.step.str('result', widget.step.str('target')) : widget.step.str('target'),
      size: size,
    );
    final p = i == current ? power : (doneSet.contains(i) ? 1.0 : 0.0);
    return switch (mode) {
      'spin' => Transform.rotate(angle: spin, child: art),
      'inflate' => Transform.scale(
        scale: doneSet.contains(i) ? 1 : .45 + p * .65 + (holding && i == current ? math.sin(t * 30) * .02 : 0),
        child: art,
      ),
      'cool' || 'music' => Transform.rotate(
        angle: holding && i == current ? math.sin(t * 24) * .05 : 0,
        child: Transform.scale(scale: holding && i == current ? 1.04 : 1, child: art),
      ),
      _ => Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          art,
          if (!doneSet.contains(i))
            Positioned(
              top: -size * .32,
              child: CustomPaint(
                size: Size(size * .3, size * .42),
                painter: _FlamePainter(t: t + i, lean: i == current && holding ? .5 + p : 0, scale: 1 - p * .7),
              ),
            ),
        ],
      ),
    };
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth / (need + .5), box.maxHeight * .42);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < need; i++)
                        Padding(
                          padding: EdgeInsets.only(bottom: box.maxHeight * .04),
                          child: HintGlow(
                            on: hint >= 1 && i == current,
                            child: SizedBox(key: keys[i], child: _target(i, size)),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 18,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: LinearProgressIndicator(value: power, color: G.teal, backgroundColor: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Listener: نگه داشتن طولانی را هیچ ژست دیگری (فشار طولانی) لغو نمی‌کند.
                Listener(
                  onPointerDown: (_) => _hold(true),
                  onPointerUp: (_) => _hold(false),
                  onPointerCancel: (_) => _hold(false),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 150),
                    scale: holding ? .92 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      decoration: BoxDecoration(
                        color: G.teal,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: G.soft(),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.scale(
                            scale: holding ? 1.25 + math.sin(t * 20) * .08 : 1,
                            child: const Text('🌬️', style: TextStyle(fontSize: 34)),
                          ),
                          const SizedBox(width: 10),
                          Text(holding ? 'فوووت...' : 'نگه دار و فوت کن', style: PText.button.copyWith(fontSize: 22)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (hint >= 3 && current < need) HintHand(from: Offset(box.maxWidth / 2, box.maxHeight - 40)),
          ],
        ),
      );
    },
  );
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({required this.t, required this.lean, required this.scale});

  final double t;
  final double lean;
  final double scale;

  @override
  void paint(Canvas canvas, Size s) {
    final flick = math.sin(t * 17) * .06 + math.sin(t * 9) * .04;
    canvas.translate(s.width / 2, s.height);
    canvas.scale(scale * (1 + flick), scale * (1 - flick));
    canvas.skew(-lean * .6, 0);
    Path flame(double w, double h) => Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-w, -h * .35, 0, -h)
      ..quadraticBezierTo(w, -h * .35, 0, 0)
      ..close();
    canvas.drawPath(flame(s.width * .55, s.height), Paint()..color = const Color(0xFFFF9800));
    canvas.drawPath(flame(s.width * .32, s.height * .65), Paint()..color = const Color(0xFFFFEB3B));
  }

  @override
  bool shouldRepaint(_FlamePainter old) => true;
}

/// رانندگی: با زدن چپ و راست صفحه، ماشین بین سه خط جابه‌جا می‌شود؛ چیزهای خوب را بگیر و از مانع‌ها دوری کن.
class SteerEngine extends EngineView {
  const SteerEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<SteerEngine> createState() => _SteerState();
}

class _Thing {
  _Thing(this.art, this.good, this.lane);

  final String art;
  final bool good;
  final int lane;
  double y = -.15;
}

class _SteerState extends ConsumerState<SteerEngine> with EngineSounds, TickerProviderStateMixin, FrameTicker {
  late final int need = widget.host.scaled(widget.step.integer('count', 5));
  late final List<String> goods = widget.step.list('good');
  late final List<String> bads = widget.step.list('bad');
  final _area = GlobalKey();
  final _rnd = math.Random(5);
  final List<_Thing> things = [];
  int lane = 1;
  double carX = 1;
  double road = 0;
  double _spawn = .5;
  int got = 0;
  int shake = 0;
  int bump = 0;
  bool finished = false;
  static const carY = .8;

  double get speed => _small(widget.host) ? .28 : .38;

  @override
  void initState() {
    super.initState();
    startTicker();
  }

  @override
  void onTick(double dt) {
    if (finished) {
      road += dt * speed * .5;
      setState(() {});
      return;
    }
    road += dt * speed;
    carX += (lane - carX) * math.min(1, dt * 12);
    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = (_small(widget.host) ? 1.6 : 1.2) + _rnd.nextDouble() * .5;
      final good = bads.isEmpty || _rnd.nextDouble() < .6;
      final pool = good ? goods : bads;
      if (pool.isNotEmpty) things.add(_Thing(pool[_rnd.nextInt(pool.length)], good, _rnd.nextInt(3)));
    }
    final size = (_area.currentContext?.findRenderObject() as RenderBox?)?.size;
    for (final th in [...things]) {
      final before = th.y;
      th.y += dt * speed;
      if (before < carY - .05 && th.y >= carY - .05 && th.lane == lane) {
        things.remove(th);
        final at = size == null ? null : _globalOf(_area, Offset((th.lane + .5) / 3 * size.width, carY * size.height));
        if (th.good) {
          got++;
          bump++;
          if (at != null) FxScope.of(context)?.burst(at, Fx.sparkle, count: 12);
          good(widget.step.opt('sound') ?? 'audio/ui/chime.mp3');
          if (got >= need) {
            finished = true;
            if (at != null) FxScope.of(context)?.burst(at, Fx.confetti, count: 40);
            sfx('audio/sfx/car_horn.mp3');
            widget.host.points(5);
            Future.delayed(_done, widget.host.done);
          }
        } else {
          shake++;
          if (at != null) FxScope.of(context)?.burst(at, Fx.dust, count: 14);
          bad();
        }
      } else if (th.y > 1.15) {
        things.remove(th);
      }
    }
    setState(() {});
  }

  void _steer(int d) {
    if (finished) return;
    widget.host.touch();
    final n = (lane + d).clamp(0, 2);
    if (n != lane) {
      ui(UiSound.whoosh);
      setState(() => lane = n);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final laneW = w / 3;
      final item = math.min(laneW * .62, h * .16);
      final car = math.min(laneW * .82, h * .22);
      final nextGood = things.where((t) => t.good).fold<_Thing?>(null, (a, t) => a == null || t.y > a.y ? t : a);
      return GestureDetector(
        key: _area,
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _steer(d.localPosition.dx < w / 2 ? -1 : 1),
        onHorizontalDragEnd: (d) => _steer((d.primaryVelocity ?? 0) < 0 ? -1 : 1),
        child: ValueListenableBuilder(
          valueListenable: widget.host.hint,
          builder: (context, hint, _) => ShakeScene(
            trigger: shake,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(child: CustomPaint(painter: _RoadPainter(road))),
                for (final th in things)
                  Positioned(
                    left: (th.lane + .5) * laneW - item / 2,
                    top: th.y * h - item / 2,
                    child: HintGlow(
                      on: hint >= 1 && th == nextGood,
                      child: GameArt(th.art, size: item),
                    ),
                  ),
                Positioned(
                  left: (carX + .5) * laneW - car / 2,
                  top: carY * h - car / 2,
                  child: Squash(
                    trigger: bump,
                    child: Transform.rotate(
                      angle: (lane - carX) * .25,
                      child: GameArt(widget.step.str('target'), size: car),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: G.purple, borderRadius: BorderRadius.circular(999)),
                    child: Text('${fa(got)}/${fa(need)}', style: PText.button),
                  ),
                ),
                if (got == 0 && hint < 3)
                  const Positioned(left: 0, right: 0, bottom: 4, child: Center(child: _Tip('چپ یا راست صفحه را بزن'))),
                if (hint >= 3 && nextGood != null)
                  HintHand(from: Offset(nextGood.lane < lane ? w * .2 : (nextGood.lane > lane ? w * .8 : w / 2), h * .6)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _RoadPainter extends CustomPainter {
  _RoadPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24)), Paint()..color = const Color(0xFF7E7B93));
    final edge = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(4, 0, 6, s.height), edge);
    canvas.drawRect(Rect.fromLTWH(s.width - 10, 0, 6, s.height), edge);
    final dash = Paint()..color = const Color(0xFFFFE082);
    final step = s.height / 5;
    final off = (t * s.height) % step;
    for (final x in [s.width / 3, s.width * 2 / 3]) {
      for (var y = -step + off; y < s.height; y += step) {
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, y, 8, step * .5), const Radius.circular(4)), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_RoadPainter old) => old.t != t;
}

/// وصل کردن نقطه‌ها: به ترتیب عددها بزن (یا انگشت بکش)؛ خط کشیده می‌شود و آخرش تصویر پیدا می‌شود.
class ConnectEngine extends EngineView {
  const ConnectEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<ConnectEngine> createState() => _ConnectState();
}

class _ConnectState extends ConsumerState<ConnectEngine> with EngineSounds {
  late final int n = _small(widget.host) ? 4 : widget.step.integer('dots', 6);
  late final List<Offset> dots = [
    for (var i = 0; i < n; i++)
      switch (widget.step.str('shape', 'circle')) {
        'star' => Offset(
          .5 + math.cos(i / n * math.pi * 2 - math.pi / 2) * (i.isEven ? .4 : .22),
          .5 + math.sin(i / n * math.pi * 2 - math.pi / 2) * (i.isEven ? .4 : .22),
        ),
        _ => Offset(.5 + math.cos(i / n * math.pi * 2 - math.pi / 2) * .38, .5 + math.sin(i / n * math.pi * 2 - math.pi / 2) * .38),
      },
  ];
  final _box = GlobalKey();
  final Map<int, int> shakes = {};
  int linked = 0;
  bool finished = false;

  void _hit(int i, double side) {
    if (finished) return;
    if (i != linked) {
      if (i < linked) return;
      setState(() => shakes[i] = (shakes[i] ?? 0) + 1);
      bad();
      return;
    }
    setState(() => linked++);
    final at = _globalOf(_box, dots[i] * side);
    FxScope.of(context)?.burst(at, Fx.sparkle, count: 8);
    good();
    if (linked == n) {
      setState(() => finished = true);
      FxScope.of(context)?.burst(_globalOf(_box, Offset(side / 2, side / 2)), Fx.confetti, count: 50);
      ui(UiSound.success);
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1300), widget.host.done);
    }
  }

  void _pan(Offset p, double side) {
    if (finished || linked >= n) return;
    if ((dots[linked] * side - p).distance < side * .1) _hit(linked, side);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final side = math.min(box.maxWidth, box.maxHeight) * .96;
      final dot = side * .13;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Center(
          child: GestureDetector(
            onPanDown: (d) => _pan(d.localPosition, side),
            onPanUpdate: (d) => _pan(d.localPosition, side),
            child: SizedBox(
              key: _box,
              width: side,
              height: side,
              child: Stack(
                children: [
                  Center(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 600),
                      opacity: finished ? 1 : .12 + .1 * linked / n,
                      child: Squash(
                        trigger: finished ? 1 : 0,
                        child: Idle(
                          enabled: finished,
                          amount: 1.5,
                          child: GameArt(widget.step.str('target'), size: side * .62),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _LinkPainter(dots: dots, linked: linked, closed: finished),
                    ),
                  ),
                  if (!finished)
                    for (var i = 0; i < n; i++)
                      Positioned(
                        left: dots[i].dx * side - dot / 2,
                        top: dots[i].dy * side - dot / 2,
                        child: GestureDetector(
                          onTap: () => _hit(i, side),
                          child: Shake(
                            trigger: shakes[i] ?? 0,
                            child: _Dot(index: i, size: dot, done: i < linked, next: i == linked, glow: hint >= 1 && i == linked),
                          ),
                        ),
                      ),
                  if (hint >= 3 && linked < n)
                    HintHand(from: linked == 0 ? dots[0] * side : dots[linked - 1] * side, to: linked == 0 ? null : dots[linked] * side),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _Dot extends StatelessWidget {
  const _Dot({required this.index, required this.size, required this.done, required this.next, required this.glow});

  final int index;
  final double size;
  final bool done;
  final bool next;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final c = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? G.green : (next ? G.orange : Colors.white),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: G.soft(),
      ),
      child: Text(
        fa(index + 1),
        style: PText.title.copyWith(color: done || next ? Colors.white : G.purple, fontSize: size * .42),
      ),
    );
    return HintGlow(
      on: glow,
      child: next ? Idle(amount: 1.4, child: c) : c,
    );
  }
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({required this.dots, required this.linked, required this.closed});

  final List<Offset> dots;
  final int linked;
  final bool closed;

  @override
  void paint(Canvas canvas, Size s) {
    if (linked < 2) return;
    final p = Path()..moveTo(dots[0].dx * s.width, dots[0].dy * s.height);
    for (var i = 1; i < linked; i++) {
      p.lineTo(dots[i].dx * s.width, dots[i].dy * s.height);
    }
    if (closed) p.close();
    canvas.drawPath(
      p,
      Paint()
        ..color = G.purple
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_LinkPainter old) => old.linked != linked || old.closed != closed;
}

/// کارت حافظه: کارت‌ها را برگردان و جفت‌ها را پیدا کن.
class MemoryEngine extends EngineView {
  const MemoryEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<MemoryEngine> createState() => _MemoryState();
}

class _MemoryState extends ConsumerState<MemoryEngine> with EngineSounds {
  late final List<String> faces = () {
    final items = widget.step.list('items');
    final pairs = math.min(items.length, switch (widget.host.age) {
      AgeBand.toddler => 2,
      AgeBand.preschool => 3,
      AgeBand.early => 4,
    });
    return [...items.take(pairs), ...items.take(pairs)]..shuffle(math.Random(items.join().hashCode));
  }();
  late final List<GlobalKey> keys = [for (final _ in faces) GlobalKey()];
  final Set<int> matched = {};
  final List<int> open = [];
  bool busy = false;

  void _flip(int i) {
    if (busy || matched.contains(i) || open.contains(i)) return;
    widget.host.touch();
    ui(UiSound.page);
    setState(() => open.add(i));
    if (open.length < 2) return;
    final a = open[0], b = open[1];
    busy = true;
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      if (faces[a] == faces[b]) {
        setState(() {
          matched.addAll([a, b]);
          open.clear();
        });
        keys[a].currentContext?.fx(Fx.sparkle, count: 10);
        keys[b].currentContext?.fx(Fx.sparkle, count: 10);
        good(widget.host.data.items[faces[a]]?.sound);
        if (matched.length == faces.length) {
          for (final k in keys) {
            k.currentContext?.fx(Fx.confetti, count: 6);
          }
          widget.host.points(5);
          Future.delayed(_done, widget.host.done);
        }
      } else {
        ui(UiSound.softNo);
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted) setState(open.clear);
        });
      }
      Future.delayed(const Duration(milliseconds: 460), () => busy = false);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = faces.length <= 4 ? 2 : (faces.length <= 6 ? 3 : 4);
      final rows = (faces.length / cols).ceil();
      final card = math.min((box.maxWidth - 16) / cols, (box.maxHeight - 16) / rows) - 10;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) {
          // راهنما: جفتِ اولین کارت باز (یا اولین جفت پیدا نشده) می‌درخشد.
          int? glow;
          if (hint >= 1) {
            final from = open.isNotEmpty
                ? open.first
                : [for (var i = 0; i < faces.length; i++) i].where((i) => !matched.contains(i)).firstOrNull;
            if (from != null) {
              glow = [for (var i = 0; i < faces.length; i++) i]
                  .where((i) => i != from && faces[i] == faces[from] && !matched.contains(i))
                  .firstOrNull;
              if (open.isEmpty) glow = from;
            }
          }
          return Center(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < faces.length; i++)
                  PopIn(
                    delay: Duration(milliseconds: 60 * i),
                    child: GestureDetector(
                      key: keys[i],
                      onTap: () => _flip(i),
                      child: HintGlow(
                        on: glow == i,
                        child: _FlipCard(
                          size: card,
                          up: open.contains(i) || matched.contains(i),
                          matched: matched.contains(i),
                          face: GameArt(faces[i], size: card * .8),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _FlipCard extends StatelessWidget {
  const _FlipCard({required this.size, required this.up, required this.matched, required this.face});

  final double size;
  final bool up;
  final bool matched;
  final Widget face;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: up ? 1 : 0),
    duration: const Duration(milliseconds: 380),
    curve: Curves.easeInOutBack,
    builder: (context, v, _) {
      final showFace = v > .5;
      return Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, .0015)
          ..rotateY(v * math.pi),
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..rotateY(showFace ? math.pi : 0),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 250),
            scale: matched ? .94 : 1,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: showFace ? (matched ? const Color(0xFFD7F5E1) : Colors.white) : G.purple,
                gradient: showFace
                    ? null
                    : const LinearGradient(colors: [Color(0xFF7C4DFF), G.purple], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(size * .16),
                border: Border.all(color: Colors.white, width: 5),
                boxShadow: G.soft(),
              ),
              child: showFace ? face : Icon(Icons.star_rounded, color: const Color(0xFFFFE066), size: size * .45),
            ),
          ),
        ),
      );
    },
  );
}

/// ضربه‌ی سریع: چیزها از سوراخ‌ها سر بیرون می‌آورند؛ فقط چیزهای درست را بزن.
class WhackEngine extends EngineView {
  const WhackEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<WhackEngine> createState() => _WhackState();
}

class _Peek {
  _Peek(this.art, this.good, this.life);

  final String art;
  final bool good;
  final double life;
  double age = 0;
  bool hit = false;

  /// چقدر بیرون آمده (۰ تا ۱).
  double get up {
    final t = age / life;
    if (hit) return 1;
    return t < .2 ? Curves.easeOutBack.transform(t / .2) : (t > .8 ? 1 - (t - .8) / .2 : 1);
  }
}

class _WhackState extends ConsumerState<WhackEngine> with EngineSounds, TickerProviderStateMixin, FrameTicker {
  late final int need = widget.host.scaled(widget.step.integer('count', 6));
  late final String target = widget.step.str('target');
  late final List<String> distract = widget.step.list('distract');
  late final int holes = _small(widget.host) ? 4 : 6;
  late final List<GlobalKey> keys = [for (var i = 0; i < holes; i++) GlobalKey()];
  final Map<int, _Peek> peeks = {};
  final Map<int, int> shakes = {};
  final Map<int, int> bonks = {};
  final _rnd = math.Random(8);
  double _spawn = .4;
  int got = 0;
  bool finished = false;

  @override
  void initState() {
    super.initState();
    startTicker();
  }

  @override
  void onTick(double dt) {
    if (!finished) {
      _spawn -= dt;
      if (_spawn <= 0 && peeks.length < (_small(widget.host) ? 1 : 2)) {
        _spawn = .5 + _rnd.nextDouble() * .5;
        final free = [for (var i = 0; i < holes; i++) i].where((i) => !peeks.containsKey(i)).toList();
        if (free.isNotEmpty) {
          final good = distract.isEmpty || _rnd.nextDouble() < .68;
          peeks[free[_rnd.nextInt(free.length)]] = _Peek(
            good ? target : distract[_rnd.nextInt(distract.length)],
            good,
            _small(widget.host) ? 2.2 : 1.6,
          );
        }
      }
    }
    for (final e in [...peeks.entries]) {
      e.value.age += dt;
      if (e.value.age >= e.value.life || (e.value.hit && e.value.age > .25)) peeks.remove(e.key);
    }
    setState(() {});
  }

  void _whack(int i) {
    final p = peeks[i];
    if (p == null || p.hit || finished || p.up < .4) return;
    widget.host.touch();
    if (!p.good) {
      setState(() => shakes[i] = (shakes[i] ?? 0) + 1);
      bad();
      return;
    }
    p
      ..hit = true
      ..age = 0;
    got++;
    bonks[i] = (bonks[i] ?? 0) + 1;
    keys[i].currentContext?.fx(Fx.sparkle, count: 12);
    good(widget.step.opt('sound') ?? 'audio/sfx/squeak.mp3');
    if (got >= need) {
      finished = true;
      keys[i].currentContext?.fx(Fx.confetti, count: 40);
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = holes == 4 ? 2 : 3;
      final rows = holes ~/ cols;
      final cell = math.min(box.maxWidth / cols, (box.maxHeight - 40) / rows) * .92;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) {
          final goodHole = peeks.entries.where((e) => e.value.good && !e.value.hit).map((e) => e.key).firstOrNull;
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: G.purple, borderRadius: BorderRadius.circular(999)),
                child: Text('${fa(got)}/${fa(need)}', style: PText.button),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var r = 0; r < rows; r++)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [for (var c = 0; c < cols; c++) _hole(r * cols + c, cell, hint >= 1 && goodHole == r * cols + c)],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );

  Widget _hole(int i, double cell, bool glow) {
    final p = peeks[i];
    final art = cell * .62;
    return GestureDetector(
      key: keys[i],
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _whack(i),
      child: SizedBox(
        width: cell,
        height: cell,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // سوراخ
            Positioned(
              bottom: cell * .1,
              child: Container(
                width: cell * .78,
                height: cell * .26,
                decoration: BoxDecoration(
                  color: const Color(0xFF5D4037),
                  borderRadius: BorderRadius.all(Radius.elliptical(cell * .39, cell * .13)),
                  border: Border.all(color: const Color(0xFF8D6E63), width: 5),
                ),
              ),
            ),
            if (p != null)
              Positioned(
                bottom: cell * .2,
                child: ClipRect(
                  child: SizedBox(
                    width: art,
                    height: art,
                    child: Transform.translate(
                      offset: Offset(0, (1 - (p.hit ? 1 - p.age * 4 : p.up).clamp(0, 1)) * art),
                      child: Shake(
                        trigger: shakes[i] ?? 0,
                        child: Squash(
                          trigger: bonks[i] ?? 0,
                          amount: .4,
                          child: HintGlow(
                            on: glow,
                            child: GameArt(p.art, size: art),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // لبه‌ی جلوی سوراخ (روی چیز)
            Positioned(
              bottom: cell * .06,
              child: Container(
                width: cell * .84,
                height: cell * .16,
                decoration: BoxDecoration(
                  color: const Color(0xFF8BC34A),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(cell * .1), top: Radius.circular(cell * .04)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
