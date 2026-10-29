import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../ui/clay.dart';
import '../../ui/toons/toon.dart';
import '../../ui/fx.dart';
import '../scoring.dart';
import 'engine.dart';

/// چیزهای کوله‌پشتی که برای یک گام نشان داده می‌شوند: آنچه لازم است و چند چیز دیگر که کودک ساخته.
/// اگر چیزِ لازم ساخته نشده باشد (بخش رد شده)، یک نسخه‌ی «قرضی» از دوستان در کوله پیدا می‌شود.
List<String> backpackChoices(EngineHost host, List<String> needed, {int extra = 3}) {
  final others = host.backpack.where((i) => !needed.contains(i)).toList()..shuffle(math.Random(needed.join().hashCode));
  // اگر کودک هنوز چیز زیادی نساخته، از چیزهای ساده‌ی دیگر داستان پر می‌شود تا انتخاب معنا داشته باشد.
  final fill = [
    'juice',
    'bread',
    'hammer',
    'watering_can',
    'flashlight',
    'paints',
    'drum',
    'toy_car',
    'soup',
    'cart',
  ].where((i) => !needed.contains(i) && !others.contains(i) && host.data.items.containsKey(i)).toList();
  final pick = [...needed, ...others.take(extra), ...fill.take(math.max(0, extra - others.length))];
  return pick..shuffle(math.Random(needed.length * 31 + host.backpack.length));
}

/// کوله‌پشتی پایین صفحه.
class BackpackTray extends StatelessWidget {
  const BackpackTray({
    super.key,
    required this.items,
    required this.host,
    this.glow,
    this.used = const {},
    this.shakes = const {},
    this.borrowed = const {},
    this.onTap,
  });

  /// لمس یک چیز (به‌جای کشیدن): آن چیز به سمت هدف پرواز می‌کند.
  final void Function(String id, BuildContext at)? onTap;

  final List<String> items;
  final EngineHost host;
  final String? glow;
  final Set<String> used;
  final Map<String, int> shakes;
  final Set<String> borrowed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE9C7),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0xFFE0A100), width: 4),
      boxShadow: G.soft(),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.backpack_rounded, color: Color(0xFFB7791F)),
            const SizedBox(width: 6),
            Text('کوله‌پشتی پوپو', style: PText.label.copyWith(color: const Color(0xFF8A5A00))),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final id in items)
              if (used.contains(id))
                const SizedBox(width: 78, height: 78)
              else
                Builder(
                  builder: (at) => GestureDetector(
                    onTap: onTap == null ? null : () => onTap!(id, at),
                    child: Draggable<String>(
                      data: id,
                      onDragStarted: host.touch,
                      feedback: Transform.rotate(angle: -.08, child: GameArt(id, size: 100)),
                      childWhenDragging: const SizedBox(width: 78, height: 78),
                      child: Shake(
                        trigger: shakes[id] ?? 0,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            HintGlow(
                              on: glow == id,
                              child: Idle(
                                seed: id.hashCode,
                                amount: .4,
                                child: GameArt(id, size: 78, label: host.data.items[id]?.title),
                              ),
                            ),
                            if (borrowed.contains(id))
                              const Positioned(
                                top: -4,
                                left: -4,
                                child: Tooltip(
                                  message: 'قرضی از دوستان',
                                  child: Icon(Icons.volunteer_activism_rounded, color: G.pink, size: 24),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ],
    ),
  );
}

/// [id] را از جای [at] تا [target] پرواز بده و بعد [then] (اگر لایه‌ی جلوه نباشد، فوری).
void flyTo(BuildContext context, String id, BuildContext at, GlobalKey target, VoidCallback then) {
  final fx = FxScope.of(context);
  final to = target.currentContext?.globalCenter;
  if (fx == null || to == null) return then();
  fx.fly(id, at.globalCenter, to, size: 84, ms: 560, arc: 120, spin: .3, endScale: .8, onLand: then);
}

/// مانع: فقط با یکی از ساخته‌های قبلی حل می‌شود.
class UseEngine extends EngineView {
  const UseEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<UseEngine> createState() => _UseState();
}

class _UseState extends ConsumerState<UseEngine> with EngineSounds {
  late final String need = widget.step.str('need');
  late final List<String> choices = backpackChoices(widget.host, [need]);
  final Map<String, int> shakes = {};
  final _spot = GlobalKey();
  bool solved = false;
  bool firstTry = true;
  int spotShake = 0;

  void _offer(String id) {
    if (solved) return;
    if (id != need) {
      firstTry = false;
      setState(() {
        shakes[id] = (shakes[id] ?? 0) + 1;
        spotShake++;
      });
      bad();
      // پوپو کاربرد واقعی آن وسیله را می‌گوید، تا اشتباه هم چیزی یاد بدهد.
      ref.say('${widget.step.p['_section']}.s${widget.step.p['_index']}.why').then((_) {
        if (mounted) ref.say('item.$id.use');
      });
      return;
    }
    setState(() => solved = true);
    sfx(widget.host.data.items[need]?.sound);
    _spot.currentContext?.fx(Fx.sparkle, count: 20);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _spot.currentContext?.fx(Fx.confetti, count: 36);
    });
    final borrowed = !widget.host.backpack.contains(need);
    widget.host.points(borrowed ? 0 : Scoring.useRight + (firstTry ? Scoring.useFirstTry : 0));
    widget.host.right();
    ref.say('${widget.step.p['_section']}.s${widget.step.p['_index']}.done');
    Future.delayed(const Duration(milliseconds: 1700), widget.host.done);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final spot = math.min(box.maxWidth, box.maxHeight - 200) * .62;
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) => Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: DragTarget<String>(
                      onAcceptWithDetails: (d) => _offer(d.data),
                      builder: (context, cand, _) => Shake(
                        trigger: spotShake,
                        child: Squash(
                          key: _spot,
                          trigger: solved ? 1 : 0,
                          amount: .2,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: spot * 1.1,
                                height: spot * 1.1,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: solved ? G.tint(G.green, .75) : Colors.white.withValues(alpha: cand.isNotEmpty ? .9 : .55),
                                  border: Border.all(
                                    color: solved ? G.green : (hint >= 1 ? const Color(0xFFFFB300) : Colors.white),
                                    width: 6,
                                  ),
                                ),
                              ),
                              AnimatedScale(
                                duration: const Duration(milliseconds: 200),
                                scale: cand.isNotEmpty ? 1.06 : 1,
                                child: Idle(
                                  amount: solved ? 1.5 : .6,
                                  child: GameArt(widget.step.str('spot'), size: spot, mood: solved ? ToonMood.happy : ToonMood.sad),
                                ),
                              ),
                              if (solved)
                                Positioned(
                                  bottom: -spot * .05,
                                  right: -spot * .05,
                                  child: PopIn(from: 1.6, child: GameArt(need, size: spot * .55, mood: ToonMood.act)),
                                ),
                              if (!solved)
                                Positioned(
                                  top: 0,
                                  child: Idle(
                                    amount: 1.5,
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: G.orange,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 4),
                                        boxShadow: G.soft(),
                                      ),
                                      child: const Icon(Icons.question_mark_rounded, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              if (solved)
                                const Positioned(
                                  top: 0,
                                  child: PopIn(child: Icon(Icons.check_circle_rounded, color: G.green, size: 64)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                BackpackTray(
                  items: choices,
                  host: widget.host,
                  glow: hint >= 1 ? need : null,
                  used: solved ? {need} : const {},
                  shakes: shakes,
                  borrowed: {if (!widget.host.backpack.contains(need)) need},
                  onTap: (id, at) {
                    if (solved) return;
                    widget.host.touch();
                    flyTo(context, id, at, _spot, () {
                      if (mounted) _offer(id);
                    });
                  },
                ),
              ],
            ),
            if (hint >= 3 && !solved)
              HintHand(from: Offset(box.maxWidth / 2, box.maxHeight - 60), to: Offset(box.maxWidth / 2, (box.maxHeight - 160) / 2)),
          ],
        ),
      );
    },
  );
}

/// پذیرایی: به هر دوست همان چیزی را بده که می‌خواهد؛ دوست می‌پرد و قلب می‌دهد.
class ServeEngine extends EngineView {
  const ServeEngine({super.key, required super.step, required super.host});

  @override
  ConsumerState<ServeEngine> createState() => _ServeState();
}

class _ServeState extends ConsumerState<ServeEngine> with EngineSounds {
  late final pairs = widget.step.maps('pairs');
  late final List<String> choices = backpackChoices(widget.host, [for (final p in pairs) p['item'] as String], extra: 2);
  late final List<GlobalKey> friends = [for (final _ in pairs) GlobalKey()];
  final Set<int> served = {};
  final Map<String, int> shakes = {};
  final Map<int, int> friendShake = {};

  void _give(int f, String id) {
    if (served.contains(f)) return;
    if (pairs[f]['item'] != id) {
      setState(() {
        shakes[id] = (shakes[id] ?? 0) + 1;
        friendShake[f] = (friendShake[f] ?? 0) + 1;
      });
      bad();
      return;
    }
    setState(() => served.add(f));
    sfx(widget.host.data.items[id]?.sound);
    friends[f].currentContext?.fx(Fx.hearts, count: 10);
    friends[f].currentContext?.fx(Fx.sparkle, count: 8);
    widget.host.right();
    widget.host.points(widget.host.backpack.contains(id) ? Scoring.useRight : 0);
    if (served.length == pairs.length) {
      ui(UiSound.success);
      Future.delayed(const Duration(milliseconds: 1100), widget.host.done);
    }
  }

  /// لمس در کوله: به اولین دوستی که آن را می‌خواهد (یا اولین دوست منتظر) پرواز می‌کند.
  void _tapGive(String id, BuildContext at) {
    final waiting = [for (var f = 0; f < pairs.length; f++) f].where((f) => !served.contains(f)).toList();
    if (waiting.isEmpty) return;
    final f = waiting.firstWhere((f) => pairs[f]['item'] == id, orElse: () => waiting.first);
    widget.host.touch();
    flyTo(context, id, at, friends[f], () {
      if (mounted) _give(f, id);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = math.min(box.maxWidth / pairs.length - 8, (box.maxHeight - 200) * .6);
      return ValueListenableBuilder(
        valueListenable: widget.host.hint,
        builder: (context, hint, _) {
          final next = [for (var i = 0; i < pairs.length; i++) i].where((i) => !served.contains(i)).firstOrNull;
          return Column(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    for (var f = 0; f < pairs.length; f++)
                      DragTarget<String>(
                        onAcceptWithDetails: (d) => _give(f, d.data),
                        builder: (context, cand, _) => Shake(
                          trigger: friendShake[f] ?? 0,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // حباب فکر: چیزی که می‌خواهد.
                              PopIn(
                                delay: Duration(milliseconds: 200 * f),
                                child: Idle(
                                  seed: f,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: served.contains(f) ? const Color(0xFFD7F5E1) : Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: G.soft(),
                                      border: Border.all(color: hint >= 1 && f == next ? const Color(0xFFFFB300) : Colors.white, width: 3),
                                    ),
                                    child: served.contains(f)
                                        ? PopIn(
                                            child: Icon(Icons.favorite_rounded, color: G.pink, size: w * .34),
                                          )
                                        : GameArt(pairs[f]['item'] as String, size: w * .4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Squash(
                                key: friends[f],
                                trigger: served.contains(f) ? 1 : 0,
                                amount: .3,
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 300),
                                  scale: cand.isNotEmpty ? 1.1 : 1,
                                  child: Idle(
                                    seed: f + 7,
                                    amount: served.contains(f) ? 1.6 : .7,
                                    child: GameArt(pairs[f]['friend'] as String, size: w, mood: served.contains(f) ? ToonMood.happy : ToonMood.idle),
                                  ),
                                ),
                              ),
                              GroundShadow(width: w * .6),
                              Text(widget.host.data.friend(pairs[f]['friend'] as String).name, style: PText.label),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              BackpackTray(
                items: choices,
                host: widget.host,
                glow: hint >= 1 && next != null ? pairs[next]['item'] as String : null,
                used: {for (final f in served) pairs[f]['item'] as String},
                shakes: shakes,
                borrowed: {
                  for (final p in pairs)
                    if (!widget.host.backpack.contains(p['item'])) p['item'] as String,
                },
                onTap: _tapGive,
              ),
            ],
          );
        },
      );
    },
  );
}
