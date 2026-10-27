import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../ui/clay.dart';
import 'engine.dart';

const _done = Duration(milliseconds: 650);

/// یک شیء کشیدنی که اگر جای درست رها نشود برمی‌گردد.
class _Draggable extends StatelessWidget {
  const _Draggable({super.key, required this.data, required this.child, this.onStart});

  final String data;
  final Widget child;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) => Draggable<String>(
    data: data,
    onDragStarted: onStart,
    feedback: Transform.scale(scale: 1.12, child: child),
    childWhenDragging: Opacity(opacity: .25, child: child),
    child: child,
  );
}

/// جدا کردن: هر چیز را در سبد درست بگذار.
class SortEngine extends EngineView {
  const SortEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<SortEngine> createState() => _SortState();
}

class _SortState extends ConsumerState<SortEngine> with EngineSounds {
  late final List<(String, bool)> queue;
  int i = 0;
  int shake = 0;
  int burst = 0;

  @override
  void initState() {
    super.initState();
    queue = [for (final g in widget.step.list('good')) (g, true), for (final b in widget.step.list('bad')) (b, false)]
      ..shuffle(math.Random(2));
  }

  void _drop(bool toGood) {
    final (_, isGood) = queue[i];
    if (isGood != toGood) {
      setState(() => shake++);
      bad();
      return;
    }
    good();
    setState(() {
      i++;
      burst++;
    });
    if (i == queue.length) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  Widget _bin(String label, bool isGood, Color color, bool glow) => DragTarget<String>(
    onAcceptWithDetails: (_) => _drop(isGood),
    builder: (context, cand, _) => AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 150,
      height: 120,
      decoration: BoxDecoration(
        color: cand.isNotEmpty ? G.tint(color, .3) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color, width: 5),
        boxShadow: [
          ...G.soft(),
          if (glow) BoxShadow(color: const Color(0xFFFFE066).withValues(alpha: .9), blurRadius: 24, spreadRadius: 4),
        ],
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isGood ? Icons.shopping_basket_rounded : Icons.delete_rounded, color: color, size: 44),
          Text(label, style: PText.heading.copyWith(color: color)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth, box.maxHeight) * .36;
      final current = i < queue.length ? queue[i] : null;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: current == null
                        ? const SizedBox.shrink()
                        : Shake(
                            trigger: shake,
                            child: _Draggable(
                              key: ValueKey(i),
                              data: current.$1,
                              onStart: widget.host.touch,
                              child: GameArt(current.$1, size: size),
                            ),
                          ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _bin(widget.step.str('goodLabel', 'خوب'), true, G.green, hint >= 1 && current?.$2 == true),
                    _bin(widget.step.str('badLabel', 'خراب'), false, G.red, hint >= 1 && current?.$2 == false),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
            if (hint >= 3 && current != null)
              HintHand(
                from: Offset(box.maxWidth / 2, (box.maxHeight - 136) / 2),
                to: Offset(current.$2 ? box.maxWidth * .75 : box.maxWidth * .25, box.maxHeight - 70),
              ),
            Positioned.fill(child: Sparkles(trigger: burst)),
          ],
        ),
      );
    },
  );
}

/// سوار کردن: هر تکه را روی سایه‌اش بگذار.
class AssembleEngine extends EngineView {
  const AssembleEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<AssembleEngine> createState() => _AssembleState();
}

class _AssembleState extends ConsumerState<AssembleEngine> with EngineSounds {
  late final parts = widget.step.maps('parts');
  final Set<int> placed = {};
  int burst = 0;
  bool get finished => placed.length == parts.length;

  void _place(int i) {
    setState(() {
      placed.add(i);
      burst++;
    });
    good('audio/sfx/snap.mp3');
    if (finished) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final area = Size(box.maxWidth, box.maxHeight - 120);
      final base = math.min(area.width, area.height) * .8;
      final part = math.min(area.width, area.height) * .3;
      final next = [for (var i = 0; i < parts.length; i++) i].where((i) => !placed.contains(i)).firstOrNull;
      Offset slot(int i) => Offset((parts[i]['x'] as num).toDouble() * area.width, (parts[i]['y'] as num).toDouble() * area.height);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Positioned(
              left: (area.width - base) / 2,
              top: (area.height - base) / 2,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: finished ? 1 : .22,
                child: GameArt(finished ? widget.step.str('result') : widget.step.str('base'), size: base),
              ),
            ),
            for (var i = 0; i < parts.length; i++)
              Positioned(
                left: slot(i).dx - part / 2,
                top: slot(i).dy - part / 2,
                child: placed.contains(i)
                    ? (finished ? const SizedBox.shrink() : GameArt(parts[i]['art'] as String, size: part))
                    : DragTarget<String>(
                        onWillAcceptWithDetails: (d) => d.data == '$i' || d.data == parts[i]['art'],
                        onAcceptWithDetails: (_) => _place(i),
                        builder: (context, cand, _) => Container(
                          width: part,
                          height: part,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: cand.isNotEmpty ? .8 : .45),
                            border: Border.all(
                              color: hint >= 1 && i == next ? const Color(0xFFFFB300) : G.purple.withValues(alpha: .5),
                              width: 4,
                            ),
                          ),
                          child: Opacity(opacity: .25, child: GameArt(parts[i]['art'] as String, size: part)),
                        ),
                      ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 116,
              child: ClayCard(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var i = 0; i < parts.length; i++)
                      if (!placed.contains(i))
                        _Draggable(data: '$i', onStart: widget.host.touch, child: GameArt(parts[i]['art'] as String, size: 92)),
                  ],
                ),
              ),
            ),
            if (hint >= 3 && next != null) HintHand(from: Offset(box.maxWidth / 2, box.maxHeight - 60), to: slot(next)),
            Positioned.fill(child: Sparkles(trigger: burst)),
          ],
        ),
      );
    },
  );
}

/// شمردن: [count] تا را در ظرف بگذار.
class CountEngine extends EngineView {
  const CountEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<CountEngine> createState() => _CountState();
}

class _CountState extends ConsumerState<CountEngine> with EngineSounds {
  late final int need = widget.step.integer('count', 3);
  late final int tray = need + 2;
  final Set<int> used = {};
  int burst = 0;

  void _drop(String data) {
    final i = int.parse(data);
    if (used.length >= need || used.contains(i)) return;
    setState(() {
      used.add(i);
      burst++;
    });
    good(widget.step.opt('sound'));
    if (used.length == need) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final big = math.min(box.maxWidth, box.maxHeight - 130) * .62;
      final small = math.min(84.0, box.maxWidth / (tray + 1));
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: DragTarget<String>(
                    onAcceptWithDetails: (d) => _drop(d.data),
                    builder: (context, cand, _) => Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          HintGlow(
                            on: hint >= 1 || cand.isNotEmpty,
                            child: GameArt(widget.step.str('into'), size: big),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                              decoration: BoxDecoration(color: G.purple, borderRadius: BorderRadius.circular(999)),
                              child: Text('${fa(used.length)} از ${fa(need)}', style: PText.button.copyWith(fontSize: 22)),
                            ),
                          ),
                          Wrap(children: [for (var k = 0; k < used.length; k++) GameArt(widget.step.str('target'), size: big * .22)]),
                        ],
                      ),
                    ),
                  ),
                ),
                ClayCard(
                  padding: const EdgeInsets.all(8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (var i = 0; i < tray; i++)
                        if (!used.contains(i))
                          _Draggable(
                            data: '$i',
                            onStart: widget.host.touch,
                            child: GameArt(widget.step.str('target'), size: small),
                          )
                        else
                          SizedBox(width: small, height: small),
                    ],
                  ),
                ),
              ],
            ),
            if (hint >= 3)
              HintHand(from: Offset(box.maxWidth / 2, box.maxHeight - 50), to: Offset(box.maxWidth / 2, (box.maxHeight - 120) / 2)),
            Positioned.fill(child: Sparkles(trigger: burst)),
          ],
        ),
      );
    },
  );
}

/// ترتیب: به ترتیب بزن (بزرگ به کوچک، یا رنگ‌های چراغ، یا لایه‌های ساندویچ).
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
  final List<int> picked = [];
  final Map<int, int> shakes = {};

  double scaleOf(int i) => bySize ? 1 - i * (.5 / items.length) : 1;

  void _tap(int i) {
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
    if (picked.length == items.length) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final size = math.min(box.maxWidth / (items.length + .6), box.maxHeight * .32);
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
                          width: size,
                          height: size * 1.1,
                          margin: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .6),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: G.purple.withValues(alpha: .3), width: 3),
                          ),
                          alignment: Alignment.bottomCenter,
                          child: k < picked.length
                              ? Transform.scale(
                                  scale: scaleOf(picked[k]),
                                  alignment: Alignment.bottomCenter,
                                  child: GameArt(items[picked[k]], size: size),
                                )
                              : Text(fa(k + 1), style: PText.title.copyWith(color: G.purple.withValues(alpha: .4))),
                        ),
                    ],
                  ),
                ),
              ),
              ClayCard(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final i in shuffled)
                      picked.contains(i)
                          ? SizedBox(width: size, height: size)
                          : GestureDetector(
                              onTap: () => _tap(i),
                              child: Shake(
                                trigger: shakes[i] ?? 0,
                                child: HintGlow(
                                  on: hint >= 1 && want < items.length && (i == want || items[i] == items[want]) && !picked.contains(i),
                                  child: Transform.scale(
                                    scale: scaleOf(i),
                                    alignment: Alignment.bottomCenter,
                                    child: GameArt(items[i], size: size),
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

/// ریختن: نگه دار تا مایع به خط برسد و رها کن.
class PourEngine extends EngineView {
  const PourEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<PourEngine> createState() => _PourState();
}

class _PourState extends ConsumerState<PourEngine> with EngineSounds {
  double level = 0;
  bool pouring = false;
  bool finished = false;
  Timer? _t;
  int shake = 0;
  static const line = .72;
  double get tol => widget.host.age.minAge <= 2 ? .14 : .09;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    if (finished) return;
    setState(() => pouring = true);
    sfx(widget.step.opt('sound'));
    widget.host.touch();
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 40), (_) {
      setState(() => level = math.min(1, level + .012));
      if (level >= 1) _stop();
    });
  }

  void _stop() {
    _t?.cancel();
    if (!pouring || finished) return;
    setState(() => pouring = false);
    if ((level - line).abs() <= tol) {
      setState(() => finished = true);
      good('audio/ui/success.mp3');
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    } else if (level > line + tol) {
      // سر رفت: دوباره از اول.
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
      final h = math.min(box.maxHeight * .62, 260.0);
      final w = h * .72;
      final color = G.hex(widget.step.str('color', '#4FC3F7'));
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              right: box.maxWidth * .12,
              child: GestureDetector(
                onTapDown: (_) => _start(),
                onTapUp: (_) => _stop(),
                onTapCancel: _stop,
                child: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: pouring ? -.12 : 0,
                  child: HintGlow(
                    on: hint >= 1 && !finished,
                    child: GameArt(widget.step.str('source'), size: h * .5),
                  ),
                ),
              ),
            ),
            if (pouring)
              Positioned(
                top: h * .42,
                right: box.maxWidth * .12 + h * .38,
                child: Container(
                  width: 10,
                  height: h * .5,
                  decoration: BoxDecoration(color: color.withValues(alpha: .8), borderRadius: BorderRadius.circular(5)),
                ),
              ),
            Positioned(
              bottom: 8,
              child: Shake(
                trigger: shake,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Opacity(opacity: .35, child: GameArt(widget.step.str('into'), size: w * 1.3)),
                    Container(
                      width: w,
                      height: h * .8,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .55),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30), top: Radius.circular(10)),
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: level,
                              widthFactor: 1,
                              child: ColoredBox(color: color),
                            ),
                          ),
                          Align(
                            alignment: const Alignment(0, 1 - line * 2),
                            child: Container(height: 5, color: hint >= 1 ? const Color(0xFFFFB300) : G.purple),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              child: Text(pouring ? 'نگه دار...' : 'نگه دار و رها کن', style: PText.heading.copyWith(color: G.purple)),
            ),
            if (hint >= 3 && !finished) HintHand(from: Offset(box.maxWidth * .8, h * .25)),
            Positioned.fill(
              child: Sparkles(trigger: finished ? 1 : 0, color: color),
            ),
          ],
        ),
      );
    },
  );
}

/// ترکیب رنگ: دو رنگ درست را در کاسه بریز.
class MixEngine extends EngineView {
  const MixEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<MixEngine> createState() => _MixState();
}

class _MixState extends ConsumerState<MixEngine> with EngineSounds {
  late final a = G.hex(widget.step.str('a'));
  late final b = G.hex(widget.step.str('b'));
  late final result = G.hex(widget.step.str('result'));
  late final List<Color> pots = [a, b, const Color(0xFF9C27B0), const Color(0xFF795548)]..shuffle(math.Random(4));
  final List<Color> inBowl = [];
  bool finished = false;
  int shake = 0;

  void _add(Color c) {
    if (finished || inBowl.contains(c)) return;
    if (c != a && c != b) {
      setState(() {
        shake++;
        inBowl.clear();
      });
      bad();
      return;
    }
    setState(() => inBowl.add(c));
    good('audio/sfx/splash.mp3');
    if (inBowl.length == 2) {
      setState(() => finished = true);
      widget.host.points(5);
      Future.delayed(const Duration(milliseconds: 1400), widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final bowl = math.min(box.maxWidth, box.maxHeight) * .45;
      final bowlColor = finished ? result : (inBowl.isEmpty ? Colors.white : inBowl.first);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Column(
          children: [
            Expanded(
              child: Center(
                child: Shake(
                  trigger: shake,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        width: bowl,
                        height: bowl * .6,
                        decoration: BoxDecoration(
                          color: bowlColor,
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(bowl * .4), top: const Radius.circular(12)),
                          border: Border.all(color: Colors.white, width: 8),
                          boxShadow: G.soft(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (finished) SectionPill(widget.step.str('resultName'), color: result),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final c in pots)
                  GestureDetector(
                    onTap: () => _add(c),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: inBowl.contains(c) ? .3 : 1,
                      child: Container(
                        width: 64,
                        height: 76,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12), bottom: Radius.circular(24)),
                          border: Border.all(color: Colors.white, width: 5),
                          boxShadow: [
                            ...G.soft(),
                            if (hint >= 1 && (c == a || c == b) && !inBowl.contains(c))
                              const BoxShadow(color: Color(0xEEFFE066), blurRadius: 22, spreadRadius: 5),
                          ],
                        ),
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

/// رنگ کردن: رنگ را انتخاب کن و روی لکه‌ها بزن.
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
  Color brush = palette.first;
  int burst = 0;

  void _paint(int i) {
    setState(() {
      painted[i] = brush;
      burst++;
    });
    good('audio/sfx/rustle.mp3');
    if (painted.length == areas) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight - 90);
      final dot = s * .2;
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
                        Center(child: GameArt(widget.step.str('target'), size: s * .75)),
                        for (var i = 0; i < areas; i++)
                          Positioned(
                            left: spots[i].dx * s - dot / 2,
                            top: spots[i].dy * s - dot / 2,
                            child: GestureDetector(
                              onTap: () => _paint(i),
                              child: HintGlow(
                                on: hint >= 1 && i == next,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 250),
                                  width: dot,
                                  height: dot,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: painted[i] ?? Colors.white.withValues(alpha: .7),
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: G.soft(),
                                  ),
                                  child: painted.containsKey(i) ? null : const Icon(Icons.brush_rounded, color: G.locked),
                                ),
                              ),
                            ),
                          ),
                        Positioned.fill(
                          child: Sparkles(trigger: burst, color: brush),
                        ),
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
                        setState(() => brush = c);
                        widget.host.touch();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: c == brush ? 58 : 46,
                        height: c == brush ? 58 : 46,
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c,
                          border: Border.all(color: Colors.white, width: c == brush ? 6 : 3),
                          boxShadow: G.soft(),
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

/// پازل: تکه‌های تصویر را سر جایشان بگذار.
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
  final Set<int> placed = {};
  int burst = 0;

  Widget _piece(int i, double cell) {
    final (rows, cols) = grid;
    final r = i ~/ cols, c = i % cols;
    return SizedBox(
      width: cell,
      height: cell,
      child: ClipRect(
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
    setState(() {
      placed.add(i);
      burst++;
    });
    good('audio/sfx/snap.mp3');
    if (placed.length == n) {
      widget.host.points(5);
      Future.delayed(_done, widget.host.done);
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final (rows, cols) = grid;
      final cell = math.min((box.maxWidth - 20) / cols, (box.maxHeight - 120) / rows) * .9;
      final small = math.min(80.0, (box.maxWidth - 20) / n - 6);
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
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: G.soft()),
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var r = 0; r < rows; r++)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (var c = 0; c < cols; c++)
                                    DragTarget<String>(
                                      onWillAcceptWithDetails: (d) => d.data == '${r * cols + c}',
                                      onAcceptWithDetails: (_) => _place(r * cols + c),
                                      onLeave: (_) {},
                                      builder: (context, cand, rejected) {
                                        final i = r * cols + c;
                                        return Container(
                                          width: cell,
                                          height: cell,
                                          decoration: BoxDecoration(
                                            border: Border.all(color: hint >= 1 && i == next ? const Color(0xFFFFB300) : G.line, width: 2),
                                            color: G.sky,
                                          ),
                                          child: placed.contains(i) ? _piece(i, cell) : null,
                                        );
                                      },
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ClayCard(
                    padding: const EdgeInsets.all(6),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 6,
                      children: [
                        for (final i in tray)
                          if (!placed.contains(i))
                            Draggable<String>(
                              data: '$i',
                              onDragStarted: widget.host.touch,
                              onDraggableCanceled: (_, _) => bad(),
                              feedback: _piece(i, cell),
                              childWhenDragging: SizedBox(width: small, height: small),
                              child: FittedBox(child: _piece(i, small)),
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
              Positioned.fill(child: Sparkles(trigger: burst)),
            ],
          );
        },
      );
    },
  );
}

/// دنبال کردن مسیر: شیء را با انگشت روی راه ببر.
class TraceEngine extends EngineView {
  const TraceEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<TraceEngine> createState() => _TraceState();
}

class _TraceState extends ConsumerState<TraceEngine> with EngineSounds {
  double progress = 0;
  bool finished = false;
  int _tick = 0;

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
    if (bestD < 70 && best > progress) {
      setState(() => progress = best);
      final tick = (progress * 10).floor();
      if (tick != _tick) {
        _tick = tick;
        widget.host.right();
        sfx('audio/ui/pop.mp3');
      }
      if (progress >= .98) {
        finished = true;
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
                left: _at(1, s).dx - 26,
                top: _at(1, s).dy - 26,
                child: const Icon(Icons.flag_rounded, color: G.red, size: 52),
              ),
              Positioned(
                left: pos.dx - size / 2,
                top: pos.dy - size / 2,
                child: HintGlow(
                  on: hint >= 1,
                  child: GameArt(widget.step.str('target'), size: size),
                ),
              ),
              if (hint >= 3 && !finished) HintHand(from: pos, to: _at(math.min(1, progress + .25), s)),
              Positioned.fill(child: Sparkles(trigger: finished ? 1 : 0)),
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
    final road = Paint()
      ..color = Colors.white.withValues(alpha: .85)
      ..strokeWidth = 46
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final done = Paint()
      ..color = G.green
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dots = Paint()..color = glow ? const Color(0xFFFFB300) : G.purple.withValues(alpha: .45);
    final p = Path()..moveTo(at(0).dx, at(0).dy);
    for (var t = .01; t <= 1.0001; t += .01) {
      p.lineTo(at(t).dx, at(t).dy);
    }
    canvas.drawPath(p, road);
    final q = Path()..moveTo(at(0).dx, at(0).dy);
    for (var t = .01; t <= progress; t += .01) {
      q.lineTo(at(t).dx, at(t).dy);
    }
    canvas.drawPath(q, done);
    for (var t = progress; t <= 1; t += .05) {
      canvas.drawCircle(at(t), 5, dots);
    }
  }

  @override
  bool shouldRepaint(_PathPainter old) => old.progress != progress || old.glow != glow;
}
