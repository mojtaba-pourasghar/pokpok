import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/content/content.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../mascot/popo_mascot.dart';
import '../profiles/profiles_screen.dart';
import '../worlds/backgrounds/scene_backgrounds.dart';

/// نقشه‌ی دنیای پوپو: شش جای مصور که هر کدام جهان جدایی است.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider)
        ..stopAmbient()
        ..startMusic('audio/music/menu_loop.mp3');
      final p = ref.read(progressProvider);
      ref.say(p.lastWorld == null ? 'app.map.hello' : 'app.map.back');
      _checkTimeLimit();
    });
  }

  /// سقف زمان روزانه: پوپو خسته می‌شود و پیشنهاد استراحت می‌دهد؛ بازی قفل نمی‌شود و کودک
  /// تنبیه نمی‌شود. والدین سقف را از بخش «زمان استفاده» تنظیم می‌کنند.
  void _checkTimeLimit() {
    final limit = ref.read(appPrefsProvider).dailyLimitMinutes;
    if (limit <= 0) return;
    if (ref.read(progressProvider.notifier).todaySeconds() >= limit * 60) {
      ref.say('session.sleepy');
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PopoMascot(pose: PopoPose.sleepy, size: 140, reducedMotion: ref.read(settingsProvider).reducedMotion),
              const SizedBox(height: PSpace.sm),
              const Text('پوپو کمی خسته است', style: PText.title, textAlign: TextAlign.center),
              const Text('وقت بازی امروز تمام شد. فردا دوباره بازی می‌کنیم!', style: PText.body, textAlign: TextAlign.center),
              const SizedBox(height: PSpace.md),
              PButton(label: 'باشه', color: PColors.purple, onPressed: () => Navigator.pop(ctx)),
            ],
          ),
        ),
      );
    }
  }

  void _open(WorldDef w) {
    ref.read(progressProvider.notifier).visitWorld(w.id);
    context.push(w.route);
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final profile = ref.watch(activeProfileProvider);
    final progress = ref.watch(progressProvider);
    final settings = ref.watch(settingsProvider);
    final soundOn = settings.musicOn || settings.effectsOn;
    final worlds = content.worlds;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final u = size.shortestSide;
          final cardW = (u * .34).clamp(118.0, 220.0);
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: SceneBackground(id: 'map', points: [for (final w in worlds) Offset(w.mapX, w.mapY)]),
              ),
              for (final w in worlds)
                Positioned(
                  left: (w.mapX * size.width - cardW / 2).clamp(4, size.width - cardW - 4),
                  top: (w.mapY * size.height - cardW * .55).clamp(70, size.height - cardW * 1.2),
                  width: cardW,
                  child: WorldCard(world: w, onTap: () => _open(w), visited: progress.stickers.contains('world.${w.id}')),
                ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(PSpace.sm),
                    child: Row(
                      children: [
                        if (profile != null)
                          Semantics(
                            button: true,
                            label: 'نمایه: ${profile.name}. برای عوض کردن لمس کن',
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: () => context.push('/profiles'),
                              child: Container(
                                padding: const EdgeInsetsDirectional.fromSTEB(4, 4, PSpace.md, 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(PRadius.pill),
                                  boxShadow: PShadow.soft(),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ProfileAvatar(profile: profile, size: 48),
                                    const SizedBox(width: PSpace.xs),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 110),
                                      child: Text(profile.name, style: PText.bodyStrong, overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        PIconButton(
                          icon: Icons.apps_rounded,
                          label: 'همه‌ی بازی‌ها',
                          iconColor: PColors.turquoise,
                          onPressed: () => context.push('/library'),
                        ),
                        const SizedBox(width: PSpace.xs),
                        PIconButton(
                          icon: Icons.star_rounded,
                          label: 'برچسب‌ها و خاطره‌ها',
                          iconColor: PColors.yellow,
                          onPressed: () => context.push('/rewards'),
                          badge: progress.stickers.isEmpty ? null : _Badge(progress.stickers.length),
                        ),
                        const SizedBox(width: PSpace.xs),
                        PIconButton(
                          icon: soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          label: soundOn ? 'خاموش کردن صدا' : 'روشن کردن صدا',
                          iconColor: PColors.purple,
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .update((s) => s.copyWith(musicOn: !soundOn, effectsOn: !soundOn, ambientOn: !soundOn)),
                        ),
                        const SizedBox(width: PSpace.xs),
                        PIconButton(
                          icon: Icons.lock_rounded,
                          label: 'بخش والدین',
                          iconColor: PColors.inkSoft,
                          onPressed: () => context.push('/parent'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (progress.lastRoute != null)
                PositionedDirectional(
                  bottom: PSpace.md + MediaQuery.paddingOf(context).bottom,
                  start: PSpace.md,
                  child: _ContinueChip(route: progress.lastRoute!),
                ),
              PositionedDirectional(
                bottom: MediaQuery.paddingOf(context).bottom,
                end: 0,
                child: IgnorePointer(
                  child: PopoMascot(
                    pose: PopoPose.pointing,
                    pointRight: false,
                    size: math.min(u * .32, 170),
                    reducedMotion: settings.reducedMotion,
                  ),
                ),
              ),
              const SafeArea(
                child: Padding(padding: EdgeInsets.only(top: 64), child: CaptionBubble()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.n);

  final int n;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(
      color: PColors.orange,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: Text(
      '$n'.replaceAllMapped(RegExp(r'\d'), (m) => '۰۱۲۳۴۵۶۷۸۹'[int.parse(m[0]!)]),
      style: PText.caption.copyWith(color: Colors.white, fontSize: 12),
    ),
  );
}

/// «ادامه» آرام و بی‌مزاحمت: آخرین فعالیت باز با یک لمس.
class _ContinueChip extends StatelessWidget {
  const _ContinueChip({required this.route});

  final String route;

  @override
  Widget build(BuildContext context) =>
      PButton(label: 'ادامه', icon: Icons.replay_rounded, color: PColors.green, onPressed: () => context.push(route));
}

/// کارت مصور یک جهان روی نقشه.
class WorldCard extends StatelessWidget {
  const WorldCard({super.key, required this.world, required this.onTap, this.visited = false});

  final WorldDef world;
  final VoidCallback onTap;
  final bool visited;

  @override
  Widget build(BuildContext context) {
    final color = PColors.worlds[world.id] ?? PColors.blue;
    return PTile(
      label: world.title,
      labelLines: 2,
      color: PColors.tint(color, .3),
      semanticHint: world.subtitle,
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 1.25,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(colors: [Colors.white, PColors.tint(color, .2)]),
                borderRadius: BorderRadius.circular(PRadius.sm),
              ),
            ),
            Padding(padding: const EdgeInsets.all(PSpace.xs), child: ArtImage(world.art)),
            if (visited) const PositionedDirectional(top: 2, end: 2, child: Icon(Icons.star_rounded, color: PColors.orange, size: 22)),
          ],
        ),
      ),
    );
  }
}
