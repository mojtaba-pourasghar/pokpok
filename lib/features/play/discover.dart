import 'dart:async';
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
import '../mascot/popo_mascot.dart';

/// «امتحان و کشف»: شیء ساخته‌شده کار می‌کند. هر نوع شیء نمایش خودش را دارد:
/// خوراکی خورده می‌شود و مزه‌اش گفته می‌شود، ابزار روی هدفش کار می‌کند، وسیله‌ی نقلیه روشن
/// می‌شود و راه می‌افتد، ساز صدا می‌دهد، چراغ تاریکی را روشن می‌کند، ظرف پر می‌شود.
///
/// هر لمس یک بار نمایش را اجرا می‌کند؛ [onTry] تعداد لمس‌ها را خبر می‌دهد.
class ItemShowcase extends ConsumerStatefulWidget {
  const ItemShowcase({super.key, required this.item, this.onTry, this.friend, this.auto = false});

  final ItemDef item;
  final ValueChanged<int>? onTry;

  /// دوستی که در بازی آزاد غذا را می‌گیرد یا تماشا می‌کند.
  final String? friend;

  /// خودکار اجرا شود (فیلم پایان فصل).
  final bool auto;

  @override
  ConsumerState<ItemShowcase> createState() => _ItemShowcaseState();
}

class _ItemShowcaseState extends ConsumerState<ItemShowcase> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  int tries = 0;
  int bites = 0;
  bool fed = false;
  Timer? _auto;

  String get kind => widget.item.kind;
  bool get isFood => kind == 'food' || kind == 'drink';

  @override
  void initState() {
    super.initState();
    if (widget.auto) {
      _auto = Timer(const Duration(milliseconds: 500), _run);
    }
  }

  @override
  void dispose() {
    _auto?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _run() {
    if (!mounted) return;
    ref.read(audioProvider).play(widget.item.sound);
    setState(() {
      tries++;
      if (isFood) bites = (bites + 1) % 4;
    });
    _c.forward(from: 0);
    widget.onTry?.call(tries);
    if (isFood && tries == 1 && widget.item.taste != null) {
      ref.say('item.${widget.item.id}.taste');
    }
  }

  void _feed() {
    if (fed) return;
    setState(() => fed = true);
    ref.read(audioProvider).play(widget.item.sound);
    ref.sayOneOf('praise');
    widget.onTry?.call(++tries);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final size = math.min(s.width, s.height) * .5;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _run,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final t = _c.value;
            final running = _c.isAnimating;
            return Stack(
              alignment: Alignment.center,
              children: [
                ..._scene(t, running, s, size),
                if (isFood && widget.item.taste != null && tries > 0)
                  Positioned(top: 4, child: SectionPill('مزه: ${widget.item.taste}', color: G.orange)),
                if (tries == 0 && !widget.auto)
                  Positioned(
                    bottom: 8,
                    child: IgnorePointer(
                      child: Column(
                        children: [
                          const Text('👆', style: TextStyle(fontSize: 44)),
                          Text('لمس کن تا ببینی!', style: PText.heading.copyWith(color: G.purple)),
                        ],
                      ),
                    ),
                  ),
                if (widget.friend != null && isFood)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: DragTarget<String>(
                      onAcceptWithDetails: (_) => _feed(),
                      builder: (context, cand, _) => Column(
                        children: [
                          if (fed) const Icon(Icons.favorite_rounded, color: G.pink, size: 34),
                          AnimatedScale(
                            duration: const Duration(milliseconds: 200),
                            scale: cand.isNotEmpty ? 1.1 : 1,
                            child: GameArt(widget.friend!, size: size * .6),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
    },
  );

  Widget _art({double? size, double scale = 1}) {
    final w = GameArt(widget.item.id, size: size ?? 160, label: widget.item.title);
    if (widget.friend != null && isFood && !fed) {
      return Draggable<String>(
        data: widget.item.id,
        feedback: GameArt(widget.item.id, size: (size ?? 160) * .7),
        childWhenDragging: const SizedBox.shrink(),
        child: w,
      );
    }
    return Transform.scale(scale: scale, child: w);
  }

  List<Widget> _scene(double t, bool running, Size s, double size) {
    final pulse = running ? math.sin(t * math.pi) : 0.0;
    switch (kind) {
      case 'food':
      case 'drink':
        // پوپو گاز می‌زند؛ شیء کوچک‌تر می‌شود و دوباره پر.
        return [
          Positioned(
            left: s.width * .06,
            bottom: 0,
            child: PopoMascot(pose: running ? PopoPose.happy : PopoPose.curious, size: size * .9),
          ),
          Transform.translate(
            offset: Offset(-pulse * s.width * .12, 0),
            child: _art(size: size, scale: 1 - bites * .12 - pulse * .1),
          ),
          if (running)
            Positioned(
              top: s.height * .2,
              child: Opacity(
                opacity: pulse,
                child: Text(kind == 'drink' ? '😋 هورت!' : '😋 اوم!', style: PText.display.copyWith(color: G.orange)),
              ),
            ),
        ];
      case 'tool':
        // ابزار روی هدفش ضربه می‌زند: میخ پایین می‌رود.
        final hit = running ? (math.sin(t * math.pi * 4)).abs() : 0.0;
        return [
          Positioned(
            bottom: s.height * .1,
            child: GameArt('plank', size: size * 1.1),
          ),
          Positioned(
            bottom: s.height * .1 + size * .45 - tries.clamp(0, 3) * 10.0,
            child: GameArt(widget.item.target ?? 'nail', size: size * .35),
          ),
          Positioned(
            bottom: s.height * .1 + size * .55,
            left: s.width / 2 - size * .1,
            child: Transform.rotate(
              angle: -.9 + hit * .9,
              alignment: Alignment.bottomLeft,
              child: _art(size: size * .8),
            ),
          ),
          if (running && hit > .9)
            Positioned(
              top: s.height * .18,
              child: Text('تق!', style: PText.display.copyWith(color: G.red)),
            ),
        ];
      case 'light':
      case 'lookout':
        // تاریکی؛ با لمس روشن می‌شود و ستاره‌ها پیدا می‌شوند.
        final on = tries > 0;
        return [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              color: on ? const Color(0xFF3549B8) : const Color(0xFF0D1030),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          if (on)
            for (var i = 0; i < 9; i++)
              Positioned(
                left: (i * 97 % 100) / 100 * s.width * .9,
                top: (i * 53 % 100) / 100 * s.height * .6,
                child: Opacity(opacity: .4 + .6 * ((t + i / 9) % 1), child: GameArt(kind == 'lookout' ? 'star' : 'firefly', size: 34)),
              ),
          if (on)
            Container(
              width: size * 1.6,
              height: size * 1.6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0xAAFFF3B0), Color(0x00FFF3B0)]),
              ),
            ),
          _art(size: size, scale: 1 + pulse * .08),
          if (kind == 'lookout' && on)
            Positioned(
              top: 10,
              right: s.width * .1,
              child: GameArt('moon', size: size * .5),
            ),
        ];
      case 'vehicle':
      case 'cart':
      case 'rocket':
      case 'submarine':
        // روشن شدن: لرزش و دود، بعد حرکت و برگشت.
        final shake = running && t < .3 ? math.sin(t * 120) * 4 : 0.0;
        final dx = running && t >= .3 ? math.sin((t - .3) / .7 * math.pi) * s.width * .32 : 0.0;
        final dy = kind == 'rocket' && running ? -math.sin((t - .3).clamp(0, 1) / .7 * math.pi) * s.height * .4 : 0.0;
        return [
          if (kind != 'rocket')
            Positioned(
              bottom: s.height * .18,
              left: 0,
              right: 0,
              child: Container(
                height: 14,
                decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(7)),
              ),
            ),
          if (running && t < .5)
            for (var i = 0; i < 3; i++)
              Positioned(
                right: s.width / 2 + size * .45 + i * 18,
                bottom: s.height * .22 + i * 14 + t * 60,
                child: Opacity(
                  opacity: (1 - t * 2).clamp(0, 1),
                  child: const Icon(Icons.cloud_rounded, color: Colors.white, size: 34),
                ),
              ),
          Transform.translate(
            offset: Offset(-dx + shake, dy),
            child: _art(size: size),
          ),
          if (running && t > .25 && t < .6)
            Positioned(
              top: s.height * .12,
              child: Text(kind == 'rocket' ? '۳، ۲، ۱... پرواز!' : 'برووووم!', style: PText.display.copyWith(color: G.blue)),
            ),
        ];
      case 'instrument':
      case 'song':
        return [
          _art(size: size, scale: 1 + pulse * .12),
          if (running)
            for (var i = 0; i < 5; i++)
              Positioned(
                left: s.width / 2 + math.cos(i * 1.3) * size * (.4 + t * .5),
                top: s.height / 2 - size * .2 - t * s.height * .35 - i * 8,
                child: Opacity(
                  opacity: 1 - t,
                  child: Icon(Icons.music_note_rounded, size: 40, color: [G.purple, G.pink, G.blue, G.orange, G.green][i]),
                ),
              ),
        ];
      case 'container':
        // ظرف پر می‌شود و چیزی نمی‌ریزد.
        return [
          _art(size: size),
          if (running)
            for (var i = 0; i < 6; i++)
              Positioned(
                left: s.width / 2 - 40 + i * 14,
                top: s.height * .05 + ((t * 2 + i / 6) % 1) * size * .7,
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF4FC3F7), size: 26),
              ),
          if (tries > 0)
            Positioned(
              bottom: s.height * .12,
              child: GameArt('q_flowers', size: size * .45),
            ),
        ];
      case 'plant':
        return [
          _art(size: size, scale: .8 + (tries > 0 ? .2 : t * .2)),
          if (running || tries > 0)
            Positioned(
              left: s.width / 2 + math.cos(t * math.pi * 2) * size * .55,
              top: s.height / 2 - size * .3 + math.sin(t * math.pi * 4) * 20,
              child: GameArt('bee', size: size * .3),
            ),
        ];
      case 'shelter':
        return [
          _art(size: size),
          if (running)
            for (var i = 0; i < 12; i++)
              Positioned(
                left: (i * 37 % 100) / 100 * s.width,
                top: ((t * 1.5 + i / 12) % 1) * s.height * .55,
                child: const Icon(Icons.water_drop_rounded, color: Color(0xFF64B5F6), size: 20),
              ),
          if (tries > 0)
            Positioned(
              bottom: 0,
              child: PopoMascot(pose: PopoPose.happy, size: size * .5),
            ),
        ];
      case 'map':
        return [
          _art(size: size * 1.2),
          if (running)
            Positioned(
              left: s.width * (.2 + .6 * t),
              top: s.height * (.5 + math.sin(t * math.pi * 2) * .15),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: G.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
            ),
        ];
      default:
        // کاردستی و بقیه: می‌چرخد و می‌درخشد.
        return [
          Transform.rotate(
            angle: running ? math.sin(t * math.pi * 2) * .15 : 0,
            child: _art(size: size, scale: 1 + pulse * .15),
          ),
          Positioned.fill(child: Sparkles(trigger: tries)),
        ];
    }
  }
}

/// سؤال فکری «با این چه کار می‌کنیم؟» با سه تصویر.
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
                  for (final i in order)
                    Shake(
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
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
