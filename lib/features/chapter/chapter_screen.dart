import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/narrator.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../ui/clay.dart';
import '../home/home_shell.dart';
import '../mascot/popo_mascot.dart';
import '../paywall/paywall.dart';

/// نقشه‌ی یک فصل (مثل نقشه‌ی مرحله‌های گوش‌یار): دایره‌های بخش‌ها روی یک راه پیچان، با ستاره‌ها.
class ChapterScreen extends ConsumerStatefulWidget {
  const ChapterScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends ConsumerState<ChapterScreen> {
  late final ChapterDef chapter = ref.read(gameDataProvider).chapter(widget.chapterId);

  @override
  void initState() {
    super.initState();
    _audio;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(audioProvider).startAmbient(chapter.ambient);
      final started = chapter.sections.any((s) => ref.read(gameProvider).done(s.id));
      if (!started) ref.say('${chapter.id}.intro');
    });
  }

  late final _audio = ref.read(audioProvider);

  @override
  void dispose() {
    _audio.stopAmbient();
    super.dispose();
  }

  void _open(int i, Gate gate) {
    final s = chapter.sections[i];
    if (!gate.sectionOpen(chapter, i)) {
      ref.say('game.locked');
      return;
    }
    if (gate.needsPurchase(chapter, i)) {
      ref.say('full.locked');
      showPaywall(context);
      return;
    }
    context.push('/play/${s.id}');
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(gateProvider);
    final g = ref.watch(gameProvider);
    final color = G.hex(chapter.color);
    final done = gate.chapterDone(chapter);
    return Scaffold(
      body: SkyScene(
        image: chapter.background,
        night: chapter.night,
        dim: .12,
        child: SafeArea(
          child: Column(
            children: [
              GameTopBar(title: chapter.title, light: true, onBack: () => context.canPop() ? context.pop() : context.go('/home')),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GameArt(chapter.friend, size: 84),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClayCard(
                        padding: const EdgeInsets.all(12),
                        child: Text(chapter.intro, style: PText.bodyStrong, maxLines: 3, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final n = chapter.sections.length;
                    final r = math.min(box.maxWidth * .17, 74.0);
                    // بخش اول پایین، آخر بالا؛ جای ستاره‌ها و نام زیر هر دایره هم حساب شده.
                    final top = r + 8, bottom = box.maxHeight - r - 64;
                    Offset at(int i) {
                      final t = n == 1 ? .5 : i / (n - 1);
                      return Offset(box.maxWidth * (i.isEven ? .3 : .7), bottom - t * (bottom - top));
                    }

                    return Stack(
                      children: [
                        CustomPaint(size: Size(box.maxWidth, box.maxHeight), painter: _TrailPainter([for (var i = 0; i < n; i++) at(i)])),
                        for (var i = 0; i < n; i++) _node(i, at(i), r, gate, color),
                        // پوپو کنار بخش بعدی.
                        Builder(
                          builder: (context) {
                            final next = chapter.sections.indexWhere((s) => !g.done(s.id));
                            if (next < 0) return const SizedBox.shrink();
                            final p = at(next);
                            return Positioned(
                              left: p.dx + (next.isEven ? r * .8 : -r * 2.3),
                              top: p.dy - r * 1.4,
                              child: const IgnorePointer(child: PopoMascot(pose: PopoPose.pointing, size: 96)),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
              if (done)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: ClayButton(
                    label: 'فیلم پایان فصل',
                    icon: Icons.movie_rounded,
                    color: G.pink,
                    onTap: () => context.push('/film/${chapter.id}'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _node(int i, Offset p, double r, Gate gate, Color color) {
    final s = chapter.sections[i];
    final open = gate.sectionOpen(chapter, i);
    final paid = gate.needsPurchase(chapter, i);
    final stars = ref.watch(gameProvider).starsOf(s.id);
    final done = ref.watch(gameProvider).done(s.id);
    return Positioned(
      left: p.dx - r,
      top: p.dy - r,
      width: r * 2,
      child: Column(
        children: [
          Pressable(
            color: open ? (done ? G.green : color) : G.locked,
            depth: 7,
            semanticLabel: 'بخش ${fa(i + 1)}: ${s.title}${open ? '' : '، قفل'}',
            onTap: () => _open(i, gate),
            child: SizedBox(
              width: r * 2,
              height: r * 2 - 7,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withValues(alpha: .7), width: 4),
                    ),
                  ),
                  if (open) GameArt(s.makes, size: r * 1.35) else const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
                  if (open && paid)
                    const Positioned(top: 6, right: 6, child: Icon(Icons.workspace_premium_rounded, color: G.yellow, size: 26)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          StarRow(stars: stars, size: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
            child: Text(s.title, style: PText.label.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final p = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      p.cubicTo(a.dx, (a.dy + b.dy) / 2, b.dx, (a.dy + b.dy) / 2, b.dx, b.dy);
    }
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.round,
    );
    final dash = Paint()
      ..color = const Color(0xFFFFC83D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final m in p.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 28) {
        canvas.drawPath(m.extractPath(d, d + 12), dash);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => old.points != points;
}
