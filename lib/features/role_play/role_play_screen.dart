import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../mascot/popo_mascot.dart';
import '../worlds/scene_view.dart';

/// نقش‌آفرینی (آشپزی، خرید، باغبانی، مراقبت از حیوان، مرتب کردن اتاق).
/// همان موتور صحنه با «اهداف»؛ بدون زمان‌سنج و بدون شکست: هر تلاش یا نتیجه می‌دهد یا آرام برمی‌گردد.
class RolePlayScreen extends ConsumerStatefulWidget {
  const RolePlayScreen({super.key, required this.sceneId});

  final String sceneId;

  @override
  ConsumerState<RolePlayScreen> createState() => _RolePlayScreenState();
}

class _RolePlayScreenState extends ConsumerState<RolePlayScreen> with ActivitySession {
  late final scene = ref.read(contentProvider).scenes[widget.sceneId];
  final _key = GlobalKey<SceneViewState>();
  bool _done = false;
  int _round = 0;

  @override
  String get activityId => widget.sceneId;
  @override
  String get activityTitle => scene?.title ?? widget.sceneId;
  @override
  String? get resumeRoute => '/play/${widget.sceneId}';

  Future<void> _celebrate() async {
    setState(() => _done = true);
    await ref.read(progressProvider.notifier).complete(widget.sceneId);
    await ref.say(scene?.done);
    if (scene?.sticker != null) await award(scene!.sticker!);
  }

  void _again() => setState(() {
    _done = false;
    _round++;
  });

  @override
  Widget build(BuildContext context) {
    final s = scene;
    if (s == null) {
      return const PScaffold(
        title: 'پیدا نشد',
        body: StateView(state: ViewState.empty, message: 'این بازی پیدا نشد.'),
      );
    }
    final reduced = ref.watch(settingsProvider.select((x) => x.reducedMotion));
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SceneView(key: ValueKey('${s.id}#$_round'), scene: s, onGoalsDone: _celebrate),
          ),
          SafeArea(
            child: Column(
              children: [
                PTopBar(
                  title: s.title,
                  light: true,
                  actions: [
                    PIconButton(
                      icon: Icons.pause_rounded,
                      label: 'مکث',
                      iconColor: PColors.orange,
                      onPressed: () => showPauseSheet(context, ref, onReset: _again),
                    ),
                  ],
                ),
                _GoalBar(sceneKey: _key, hint: s.hint, want: s.want, round: _round),
              ],
            ),
          ),
          const SafeArea(
            child: Padding(padding: EdgeInsets.only(top: 140), child: CaptionBubble()),
          ),
          if (_done)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: .25),
                child: Center(
                  child: PCard(
                    padding: const EdgeInsets.all(PSpace.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopoMascot(pose: PopoPose.happy, size: 160, reducedMotion: reduced),
                        Text('آفرین!', style: PText.display.copyWith(color: PColors.orange)),
                        if (s.sticker != null) ...[
                          const SizedBox(height: PSpace.xs),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ArtImage(ref.read(contentProvider).stickers[s.sticker]?.art ?? 'sun', size: 44),
                              const SizedBox(width: PSpace.xs),
                              Text('برچسب «${ref.read(contentProvider).stickers[s.sticker]?.title ?? ''}»', style: PText.bodyStrong),
                            ],
                          ),
                        ],
                        const SizedBox(height: PSpace.md),
                        Wrap(
                          spacing: PSpace.sm,
                          runSpacing: PSpace.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            PButton(label: 'دوباره', icon: Icons.refresh_rounded, color: PColors.orange, onPressed: _again),
                            PButton(
                              label: 'بازی‌های دیگر',
                              icon: Icons.apps_rounded,
                              color: PColors.blue,
                              onPressed: () => context.go('/library'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// راهنمای هدف (تصویر چیزهای لازم برای فهرست خرید + متن کوتاه).
class _GoalBar extends ConsumerWidget {
  const _GoalBar({required this.sceneKey, required this.hint, required this.want, required this.round});

  final GlobalKey<SceneViewState> sceneKey;
  final String? hint;
  final List<String> want;
  final int round;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (hint == null && want.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PSpace.md),
      padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: PSpace.xs),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(PRadius.pill),
        boxShadow: PShadow.soft(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final w in want) Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: ArtImage(w, size: 36)),
          if (want.isNotEmpty) const SizedBox(width: PSpace.xs),
          if (hint != null)
            Flexible(
              child: Text(hint!, style: PText.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
            ),
        ],
      ),
    );
  }
}
