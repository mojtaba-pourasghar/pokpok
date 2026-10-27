import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/narrator.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../ui/clay.dart';
import '../mascot/popo_mascot.dart';
import '../playroom/playroom_tab.dart';
import '../workshop/workshop_tab.dart';
import 'me_tab.dart';

/// خانه با چهار زبانه (مثل گوش‌یار): ماجرا (فصل‌ها)، کارگاه (کیت‌ها و ابزارها)، اتاق بازی، من.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.tab});

  final String? tab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  static const tabs = ['story', 'workshop', 'playroom', 'me'];
  late int index = tabs.indexOf(widget.tab ?? 'story').clamp(0, tabs.length - 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      ref.read(audioProvider).startMusic('audio/music/menu_loop.mp3');
      final bonus = await ref.read(gameProvider.notifier).dailyBonus();
      if (!mounted) return;
      if (bonus > 0) {
        await _showBonus(bonus);
      } else if (index == 0) {
        await ref.say('home.hello');
      }
    });
  }

  /// جایزه‌ی امروز: نوار بالای صفحه (نه پنجره، تا بازی را قطع نکند). با لمس بسته می‌شود.
  int bonus = 0;

  Future<void> _showBonus(int coins) async {
    setState(() => bonus = coins);
    await ref.say('game.daily');
  }

  void _select(int i) {
    setState(() {
      index = i;
      bonus = 0;
    });
    ref.read(audioProvider).stopAll();
    switch (tabs[i]) {
      case 'workshop':
        ref.say('workshop.hello');
      case 'playroom':
        ref.say('playroom.hello');
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (tabs[index]) {
      'workshop' => const WorkshopTab(),
      'playroom' => const PlayroomTab(),
      'me' => const MeTab(),
      _ => const StoryTab(),
    };
    final streak = ref.watch(gameProvider).streak;
    return Scaffold(
      body: SkyScene(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (bonus > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: GestureDetector(
                    onTap: () => setState(() => bonus = 0),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) => Transform.scale(scale: v, child: child),
                      child: ClayCard(
                        border: G.yellow,
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const PopoMascot(pose: PopoPose.happy, size: 64),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('جایزه‌ی امروز!', style: PText.heading.copyWith(color: G.purple)),
                                  Text('روز ${fa(streak)} پشت سر هم؛ روز هفتم ۵۰ سکه!', style: PText.caption),
                                ],
                              ),
                            ),
                            SectionPill('+${fa(bonus)} سکه', color: G.orange),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              Expanded(child: body),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(index: index, onTap: _select),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  static const items = [
    (Icons.auto_stories_rounded, 'ماجرا'),
    (Icons.handyman_rounded, 'کارگاه'),
    (Icons.toys_rounded, 'اتاق بازی'),
    (Icons.face_rounded, 'من'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: G.soft(),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: [
            for (final (i, (icon, label)) in items.indexed)
              Expanded(
                child: Semantics(
                  selected: i == index,
                  button: true,
                  label: label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == index ? G.purpleSoft : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: i == index ? G.purple : G.inkSoft, size: 28),
                          Text(
                            label,
                            style: PText.caption.copyWith(color: i == index ? G.purple : G.inkSoft, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// قفل‌ها: فصل بعدی بعد از تمام شدن فصل قبل، بخش بعدی بعد از بخش قبل. در debug همه باز.
/// نسخه‌ی رایگان: کل فصل ۱ و بخش اول هر فصل.
class Gate {
  Gate(this.data, this.progress, {required this.open, required this.paid});

  final GameData data;
  final GameProgress progress;

  /// همه‌چیز باز (اجرای debug).
  final bool open;

  /// نسخه‌ی کامل خریده شده یا دیوار پرداخت خاموش است.
  final bool paid;

  bool chapterDone(ChapterDef c) => c.sections.every((s) => progress.done(s.id));

  bool chapterOpen(ChapterDef c) => open || c.index == 0 || chapterDone(data.chapters[c.index - 1]);

  bool sectionOpen(ChapterDef c, int i) => open || (chapterOpen(c) && (i == 0 || progress.done(c.sections[i - 1].id)));

  bool needsPurchase(ChapterDef c, int i) => !paid && c.index > 0 && i > 0;

  int chapterStars(ChapterDef c) => c.sections.fold(0, (a, s) => a + progress.starsOf(s.id));
  int chapterDoneCount(ChapterDef c) => c.sections.where((s) => progress.done(s.id)).length;
}

final gateProvider = Provider<Gate>((ref) {
  final access = ref.watch(accessProvider);
  return Gate(ref.watch(gameDataProvider), ref.watch(gameProvider), open: access.everythingOpen, paid: access.owned || !access.paywall);
});

/// زبانه‌ی ماجرا: سلام پوپو و فهرست فصل‌ها (کارت‌های رنگی مثل «بازی‌ها و مأموریت‌ها»ی گوش‌یار).
class StoryTab extends ConsumerWidget {
  const StoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final gate = ref.watch(gateProvider);
    final name = ref.watch(activeProfileProvider)?.name ?? 'دوست من';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            ClayIconButton(icon: Icons.settings_rounded, label: 'بخش والدین', onTap: () => context.push('/parent')),
            const Spacer(),
            const WalletBar(),
          ],
        ),
        const SizedBox(height: 8),
        Text('سلام $name!', style: PText.display.copyWith(color: G.purple, fontSize: 28)),
        const SizedBox(height: 4),
        const PopoSays(text: 'طوفان همه‌چیز جشن جنگل را به هم ریخته. بیا با هم درستش کنیم!', pose: PopoPose.welcome, size: 84),
        const SizedBox(height: 12),
        _FestivalMap(gate: gate),
        const SizedBox(height: 16),
        const SectionPill('فصل‌ها'),
        const SizedBox(height: 10),
        for (final c in data.chapters)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ChapterCard(chapter: c, gate: gate),
          ),
      ],
    );
  }
}

/// نقشه‌ی جشن: هشت تکه که با تمام شدن هر فصل روشن می‌شوند.
class _FestivalMap extends ConsumerWidget {
  const _FestivalMap({required this.gate});

  final Gate gate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider);
    final done = data.chapters.where(gate.chapterDone).length;
    return ClayCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.celebration_rounded, color: G.pink),
              const SizedBox(width: 6),
              Expanded(
                child: Text('نقشه‌ی جشن بزرگ', style: PText.heading.copyWith(color: G.purple)),
              ),
              Text('${fa(done)} از ${fa(data.chapters.length)}', style: PText.caption),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final c in data.chapters)
                Expanded(
                  child: AspectRatio(
                    aspectRatio: .8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: gate.chapterDone(c) ? G.hex(c.color) : G.line,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: gate.chapterDone(c)
                          ? Text(data.friend(c.friend).emoji, style: const TextStyle(fontSize: 22))
                          : const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChapterCard extends ConsumerWidget {
  const ChapterCard({super.key, required this.chapter, required this.gate});

  final ChapterDef chapter;
  final Gate gate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = gate.chapterOpen(chapter);
    final color = G.hex(chapter.color);
    final done = gate.chapterDoneCount(chapter);
    final total = chapter.sections.length;
    return Pressable(
      color: open ? color : G.locked,
      radius: 28,
      semanticLabel: 'فصل ${fa(chapter.index + 1)}: ${chapter.title}${open ? '' : '، قفل'}',
      onTap: () {
        if (open) {
          context.push('/chapter/${chapter.id}');
        } else {
          ref.say('game.locked');
        }
      },
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .25), borderRadius: BorderRadius.circular(22)),
            child: open ? GameArt(chapter.friend, size: 88) : const Icon(Icons.lock_rounded, color: Colors.white, size: 44),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('فصل ${fa(chapter.index + 1)}', style: PText.caption.copyWith(color: Colors.white70)),
                Text(
                  chapter.title,
                  style: PText.heading.copyWith(color: Colors.white, fontSize: 19),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(value: done / total, minHeight: 10, backgroundColor: Colors.white24, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${fa(done)} از ${fa(total)} بخش',
                        style: PText.caption.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.star_rounded, color: G.yellow, size: 20),
                    Text(' ${fa(gate.chapterStars(chapter))}/${fa(total * 3)}', style: PText.caption.copyWith(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 32),
        ],
      ),
    );
  }
}
