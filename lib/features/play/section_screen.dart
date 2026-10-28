import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../data/models/models.dart';
import '../../game/engines/engines.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../game/scoring.dart';
import '../../ui/clay.dart';
import '../../ui/fx.dart';
import '../../ui/popo_corner.dart';
import '../mascot/popo_mascot.dart';
import 'discover.dart';

enum _Phase { mission, step, made, discover, quiz, play, result }

/// یک بخش: مأموریت ← گام‌ها ← ساخته شد ← امتحان و کشف ← سؤال فکری ← بازی آزاد ← کوله‌پشتی و ستاره‌ها.
/// همین صفحه کیت‌های کارگاه ستاره و دستورهای ساخت ابزار را هم اجرا می‌کند.
///
/// صحنه تمام‌صفحه است (پس‌زمینه‌ی فصل دیده می‌شود)، پوپو بزرگ در گوشه حرف می‌زند و با هر کار درست،
/// اشتباه یا راهنما ژستش عوض می‌شود؛ بین گام‌ها یک جشن کوچک هست.
class SectionScreen extends ConsumerStatefulWidget {
  const SectionScreen({super.key, required this.sectionId});

  final String sectionId;

  @override
  ConsumerState<SectionScreen> createState() => _SectionScreenState();
}

class _SectionScreenState extends ConsumerState<SectionScreen> with ActivitySession {
  late final GameData data = ref.read(gameDataProvider);
  late final SectionDef section = data.sections[widget.sectionId]!;
  late final ChapterDef? chapter = data.chapterOf(section.id);
  late final ItemDef item = data.item(section.makes);
  late final Set<String> backpack = ref.read(gameProvider).backpack;
  late final PopoAudio _audio = ref.read(audioProvider);
  final _fx = GlobalKey<FxLayerState>();
  final _stage = GlobalKey();

  final run = RunStats();
  _Phase phase = _Phase.mission;
  int stepIndex = 0;
  EngineHost? host;
  SectionOutcome? outcome;
  int tries = 0;
  bool secretFound = false;
  bool cheering = false;

  PopoPose pose = PopoPose.welcome;
  Timer? _poseTimer;

  @override
  String get activityId => 'section:${section.id}';
  @override
  String get activityTitle => section.title;
  @override
  String? get resumeRoute => '/play/${section.id}';

  String get friend => chapter?.friend ?? 'bear';

  @override
  void initState() {
    super.initState();
    _audio;
    // همه‌ی صداهای این بخش از پیش بارگذاری می‌شوند تا هیچ‌کدام دیر یا بریده پخش نشود.
    _audio.preload(
      {
        item.sound,
        for (final s in section.steps) ...[
          if (s.opt('sound') != null) s.str('sound'),
          for (final p in s.maps('pads')) p['sound'] as String,
          if (s.engine == 'use') data.items[s.str('need')]?.sound ?? '',
        ],
        for (final u in UiSound.values) u.path,
      }.where((p) => p.isNotEmpty),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // کیت‌ها و دستورهای ساخت ابزار در کارگاه‌اند.
      _audio.startAmbient(chapter?.ambient ?? 'audio/ambient/workshop.ogg');
      ref.say('${section.id}.mission');
    });
  }

  @override
  void dispose() {
    _poseTimer?.cancel();
    host?.dispose();
    _audio.stopAmbient();
    _audio.stopAll();
    super.dispose();
  }

  /// ژست کوتاه پوپو و بعد برگشت به حالت عادی.
  void _react(PopoPose p, {int ms = 1300}) {
    _poseTimer?.cancel();
    setState(() => pose = p);
    _poseTimer = Timer(Duration(milliseconds: ms), () {
      if (mounted) setState(() => pose = phase == _Phase.step ? PopoPose.curious : PopoPose.idle);
    });
  }

  Offset get _stageCenter => _stage.currentContext?.globalCenter ?? Offset.zero;

  void _startSteps() {
    run.clock.start();
    setState(() {
      phase = _Phase.step;
      pose = PopoPose.curious;
    });
    _makeHost();
  }

  void _makeHost() {
    host?.dispose();
    final step = section.steps[stepIndex];
    host = EngineHost(
      age: ref.read(activeProfileProvider)?.ageBand ?? AgeBand.preschool,
      data: data,
      backpack: backpack,
      onDone: _stepDone,
      onMistake: () {
        run.mistakes++;
        _react(PopoPose.thinking);
      },
      onRight: () {
        if (pose != PopoPose.happy) _react(PopoPose.happy, ms: 700);
      },
      onPoints: (n) => run.points += n,
      onHint: (level) {
        run.hints++;
        _react(PopoPose.pointing, ms: 2500);
        ref.say(level == 2 ? 'game.hint.1' : 'game.hint.2');
      },
    )..start();
    ref.say('${section.id}.s${stepIndex + 1}');
    if (step.engine == 'use' || step.engine == 'serve') _react(PopoPose.thinking, ms: 2000);
  }

  Future<void> _stepDone() async {
    if (!mounted) return;
    // جشن کوچک بین گام‌ها
    setState(() => cheering = true);
    _react(PopoPose.happy, ms: 1400);
    _fx.currentState?.burst(_stageCenter, Fx.confetti, count: 30);
    _fx.currentState?.burst(_stageCenter, Fx.sparkle);
    _audio.ui(UiSound.success);
    unawaited(ref.sayOneOf('praise'));
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => cheering = false);
    if (stepIndex + 1 < section.steps.length) {
      setState(() => stepIndex++);
      _makeHost();
      return;
    }
    run.clock.stop();
    setState(() => phase = _Phase.made);
    _audio.ui(UiSound.sparkle);
    _fx.currentState?.burst(_stageCenter, Fx.confetti, count: 60);
    ref.say('item.${item.id}.made');
  }

  Future<void> _finish() async {
    final age = ref.read(activeProfileProvider)?.ageBand ?? AgeBand.preschool;
    final target = Scoring.targetFor(section.targetSec, age, timeOn: ref.read(appPrefsProvider).timedStars);
    final o = await ref.read(gameProvider.notifier).finish(section, run, target: target);
    if (!mounted) return;
    setState(() {
      outcome = o;
      phase = _Phase.result;
      pose = PopoPose.happy;
    });
    _audio.ui(UiSound.sparkle);
    await ref.say('game.backpack');
    if (!mounted) return;
    await ref.say('game.stars.${o.stars}');
    if (o.fast && mounted) await ref.say('game.fast');
  }

  /// جای پنهانِ ابزار فروشگاهی (اگر کودک آن ابزار را دارد).
  bool get _hasSecret {
    final s = section.secret;
    final g = ref.watch(gameProvider);
    return s != null && g.tools.contains(s) && !g.secrets.contains(section.id) && !secretFound;
  }

  Future<void> _findSecret(BuildContext at) async {
    setState(() => secretFound = true);
    at.fx(Fx.sparkle, count: 20);
    _audio.ui(UiSound.sparkle);
    await ref.read(gameProvider.notifier).findSecret(section.id);
    await ref.say('game.secret');
  }

  // ── ناوبری بعد از نتیجه ─────────────────────────────────────────────────────
  String get _backRoute {
    final ch = chapter;
    if (ch != null) return '/chapter/${ch.id}';
    if (section.id.startsWith('k_')) return '/home?tab=workshop';
    final tool = data.tools.where((t) => t.recipes.any((r) => r.id == section.id)).firstOrNull;
    return tool == null ? '/home' : '/tool/${tool.id}';
  }

  void _next() {
    final ch = chapter;
    if (ch == null) {
      context.go(_backRoute);
      return;
    }
    final i = ch.sections.indexWhere((s) => s.id == section.id);
    final g = ref.read(gameProvider);
    if (i == ch.sections.length - 1) {
      // آخرین بخش فصل: فیلم پایان فصل (بار اول خودکار).
      context.go(g.films.contains(ch.id) ? '/chapter/${ch.id}' : '/film/${ch.id}');
    } else {
      context.go('/chapter/${ch.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ch = chapter;
    final color = ch == null ? G.purple : G.hex(ch.color);
    final reduced = ref.watch(settingsProvider).reducedMotion;
    final button = _button(color);
    return Scaffold(
      body: FxLayer(
        key: _fx,
        reduced: reduced,
        child: SkyScene(
          image: ch?.background ?? (section.id.startsWith('k_') ? 'art/backgrounds/star_workshop.webp' : 'art/backgrounds/shop.webp'),
          night: ch?.night ?? false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // کمی تیرگی بالا و پایین تا نوار و حباب خوانا باشند؛ وسط صحنه روشن می‌ماند.
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x55000000), Color(0x00000000), Color(0x00000000), Color(0x44000000)],
                      stops: [0, .18, .7, 1],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    _topBar(color),
                    if (phase == _Phase.step) _StepBar(steps: section.steps, index: stepIndex, color: color),
                    Expanded(
                      child: Padding(
                        key: _stage,
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 450),
                          switchInCurve: Curves.easeOutCubic,
                          transitionBuilder: (child, a) => FadeTransition(
                            opacity: a,
                            child: SlideTransition(
                              position: Tween(begin: const Offset(-.15, 0), end: Offset.zero).animate(a),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(key: ValueKey('$phase$stepIndex'), child: _body(color)),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                      child: PopoCorner(pose: pose, size: phase == _Phase.step ? 92 : 112),
                    ),
                    if (button != null) Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 14), child: button),
                  ],
                ),
              ),
              if (cheering) const IgnorePointer(child: Center(child: _Cheer())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(Color color) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
    child: Row(
      children: [
        ClayIconButton(icon: Icons.arrow_forward_rounded, label: 'برگشت', onTap: () => context.go(_backRoute)),
        const SizedBox(width: 8),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GameArt(item.id, size: 30),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    section.title,
                    style: PText.heading.copyWith(color: color, fontSize: 17),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (phase == _Phase.step) ...[
          ClayIconButton(icon: Icons.lightbulb_rounded, label: 'راهنما', iconColor: G.orange, onTap: () => host?.raiseHint()),
          const SizedBox(width: 6),
        ],
        const WalletBar(),
      ],
    ),
  );

  /// دکمه‌ی پایین هر مرحله (در گام‌ها دکمه‌ای نیست؛ خود بازی جلو می‌برد).
  Widget? _button(Color color) => switch (phase) {
    _Phase.mission => ClayButton(label: 'شروع کنیم!', icon: Icons.play_arrow_rounded, color: G.orange, big: true, onTap: _startSteps),
    _Phase.made => ClayButton(
      label: 'امتحانش کنیم!',
      icon: Icons.touch_app_rounded,
      color: G.green,
      big: true,
      onTap: () => setState(() {
        phase = _Phase.discover;
        pose = PopoPose.curious;
      }),
    ),
    _Phase.discover => ClayButton(
      label: tries >= 2 ? 'فهمیدم!' : 'بیشتر امتحان کن',
      icon: tries >= 2 ? Icons.check_rounded : Icons.touch_app_rounded,
      color: tries >= 2 ? G.purple : G.locked,
      onTap: tries >= 2 ? () => setState(() => phase = _Phase.quiz) : null,
    ),
    _Phase.play => ClayButton(label: 'بگذارش در کوله‌پشتی', icon: Icons.backpack_rounded, color: G.orange, onTap: _finish),
    _Phase.result => Row(
      children: [
        Expanded(
          child: ClayButton(
            label: 'دوباره',
            icon: Icons.replay_rounded,
            color: G.orange,
            onTap: () => context.pushReplacement('/play/${section.id}?r=${DateTime.now().millisecondsSinceEpoch}'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ClayButton(
            label: chapter != null && chapter!.sections.last.id == section.id ? 'فیلم فصل' : 'ادامه',
            icon: Icons.arrow_back_rounded,
            color: G.purple,
            onTap: _next,
          ),
        ),
      ],
    ),
    _ => null,
  };

  Widget _body(Color color) {
    switch (phase) {
      case _Phase.mission:
        return _MissionScene(friend: friend, item: item, section: section, data: data);
      case _Phase.step:
        return buildEngine(section.steps[stepIndex], host!, key: ValueKey('engine$stepIndex'));
      case _Phase.made:
        return _MadeScene(item: item);
      case _Phase.discover:
        return Stack(
          children: [
            ItemShowcase(item: item, friend: friend, onTry: (n) => setState(() => tries = n)),
            if (_hasSecret)
              Positioned(
                top: 0,
                left: 0,
                child: Builder(
                  builder: (c) => GestureDetector(
                    onTap: () => _findSecret(c),
                    child: Tooltip(
                      message: 'یک چیز پنهان!',
                      child: HintGlow(on: true, child: GameArt(section.secret!, size: 60)),
                    ),
                  ),
                ),
              ),
          ],
        );
      case _Phase.quiz:
        return QuizView(
          item: item,
          onAnswered: (first) {
            if (first) run.points += Scoring.quizRight;
            if (!first) run.mistakes++;
            setState(() {
              tries = 0;
              phase = _Phase.play;
              pose = PopoPose.happy;
            });
            ref.say('game.play');
          },
        );
      case _Phase.play:
        return ItemShowcase(item: item, friend: friend, play: true, onTry: (n) => setState(() => tries = n));
      case _Phase.result:
        return _ResultScene(outcome: outcome!, run: run, item: item, tip: _tip());
    }
  }

  String _tip() {
    if (run.hints > 0) return 'دفعه‌ی بعد بدون راهنما امتحان کن تا ستاره‌ی بیشتری بگیری!';
    if (run.mistakes > 1) return 'با دقت بیشتر، ستاره‌ی بیشتری می‌گیری!';
    return 'کمی سریع‌تر، ستاره‌ی سوم مال توست!';
  }
}

/// نوار گام‌ها: هر گام یک دایره با نماد کارش؛ گام فعلی بزرگ‌تر، گام‌های تمام‌شده سبز.
class _StepBar extends StatelessWidget {
  const _StepBar({required this.steps, required this.index, required this.color});

  final List<StepDef> steps;
  final int index;
  final Color color;

  static IconData icon(String engine) => switch (engine) {
    'collect' || 'whack' => Icons.touch_app_rounded,
    'sort' => Icons.compare_arrows_rounded,
    'cut' => Icons.content_cut_rounded,
    'tap' => Icons.back_hand_rounded,
    'rotate' => Icons.rotate_right_rounded,
    'pour' => Icons.water_drop_rounded,
    'timing' => Icons.timer_rounded,
    'assemble' || 'stack' => Icons.extension_rounded,
    'order' => Icons.format_list_numbered_rounded,
    'count' => Icons.pin_rounded,
    'paint' || 'mix' => Icons.palette_rounded,
    'scrub' => Icons.cleaning_services_rounded,
    'dark' => Icons.flashlight_on_rounded,
    'trace' || 'drive' || 'connect' => Icons.gesture_rounded,
    'rhythm' => Icons.music_note_rounded,
    'puzzle' || 'memory' => Icons.grid_view_rounded,
    'use' || 'serve' => Icons.backpack_rounded,
    'catch' => Icons.shopping_basket_rounded,
    'feed' => Icons.restaurant_rounded,
    'blow' => Icons.air_rounded,
    _ => Icons.star_rounded,
  };

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Flexible(
              child: Container(
                height: 5,
                constraints: const BoxConstraints(maxWidth: 22),
                decoration: BoxDecoration(color: i <= index ? G.green : Colors.white70, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: i == index ? 42 : 30,
            height: i == index ? 42 : 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < index ? G.green : (i == index ? color : Colors.white),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: G.soft(),
            ),
            child: Icon(
              i < index ? Icons.check_rounded : icon(steps[i].engine),
              size: i == index ? 22 : 16,
              color: i <= index ? Colors.white : G.locked,
            ),
          ),
        ],
      ],
    ),
  );
}

/// «آفرین!» بزرگ وسط صفحه بین گام‌ها.
class _Cheer extends StatelessWidget {
  const _Cheer();

  @override
  Widget build(BuildContext context) => PopIn(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
      decoration: BoxDecoration(
        color: G.green,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 5),
        boxShadow: G.soft(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 8),
          Text('آفرین!', style: PText.display.copyWith(color: Colors.white)),
        ],
      ),
    ),
  );
}

/// صحنه‌ی مأموریت: دوست فصل در صحنه، ابر فکرش چیزی که باید ساخت؛ و آنچه از کوله لازم است.
class _MissionScene extends StatelessWidget {
  const _MissionScene({required this.friend, required this.item, required this.section, required this.data});

  final String friend;
  final ItemDef item;
  final SectionDef section;
  final GameData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth * .55, box.maxHeight * .62);
      return Stack(
        children: [
          Positioned(
            right: box.maxWidth * .06,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Idle(
                  seed: 3,
                  child: PopIn(child: GameArt(friend, size: s)),
                ),
                GroundShadow(width: s * .7),
              ],
            ),
          ),
          Positioned(
            left: box.maxWidth * .04,
            top: box.maxHeight * .04,
            child: PopIn(
              delay: const Duration(milliseconds: 350),
              child: _ThoughtCloud(
                size: s * .78,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Idle(seed: 7, amount: .6, child: GameArt(item.id, size: s * .42)),
                    Text(item.title, style: PText.heading.copyWith(color: G.purple)),
                  ],
                ),
              ),
            ),
          ),
          if (section.needs.isNotEmpty)
            Positioned(
              left: 0,
              bottom: 8,
              child: PopIn(
                delay: const Duration(milliseconds: 700),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE9C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0A100), width: 3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.backpack_rounded, color: Color(0xFFB7791F)),
                      for (final n in section.needs.toSet()) GameArt(n, size: 46, label: data.items[n]?.title),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ThoughtCloud extends StatelessWidget {
  const _ThoughtCloud({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size * .9,
    child: Stack(
      children: [
        Positioned.fill(
          bottom: size * .12,
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size), boxShadow: G.soft()),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(padding: const EdgeInsets.all(14), child: child),
            ),
          ),
        ),
        Positioned(
          right: size * .12,
          bottom: size * .04,
          child: const CircleAvatar(radius: 11, backgroundColor: Colors.white),
        ),
        Positioned(
          right: size * .02,
          bottom: -2,
          child: const CircleAvatar(radius: 6, backgroundColor: Colors.white),
        ),
      ],
    ),
  );
}

/// «ساخته شد!»: پرتوهای چرخان پشت شیء، ورود فنری.
class _MadeScene extends StatefulWidget {
  const _MadeScene({required this.item});

  final ItemDef item;

  @override
  State<_MadeScene> createState() => _MadeSceneState();
}

class _MadeSceneState extends State<_MadeScene> with SingleTickerProviderStateMixin {
  late final AnimationController _rays = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();

  @override
  void dispose() {
    _rays.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight) * .62;
      return Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _rays,
            builder: (context, _) => Transform.rotate(
              angle: _rays.value * math.pi * 2,
              child: CustomPaint(size: Size.square(s * 1.7), painter: _RaysPainter()),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PopIn(
                child: Idle(
                  seed: 2,
                  child: GameArt(widget.item.id, size: s, label: widget.item.title),
                ),
              ),
              PopIn(
                delay: const Duration(milliseconds: 300),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
                  child: Text('${widget.item.title} آماده شد!', style: PText.title.copyWith(color: G.purple)),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2;
    final paint = Paint()
      ..shader = const RadialGradient(colors: [Color(0xCCFFF3B0), Color(0x00FFF3B0)]).createShader(Rect.fromCircle(center: c, radius: r));
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + math.cos(a - .12) * r, c.dy + math.sin(a - .12) * r)
        ..lineTo(c.dx + math.cos(a + .12) * r, c.dy + math.sin(a + .12) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_RaysPainter old) => false;
}

/// نتیجه: ستاره‌ها یکی‌یکی می‌آیند، سکه‌ها شمرده می‌شوند، شیء به کوله پرواز می‌کند.
class _ResultScene extends ConsumerStatefulWidget {
  const _ResultScene({required this.outcome, required this.run, required this.item, required this.tip});

  final SectionOutcome outcome;
  final RunStats run;
  final ItemDef item;
  final String tip;

  @override
  ConsumerState<_ResultScene> createState() => _ResultSceneState();
}

class _ResultSceneState extends ConsumerState<_ResultScene> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..forward();
  final _starKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final _bag = GlobalKey();
  int _shown = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      final n = (_c.value * 4).floor().clamp(0, widget.outcome.stars);
      while (_shown < n) {
        _starKeys[_shown].currentContext?.fx(Fx.sparkle, count: 16);
        ref.read(audioProvider).ui(UiSound.chime);
        _shown++;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final fx = FxScope.of(context);
      final bag = _bag.currentContext?.globalCenter;
      if (fx != null && bag != null) {
        fx.fly(
          widget.item.id,
          context.globalCenter,
          bag,
          size: 120,
          ms: 900,
          arc: 160,
          endScale: .35,
          onLand: () {
            _bag.currentContext?.fx(Fx.sparkle);
            ref.read(audioProvider).ui(UiSound.pop);
          },
        );
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.outcome;
    return Center(
      child: SingleChildScrollView(
        child: ClayCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final coins = (o.coins * Curves.easeOut.transform(((_c.value - .5) / .5).clamp(0.0, 1.0))).round();
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(o.stars == 3 ? 'عالی!' : 'آفرین!', style: PText.display.copyWith(color: G.green)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Transform.translate(
                          offset: Offset(0, i == 1 ? -10 : 0),
                          child: Transform.scale(
                            key: _starKeys[i],
                            scale: i < o.stars ? Curves.elasticOut.transform(((_c.value * 4) - i - .2).clamp(0.0, 1.0)) : 1,
                            child: Icon(Icons.star_rounded, size: i == 1 ? 84 : 66, color: i < o.stars ? G.yellow : G.line),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      CountChip(icon: Icons.monetization_on_rounded, value: coins, color: G.orange, label: 'سکه'),
                      CountChip(icon: Icons.timer_rounded, value: widget.run.seconds, color: G.blue, label: 'ثانیه'),
                      if (o.newRecord) const SectionPill('رکورد تازه!', color: G.pink),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Squash(
                        trigger: _c.value > .6 ? 1 : 0,
                        child: Icon(Icons.backpack_rounded, key: _bag, color: const Color(0xFFB7791F), size: 56),
                      ),
                      const SizedBox(width: 8),
                      Flexible(child: Text('${widget.item.title} به کوله‌پشتی رفت.', style: PText.heading)),
                    ],
                  ),
                  if (o.stars < 3) ...[const SizedBox(height: 6), Text(widget.tip, style: PText.caption, textAlign: TextAlign.center)],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
