import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../game/engines/engine.dart';
import '../../game/game_data.dart';
import '../../ui/clay.dart';
import '../../ui/fx.dart';
import 'scenes/craft_scene.dart';
import 'scenes/drive_scene.dart';
import 'scenes/eat_scene.dart';
import 'scenes/light_scene.dart';
import 'scenes/music_scene.dart';
import 'scenes/toy_scene.dart';
import 'scenes/tool_scene.dart';
import 'scenes/water_scene.dart';

/// «امتحان و کشف»: شیء ساخته‌شده در یک صحنه‌ی تعاملی متحرک کار می‌کند — هر نوع شیء صحنه‌ی خودش را
/// دارد (scenes/). همین صحنه‌ها در بازی آزاد ([play]) و فیلم پایان فصل ([auto]) هم به کار می‌روند.
class ItemShowcase extends StatelessWidget {
  const ItemShowcase({super.key, required this.item, this.onTry, this.friend, this.auto = false, this.play = false});

  final ItemDef item;
  final ValueChanged<int>? onTry;
  final String? friend;
  final bool auto;
  final bool play;

  @override
  Widget build(BuildContext context) => switch (item.kind) {
    'food' || 'drink' => EatScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    'tool' => ToolScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    'vehicle' || 'cart' || 'rocket' || 'submarine' => DriveScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    'light' || 'lookout' || 'find' => LightScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    'instrument' || 'song' => MusicScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    'container' || 'plant' || 'shelter' => WaterScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    'craft' || 'letter' || 'map' || 'medal' => CraftScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
    _ => ToyScene(item: item, friend: friend, onTry: onTry, auto: auto, play: play),
  };
}

class QuizView extends ConsumerStatefulWidget {
  const QuizView({super.key, required this.item, required this.onAnswered});

  final ItemDef item;

  /// true اگر بار اول درست جواب داد.
  final ValueChanged<bool> onAnswered;

  @override
  ConsumerState<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends ConsumerState<QuizView> {
  late final order = [for (var i = 0; i < widget.item.quiz.options.length; i++) i]..shuffle(math.Random(widget.item.id.hashCode));
  bool firstTry = true;
  int? right;
  final Map<int, int> shakes = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.say('item.${widget.item.id}.quiz'));
  }

  void _pick(int i) {
    if (right != null) return;
    if (i == widget.item.quiz.answer) {
      setState(() => right = i);
      context.fx(Fx.confetti, count: 30);
      ref.read(audioProvider).ui(UiSound.success);
      ref.say('game.quiz.right').then((_) {
        if (mounted) ref.say('item.${widget.item.id}.use');
      });
      Future.delayed(const Duration(milliseconds: 2400), () => widget.onAnswered(firstTry));
    } else {
      firstTry = false;
      setState(() => shakes[i] = (shakes[i] ?? 0) + 1);
      ref.read(audioProvider).ui(UiSound.softNo);
      ref.say('game.quiz.wrong');
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.item.quiz;
    return Column(
      children: [
        ClayCard(
          child: Row(
            children: [
              GameArt(widget.item.id, size: 64),
              const SizedBox(width: 10),
              Expanded(
                child: Text(q.question, style: PText.title.copyWith(color: G.purple)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = math.min((box.maxWidth - 32) / 3, box.maxHeight * .8);
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final (k, i) in order.indexed)
                    PopIn(
                      delay: Duration(milliseconds: 250 + k * 180),
                      child: Shake(
                        trigger: shakes[i] ?? 0,
                        child: GestureDetector(
                          onTap: () => _pick(i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            width: w,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: right == i ? const Color(0xFFE6F8EC) : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: right == i ? G.green : Colors.white, width: 5),
                              boxShadow: G.soft(),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GameArt(q.options[i].art, size: w * .8),
                                const SizedBox(height: 6),
                                Text(q.options[i].label, style: PText.label, textAlign: TextAlign.center, maxLines: 2),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
