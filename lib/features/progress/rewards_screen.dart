import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/fa.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/common.dart';

/// دفتر خاطره‌ها: برچسب‌های جمع‌شده و آخرین بازی‌ها. بدون رتبه، بدون مقایسه، بدون «روزهای پشت سر هم».
class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.say(ref.read(progressProvider).stickers.isEmpty ? 'rewards.empty' : 'rewards.hello');
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final progress = ref.watch(progressProvider);
    final mine = [
      for (final s in content.stickers.values)
        if (progress.stickers.contains(s.id)) s,
    ];
    final recent = progress.history.take(6).toList();
    return PScaffold(
      title: 'خاطره‌های من',
      color: PColors.tint(PColors.yellow, .28),
      body: mine.isEmpty
          ? StateView(
              state: ViewState.empty,
              message: 'هنوز برچسبی نداری. بیا بازی کنیم!',
              actionLabel: 'بریم!',
              onAction: () => context.go('/map'),
            )
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(PSpace.md),
                  sliver: SliverToBoxAdapter(child: Text('برچسب‌های من (${faDigits(mine.length)})', style: PText.heading)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: PSpace.md),
                  sliver: SliverGrid.count(
                    crossAxisCount: (MediaQuery.sizeOf(context).width / 130).floor().clamp(3, 8),
                    mainAxisSpacing: PSpace.sm,
                    crossAxisSpacing: PSpace.sm,
                    childAspectRatio: .82,
                    children: [
                      for (final s in mine)
                        Semantics(
                          label: 'برچسب ${s.title}',
                          child: Container(
                            padding: const EdgeInsets.all(PSpace.xs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(PRadius.md),
                              border: Border.all(color: PColors.yellow, width: 3),
                              boxShadow: PShadow.soft(),
                            ),
                            child: Column(
                              children: [
                                Expanded(child: ArtImage(s.art)),
                                Text(
                                  s.title,
                                  style: PText.caption.copyWith(color: PColors.ink),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (recent.isNotEmpty) ...[
                  const SliverPadding(
                    padding: EdgeInsets.all(PSpace.md),
                    sliver: SliverToBoxAdapter(child: Text('بازی‌های اخیر', style: PText.heading)),
                  ),
                  SliverList.list(
                    children: [
                      for (final h in recent)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: 4),
                          child: PCard(
                            padding: const EdgeInsets.all(PSpace.sm),
                            child: Row(
                              children: [
                                const Icon(Icons.history_rounded, color: PColors.purple),
                                const SizedBox(width: PSpace.sm),
                                Expanded(child: Text(h.title, style: PText.bodyStrong)),
                                Text(faRelativeDay(h.at), style: PText.caption),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: PSpace.xl),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
