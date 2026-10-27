import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../game/engines/engine.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../ui/clay.dart';
import '../mascot/popo_mascot.dart';

/// اتاق بازی: همه‌ی ساخته‌ها روی قفسه. کودک چیزها را روی صحنه می‌کشد و با آن‌ها بازی می‌کند؛
/// دو چیز که با هم کار تازه‌ای می‌کنند «ترکیب» کشف می‌کنند؛ سه سفارش روزانه‌ی دوستان سکه می‌دهند.
class PlayroomTab extends ConsumerStatefulWidget {
  const PlayroomTab({super.key});

  @override
  ConsumerState<PlayroomTab> createState() => _PlayroomTabState();
}

class _PlayroomTabState extends ConsumerState<PlayroomTab> {
  /// چیزهای روی صحنه و جایشان (۰ تا ۱).
  final Map<String, Offset> stage = {};
  final Map<String, int> bounce = {};
  String? message;
  int burst = 0;

  /// سفارش انتخاب‌شده (شماره در data.orders).
  int? order;

  List<int> _todayOrders(GameData data) {
    final now = DateTime.now();
    final rnd = math.Random(now.year * 1000 + now.month * 40 + now.day);
    final all = [for (var i = 0; i < data.orders.length; i++) i]..shuffle(rnd);
    return all.take(3).toList();
  }

  void _place(String id, Offset at) {
    setState(() => stage[id] = at);
    ref.read(audioProvider).ui(UiSound.pop);
    _checkCombos();
  }

  Future<void> _checkCombos() async {
    final data = ref.read(gameDataProvider);
    for (final c in data.combos) {
      if (c.items.every(stage.containsKey)) {
        final fresh = await ref.read(gameProvider.notifier).discoverCombo(c);
        if (!mounted) return;
        setState(() {
          message = c.text;
          burst++;
          for (final i in c.items) {
            bounce[i] = (bounce[i] ?? 0) + 1;
          }
        });
        for (final i in c.items) {
          ref.read(audioProvider).play(data.item(i).sound);
        }
        if (fresh) {
          await ref.say('playroom.combo');
          final idx = data.combos.indexOf(c) + 1;
          if (mounted) await ref.say('combo.$idx');
        }
        return;
      }
    }
  }

  void _tapItem(String id) {
    final item = ref.read(gameDataProvider).item(id);
    ref.read(audioProvider).play(item.sound);
    setState(() {
      bounce[id] = (bounce[id] ?? 0) + 1;
      message = item.use;
    });
  }

  Future<void> _give(String id) async {
    final data = ref.read(gameDataProvider);
    final o = order;
    if (o == null) return;
    final want = data.orders[o];
    if (data.item(id).tags.contains(want.tag)) {
      ref.read(audioProvider).ui(UiSound.success);
      await ref.read(gameProvider.notifier).completeOrder(o);
      if (!mounted) return;
      setState(() {
        order = null;
        burst++;
        message = '+۱۵ سکه!';
      });
      await ref.say('playroom.order.done');
    } else {
      ref.read(audioProvider).ui(UiSound.softNo);
      await ref.say('playroom.order.wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider);
    final g = ref.watch(gameProvider);
    final mine = [
      for (final id in data.items.keys)
        if (g.backpack.contains(id)) id,
    ];
    final today = _todayOrders(data);
    final doneToday = ref.read(gameProvider.notifier).ordersToday();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Text('اتاق بازی', style: PText.display.copyWith(color: G.purple, fontSize: 28)),
              const Spacer(),
              const WalletBar(),
            ],
          ),
        ),
        // سفارش‌های امروز
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final o in today)
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: _OrderChip(
                    order: data.orders[o],
                    friend: data.friend(data.orders[o].friend),
                    done: doneToday.contains(o),
                    selected: order == o,
                    onTap: doneToday.contains(o)
                        ? null
                        : () {
                            setState(() => order = o);
                            ref.say('order.${o + 1}');
                          },
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: SkyScene(
                image: 'art/backgrounds/playroom.webp',
                child: LayoutBuilder(
                  builder: (context, box) => DragTarget<String>(
                    onAcceptWithDetails: (d) {
                      final rb = context.findRenderObject() as RenderBox;
                      final local = rb.globalToLocal(d.offset + const Offset(48, 48));
                      _place(d.data, Offset((local.dx / box.maxWidth).clamp(.08, .92), (local.dy / box.maxHeight).clamp(.12, .9)));
                    },
                    builder: (context, cand, _) => Stack(
                      children: [
                        if (order != null)
                          Positioned(
                            left: 12,
                            top: 12,
                            child: DragTarget<String>(
                              onAcceptWithDetails: (d) => _give(d.data),
                              builder: (context, c2, _) =>
                                  HintGlow(on: c2.isNotEmpty, child: GameArt(data.orders[order!].friend, size: 110)),
                            ),
                          ),
                        for (final e in stage.entries)
                          Positioned(
                            left: e.value.dx * box.maxWidth - 48,
                            top: e.value.dy * box.maxHeight - 48,
                            child: GestureDetector(
                              onTap: () => _tapItem(e.key),
                              onLongPress: () => setState(() => stage.remove(e.key)),
                              child: Draggable<String>(
                                data: e.key,
                                feedback: GameArt(e.key, size: 96),
                                childWhenDragging: const SizedBox(width: 96, height: 96),
                                child: Bounce(
                                  trigger: bounce[e.key] ?? 0,
                                  child: GameArt(e.key, size: 96, label: data.item(e.key).title),
                                ),
                              ),
                            ),
                          ),
                        if (stage.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: PopoSays(
                                text: mine.isEmpty
                                    ? 'هنوز چیزی نساخته‌ای! از «ماجرا» شروع کن.'
                                    : 'چیزها را از قفسه این‌جا بکش و باهاشان بازی کن!',
                                pose: PopoPose.pointing,
                                size: 70,
                              ),
                            ),
                          ),
                        if (message != null)
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: ClayCard(
                              padding: const EdgeInsets.all(10),
                              child: Text(message!, style: PText.bodyStrong, textAlign: TextAlign.center),
                            ),
                          ),
                        Positioned.fill(child: Sparkles(trigger: burst)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // قفسه
        Container(
          height: 118,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: const Color(0xFFD7A86E),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFA9773F), width: 4),
          ),
          child: mine.isEmpty
              ? Center(
                  child: Text('قفسه خالی است', style: PText.heading.copyWith(color: Colors.white)),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(8),
                  children: [
                    for (final id in mine)
                      Draggable<String>(
                        data: id,
                        feedback: GameArt(id, size: 96),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GameArt(id, size: 92, label: data.item(id).title),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _OrderChip extends StatelessWidget {
  const _OrderChip({required this.order, required this.friend, required this.done, required this.selected, this.onTap});

  final OrderDef order;
  final Friend friend;
  final bool done;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    color: done ? G.green : (selected ? G.orange : Colors.white),
    radius: 22,
    depth: 4,
    semanticLabel: order.text,
    onTap: onTap,
    padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
    child: SizedBox(
      width: 210,
      child: Row(
        children: [
          GameArt(friend.id, size: 64),
          const SizedBox(width: 6),
          Expanded(
            child: done
                ? Text('انجام شد!', style: PText.label.copyWith(color: Colors.white))
                : Text(
                    order.text,
                    style: PText.caption.copyWith(color: selected ? Colors.white : G.ink, fontWeight: FontWeight.w700),
                    maxLines: 3,
                  ),
          ),
        ],
      ),
    ),
  );
}
