import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/narrator.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../ui/clay.dart';
import '../paywall/paywall.dart';

/// زبانه‌ی کارگاه: «کارگاه ستاره» (کیت‌هایی که با جمع ستاره‌ها باز می‌شوند) و «فروشگاه ابزار»
/// (ابزارهایی که با سکه خریده می‌شوند). هیچ‌کدام برای تمام کردن داستان لازم نیستند.
class WorkshopTab extends ConsumerStatefulWidget {
  const WorkshopTab({super.key});

  @override
  ConsumerState<WorkshopTab> createState() => _WorkshopTabState();
}

class _WorkshopTabState extends ConsumerState<WorkshopTab> {
  bool shop = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider);
    final g = ref.watch(gameProvider);
    final access = ref.watch(accessProvider);
    final paid = access.owned || !access.paywall;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Text('کارگاه', style: PText.display.copyWith(color: G.purple, fontSize: 28)),
              const Spacer(),
              const WalletBar(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _Segment(label: 'کیت‌های ستاره', icon: Icons.star_rounded, on: !shop, onTap: () => setState(() => shop = false)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Segment(
                  label: 'فروشگاه ابزار',
                  icon: Icons.storefront_rounded,
                  on: shop,
                  onTap: () {
                    setState(() => shop = true);
                    ref.say('shop.hello');
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: .78,
            children: shop
                ? [for (final t in data.tools) _ToolCard(tool: t, owned: g.tools.contains(t.id), coins: g.coins)]
                : [
                    for (final (i, k) in data.kits.indexed)
                      _KitCard(kit: k, stars: g.stars, done: g.starsOf(k.section.id), locked: !paid && i > 1),
                  ],
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.icon, required this.on, required this.onTap});

  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    color: on ? G.purple : Colors.white,
    depth: 4,
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: on ? G.yellow : G.purple),
        const SizedBox(width: 6),
        Text(label, style: PText.label.copyWith(color: on ? Colors.white : G.purple)),
      ],
    ),
  );
}

class _KitCard extends ConsumerWidget {
  const _KitCard({required this.kit, required this.stars, required this.done, required this.locked});

  final KitDef kit;
  final int stars;

  /// ستاره‌های خود این کیت (اگر ساخته شده).
  final int done;

  /// پشت نسخه‌ی کامل.
  final bool locked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final open = stars >= kit.stars;
    final item = ref.watch(gameDataProvider).item(kit.section.makes);
    return Pressable(
      color: open ? G.teal : G.locked,
      radius: 28,
      semanticLabel: '${item.title}، ${open ? 'باز' : 'با ${fa(kit.stars)} ستاره باز می‌شود'}',
      onTap: () {
        if (!open) {
          ref.say('game.locked');
          return;
        }
        if (locked) {
          ref.say('full.locked');
          showPaywall(context);
          return;
        }
        context.push('/play/${kit.section.id}');
      },
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(opacity: open ? 1 : .45, child: GameArt(item.id, size: 120)),
                if (!open) const Icon(Icons.lock_rounded, color: Colors.white, size: 44),
                if (open && locked) const Positioned(top: 0, right: 0, child: Icon(Icons.workspace_premium_rounded, color: G.yellow)),
              ],
            ),
          ),
          Text(item.title, style: PText.heading.copyWith(color: Colors.white), maxLines: 1),
          const SizedBox(height: 4),
          if (open)
            StarRow(stars: done, size: 22)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: G.yellow, size: 22),
                Text(' ${fa(stars)} / ${fa(kit.stars)}', style: PText.label.copyWith(color: Colors.white)),
              ],
            ),
        ],
      ),
    );
  }
}

class _ToolCard extends ConsumerWidget {
  const _ToolCard({required this.tool, required this.owned, required this.coins});

  final ToolDef tool;
  final bool owned;
  final int coins;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Pressable(
    color: owned ? G.blue : Colors.white,
    radius: 28,
    semanticLabel: '${tool.title}، ${owned ? 'خریده شده' : '${fa(tool.price)} سکه'}',
    onTap: () => context.push('/tool/${tool.id}'),
    padding: const EdgeInsets.all(10),
    child: Column(
      children: [
        Expanded(child: GameArt(tool.id, size: 120)),
        Text(tool.title, style: PText.heading.copyWith(color: owned ? Colors.white : G.ink), maxLines: 1),
        const SizedBox(height: 4),
        if (owned)
          Text('${fa(tool.recipes.length)} چیز تازه برای ساختن', style: PText.caption.copyWith(color: Colors.white))
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.monetization_on_rounded, color: coins >= tool.price ? G.orange : G.locked, size: 22),
              Text(' ${fa(tool.price)}', style: PText.label.copyWith(color: coins >= tool.price ? G.ink : G.inkSoft)),
            ],
          ),
      ],
    ),
  );
}
