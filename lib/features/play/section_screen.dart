import 'dart:async';

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
import '../mascot/popo_mascot.dart';
import 'discover.dart';

enum _Phase { mission, step, made, discover, quiz, play, result }

/// یک بخش: مأموریت ← گام‌ها ← ساخته شد ← امتحان و کشف ← سؤال فکری ← بازی آزاد ← کوله‌پشتی و ستاره‌ها.
/// همین صفحه کیت‌های کارگاه ستاره و دستورهای ساخت ابزار را هم اجرا می‌کند.
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

  final run = RunStats();
  _Phase phase = _Phase.mission;
  int stepIndex = 0;
  EngineHost? host;
  SectionOutcome? outcome;
  int tries = 0;
  bool secretFound = false;

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
    final ch = chapter;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final audio = ref.read(audioProvider);
      // کیت‌ها و دستورهای ساخت ابزار در کارگاه‌اند.
      audio.startAmbient(ch?.ambient ?? 'audio/ambient/workshop.mp3');
      ref.say('${section.id}.mission');
    });
  }

  @override
  void dispose() {
    host?.dispose();
    _audio.stopAmbient();
    _audio.stopAll();
    super.dispose();
  }

  late final PopoAudio _audio = ref.read(audioProvider);

  void _startSteps() {
    run.clock.start();
    setState(() => phase = _Phase.step);
    _makeHost();
  }

  void _makeHost() {
    host?.dispose();
    final step = section.steps[stepIndex];
    if (step.engine == 'use' || step.engine == 'serve') ref.say('${section.id}.s${stepIndex + 1}');
    host = EngineHost(
      age: ref.read(activeProfileProvider)?.ageBand ?? AgeBand.preschool,
      data: data,
      backpack: backpack,
      onDone: _stepDone,
      onMistake: () => run.mistakes++,
      onPoints: (n) => run.points += n,
      onHint: (level) {
        run.hints++;
        ref.say(level == 2 ? 'game.hint.1' : 'game.hint.2');
      },
    )..start();
    if (step.engine != 'use' && step.engine != 'serve') ref.say('${section.id}.s${stepIndex + 1}');
  }

  void _stepDone() {
    if (!mounted) return;
    if (stepIndex + 1 < section.steps.length) {
      setState(() => stepIndex++);
      _makeHost();
      return;
    }
    run.clock.stop();
    setState(() => phase = _Phase.made);
    ref.read(audioProvider).ui(UiSound.success);
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
    });
    ref.read(audioProvider).ui(UiSound.sparkle);
    await ref.say('game.backpack');
    if (!mounted) return;
    await ref.say('game.stars.${o.stars}');
    if (o.fast && mounted) await ref.say('game.fast');
  }

  /// جای پنهانِ ابزار فروشگاهی (اگر کودک آن ابزار را دارد).
  bool get _hasSecret {
    final s = section.secret;
    return s != null && ref.watch(gameProvider).tools.contains(s) && !ref.watch(gameProvider).secrets.contains(section.id) && !secretFound;
  }

  Future<void> _findSecret() async {
    setState(() => secretFound = true);
    ref.read(audioProvider).ui(UiSound.sparkle);
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
    return Scaffold(
      body: SkyScene(
        image: ch?.background ?? (section.id.startsWith('k_') ? 'art/backgrounds/star_workshop.webp' : 'art/backgrounds/shop.webp'),
        night: ch?.night ?? false,
        dim: phase == _Phase.step ? .25 : .15,
        child: SafeArea(
          child: Column(
            children: [
              GameTopBar(
                title: section.title,
                light: true,
                onBack: () => context.go(_backRoute),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (phase == _Phase.step)
                      ClayIconButton(icon: Icons.lightbulb_rounded, label: 'راهنما', iconColor: G.orange, onTap: () => host?.raiseHint()),
                    const SizedBox(width: 6),
                    const WalletBar(),
                  ],
                ),
              ),
              if (phase == _Phase.step)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: StepDots(done: stepIndex, total: section.steps.length),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PopoSays(pose: phase == _Phase.result ? PopoPose.happy : PopoPose.idle, size: 64),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: KeyedSubtree(key: ValueKey('$phase$stepIndex'), child: _body(color)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(Widget child) => Container(
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .86), borderRadius: BorderRadius.circular(32), boxShadow: G.soft()),
    padding: const EdgeInsets.all(12),
    child: child,
  );

  Widget _body(Color color) {
    switch (phase) {
      case _Phase.mission:
        return Column(
          children: [
            Expanded(
              child: _card(
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [GameArt(friend, size: 150), const SizedBox(width: 8), GameArt(item.id, size: 120)],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SectionPill('می‌سازیم: ${item.title}', color: color),
                        const SizedBox(height: 12),
                        Text(section.mission, style: PText.title, textAlign: TextAlign.center),
                        if (section.needs.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('از کوله‌پشتی لازم می‌شود:', style: PText.caption),
                          Wrap(children: [for (final n in section.needs.toSet()) GameArt(n, size: 56, label: data.items[n]?.title)]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClayButton(label: 'شروع کنیم!', icon: Icons.play_arrow_rounded, color: G.orange, big: true, onTap: _startSteps),
          ],
        );
      case _Phase.step:
        final step = section.steps[stepIndex];
        return _card(buildEngine(step, host!, key: ValueKey('engine$stepIndex')));
      case _Phase.made:
        return Column(
          children: [
            Expanded(
              child: _card(
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(child: Sparkles(trigger: 1)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: .3, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (context, v, child) => Transform.scale(scale: v, child: child),
                          child: GameArt(item.id, size: 220, label: item.title),
                        ),
                        const SizedBox(height: 12),
                        Text('${item.title} آماده شد!', style: PText.display.copyWith(color: G.purple)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClayButton(
              label: 'امتحانش کنیم!',
              icon: Icons.touch_app_rounded,
              color: G.green,
              big: true,
              onTap: () => setState(() => phase = _Phase.discover),
            ),
          ],
        );
      case _Phase.discover:
        return Column(
          children: [
            Expanded(
              child: _card(
                Stack(
                  children: [
                    ItemShowcase(item: item, onTry: (n) => setState(() => tries = n)),
                    if (_hasSecret)
                      Positioned(
                        top: 0,
                        left: 0,
                        child: GestureDetector(
                          onTap: _findSecret,
                          child: Tooltip(
                            message: 'یک چیز پنهان!',
                            child: HintGlow(on: true, child: GameArt(section.secret!, size: 56)),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClayButton(
              label: 'فهمیدم!',
              icon: Icons.arrow_back_rounded,
              color: G.purple,
              onTap: tries > 0 ? () => setState(() => phase = _Phase.quiz) : null,
            ),
          ],
        );
      case _Phase.quiz:
        return _card(
          QuizView(
            item: item,
            onAnswered: (first) {
              if (first) run.points += Scoring.quizRight;
              if (!first) run.mistakes++;
              setState(() {
                tries = 0;
                phase = _Phase.play;
              });
              ref.say('game.play');
            },
          ),
        );
      case _Phase.play:
        return Column(
          children: [
            Expanded(
              child: _card(ItemShowcase(item: item, friend: friend, onTry: (n) => setState(() => tries = n))),
            ),
            const SizedBox(height: 12),
            ClayButton(label: 'بگذارش در کوله‌پشتی', icon: Icons.backpack_rounded, color: G.orange, onTap: _finish),
          ],
        );
      case _Phase.result:
        final o = outcome!;
        final last = chapter != null && chapter!.sections.last.id == section.id;
        return Column(
          children: [
            Expanded(
              child: _card(
                Stack(
                  children: [
                    Positioned.fill(child: Sparkles(trigger: o.stars)),
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                              decoration: BoxDecoration(color: G.green, borderRadius: BorderRadius.circular(18)),
                              child: Text(o.stars == 3 ? 'عالی!' : 'آفرین!', style: PText.display.copyWith(color: Colors.white)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(milliseconds: 500 + i * 250),
                                    curve: Curves.elasticOut,
                                    builder: (context, v, _) => Transform.scale(
                                      scale: i < o.stars ? v : 1,
                                      child: Icon(Icons.star_rounded, size: i == 1 ? 76 : 60, color: i < o.stars ? G.yellow : G.line),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                SectionPill('+${fa(o.coins)} سکه', color: G.orange),
                                SectionPill('${fa(run.seconds)} ثانیه', color: G.blue),
                                if (o.newRecord) const SectionPill('رکورد تازه!', color: G.pink),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.backpack_rounded, color: Color(0xFFB7791F), size: 40),
                                GameArt(item.id, size: 90),
                              ],
                            ),
                            Text('${item.title} به کوله‌پشتی رفت.', style: PText.heading),
                            if (o.stars < 3) ...[
                              const SizedBox(height: 6),
                              Text(_tip(), style: PText.caption, textAlign: TextAlign.center),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClayButton(
              label: last ? 'فیلم پایان فصل' : 'ادامه',
              icon: last ? Icons.movie_rounded : Icons.arrow_back_rounded,
              color: G.purple,
              onTap: _next,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClayButton(
                    label: 'دوباره',
                    icon: Icons.replay_rounded,
                    color: G.orange,
                    onTap: () => context.pushReplacement('/play/${section.id}?r=${DateTime.now().millisecondsSinceEpoch}'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  String _tip() {
    if (run.hints > 0) return 'دفعه‌ی بعد بدون راهنما امتحان کن تا ستاره‌ی بیشتری بگیری!';
    if (run.mistakes > 1) return 'با دقت بیشتر، ستاره‌ی بیشتری می‌گیری!';
    return 'کمی سریع‌تر، ستاره‌ی سوم مال توست!';
  }
}
