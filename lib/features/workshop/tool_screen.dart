import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../ui/clay.dart';
import '../mascot/popo_mascot.dart';

/// یک ابزار فروشگاه: معرفی (کار کردن و صدا، جمله‌ی ایمنی)، خرید با سکه، و دستورهای ساختی که باز می‌کند.
/// اگر سکه کم باشد، می‌گوید چقدر مانده و راه گرفتن سکه را پیشنهاد می‌کند.
class ToolScreen extends ConsumerStatefulWidget {
  const ToolScreen({super.key, required this.toolId});

  final String toolId;

  @override
  ConsumerState<ToolScreen> createState() => _ToolScreenState();
}

class _ToolScreenState extends ConsumerState<ToolScreen> with SingleTickerProviderStateMixin {
  late final ToolDef tool = ref.read(gameDataProvider).tools.firstWhere((t) => t.id == widget.toolId);
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _demo() {
    ref.read(audioProvider).play(tool.sound);
    _c.forward(from: 0);
  }

  Future<void> _buy() async {
    final ok = await ref.read(gameProvider.notifier).buy(tool);
    if (!mounted) return;
    if (!ok) {
      ref.read(audioProvider).ui(UiSound.softNo);
      await ref.say('game.coins.low');
      return;
    }
    ref.read(audioProvider).ui(UiSound.success);
    _demo();
    await ref.say('shop.bought');
    if (mounted) await ref.say('tool.${tool.id}.safety');
  }

  @override
  Widget build(BuildContext context) {
    final g = ref.watch(gameProvider);
    final data = ref.watch(gameDataProvider);
    final owned = g.tools.contains(tool.id);
    final missing = math.max(0, tool.price - g.coins);
    return Scaffold(
      body: SkyScene(
        image: 'art/backgrounds/shop.webp',
        dim: .15,
        child: SafeArea(
          child: Column(
            children: [
              GameTopBar(title: tool.title, light: true, onBack: () => context.canPop() ? context.pop() : context.go('/home?tab=workshop')),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    ClayCard(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: owned ? _demo : null,
                            child: AnimatedBuilder(
                              animation: _c,
                              builder: (context, child) => Transform.rotate(angle: math.sin(_c.value * math.pi * 4) * .25, child: child),
                              child: GameArt(tool.id, size: 180, label: tool.title),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.health_and_safety_rounded, color: G.green),
                              const SizedBox(width: 6),
                              Expanded(child: Text(tool.safety, style: PText.bodyStrong)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (owned)
                            Text('این ابزار مال توست! لمسش کن تا کار کند.', style: PText.heading.copyWith(color: G.green))
                          else ...[
                            ClayButton(
                              label: 'خرید با ${fa(tool.price)} سکه',
                              icon: Icons.monetization_on_rounded,
                              color: missing == 0 ? G.orange : G.locked,
                              onTap: _buy,
                            ),
                            if (missing > 0) ...[
                              const SizedBox(height: 10),
                              PopoSays(
                                text: '${fa(missing)} سکه‌ی دیگر لازم داری. یک بخش را دوباره بازی کن یا سفارش‌های اتاق بازی را انجام بده!',
                                pose: PopoPose.thinking,
                                size: 60,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SectionPill(owned ? 'با این ابزار بساز' : 'بعد از خرید می‌توانی بسازی'),
                    const SizedBox(height: 10),
                    for (final r in tool.recipes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Pressable(
                          color: owned ? G.teal : G.locked,
                          radius: 24,
                          semanticLabel: data.item(r.makes).title,
                          onTap: owned ? () => context.push('/play/${r.id}') : null,
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              GameArt(r.makes, size: 80),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(data.item(r.makes).title, style: PText.heading.copyWith(color: Colors.white)),
                              ),
                              StarRow(stars: g.starsOf(r.id)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
