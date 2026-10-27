import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/widgets/common.dart';
import '../../game/game_state.dart';
import '../../game/scoring.dart';
import '../../ui/clay.dart';
import 'home_shell.dart';

/// زبانه‌ی «من»: نمایه، مرتبه‌ی سازنده، ستاره‌ها و سکه‌ها، پیشرفت فصل‌ها و فیلم‌های من.
class MeTab extends ConsumerWidget {
  const MeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final g = ref.watch(gameProvider);
    final data = ref.watch(gameDataProvider);
    final gate = ref.watch(gateProvider);
    final rank = g.rank;
    final next = rank.next;
    final doneSections = data.chapters.fold(0, (a, c) => a + gate.chapterDoneCount(c));
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        ClayCard(
          child: Row(
            children: [
              if (profile != null) ArtImage(profile.avatar, size: 72),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(profile?.name ?? 'کوچولو', style: PText.title.copyWith(color: G.purple)),
                    SectionPill(rank.title, color: G.orange),
                    if (next != null) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ((g.lifetimeCoins - rank.from) / (next.from - rank.from)).clamp(0, 1),
                          minHeight: 10,
                          backgroundColor: G.line,
                          color: G.orange,
                        ),
                      ),
                      Text('تا «${next.title}»: ${fa(next.from - g.lifetimeCoins)} سکه', style: PText.caption),
                    ],
                  ],
                ),
              ),
              ClayIconButton(icon: Icons.switch_account_rounded, label: 'عوض کردن بازیکن', onTap: () => context.push('/profiles')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _Stat(icon: Icons.star_rounded, color: G.yellow, value: g.stars, label: 'ستاره'),
            const SizedBox(width: 10),
            _Stat(icon: Icons.monetization_on_rounded, color: G.orange, value: g.coins, label: 'سکه'),
            const SizedBox(width: 10),
            _Stat(icon: Icons.flag_rounded, color: G.green, value: doneSections, label: 'از ${fa(data.totalSections)} بخش'),
          ],
        ),
        const SizedBox(height: 16),
        const SectionPill('فصل‌ها'),
        const SizedBox(height: 8),
        ClayCard(
          child: Column(
            children: [
              for (final c in data.chapters)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      GameArt(c.friend, size: 40),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.title, style: PText.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const Icon(Icons.star_rounded, color: G.yellow, size: 20),
                      Text(' ${fa(gate.chapterStars(c))}/${fa(c.sections.length * 3)}', style: PText.caption),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SectionPill('فیلم‌های من', color: G.pink),
        const SizedBox(height: 8),
        if (g.films.isEmpty)
          const Text('هر فصل را که تمام کنی، فیلمش این‌جا می‌آید.', style: PText.caption)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in data.chapters)
                if (g.films.contains(c.id))
                  Pressable(
                    color: G.hex(c.color),
                    radius: 22,
                    semanticLabel: 'فیلم ${c.title}',
                    onTap: () => context.push('/film/${c.id}'),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        GameArt(c.friend, size: 70),
                        const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                      ],
                    ),
                  ),
            ],
          ),
        const SizedBox(height: 16),
        const SectionPill('ابزارهای من', color: G.blue),
        const SizedBox(height: 8),
        Wrap(
          children: [
            for (final t in data.tools)
              if (g.tools.contains(t.id)) GameArt(t.id, size: 64, label: t.title),
          ],
        ),
        if (g.tools.isEmpty) const Text('از «کارگاه ← فروشگاه ابزار» با سکه ابزار بخر.', style: PText.caption),
        const SizedBox(height: 20),
        ClayButton(label: 'بخش والدین', icon: Icons.lock_rounded, color: G.inkSoft, onTap: () => context.push('/parent')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  final IconData icon;
  final Color color;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: ClayCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          Text(fa(value), style: PText.title),
          Text(label, style: PText.caption, textAlign: TextAlign.center, maxLines: 1),
        ],
      ),
    ),
  );
}

/// برای استفاده در جاهای دیگر: نام مرتبه.
String rankTitle(int lifetimeCoins) => MakerRank.of(lifetimeCoins).title;
