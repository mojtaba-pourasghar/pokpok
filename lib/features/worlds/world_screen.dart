import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/content/content.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../paywall/paywall.dart';
import 'scene_view.dart';

/// یک جهان (خانه، شهر، طبیعت) با چند صحنه و نوار پایین برای رفتن بین صحنه‌ها.
class WorldScreen extends ConsumerStatefulWidget {
  const WorldScreen({super.key, required this.worldId, this.initialScene});

  final String worldId;
  final String? initialScene;

  @override
  ConsumerState<WorldScreen> createState() => _WorldScreenState();
}

class _WorldScreenState extends ConsumerState<WorldScreen> with ActivitySession {
  late final WorldDef? _world = ref.read(contentProvider).world(widget.worldId);
  late final List<SceneDef> _scenes = ref.read(contentProvider).scenesOf(widget.worldId);
  late int _index = () {
    final i = _scenes.indexWhere((s) => s.id == widget.initialScene);
    return i < 0 ? 0 : i;
  }();
  final _sceneKey = GlobalKey<SceneViewState>();

  @override
  String get activityId => 'world.${widget.worldId}';
  @override
  String get activityTitle => _world?.title ?? widget.worldId;
  @override
  String? get resumeRoute => '/world/${widget.worldId}';

  late final PopoAudio _audio;

  @override
  void initState() {
    super.initState();
    _audio = ref.read(audioProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider).startMusic('audio/music/play_loop.mp3');
      award('world.${widget.worldId}');
    });
  }

  @override
  void dispose() {
    _audio.stopAmbient();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_world == null || _scenes.isEmpty) {
      return const PScaffold(
        title: 'پیدا نشد',
        body: StateView(state: ViewState.empty, message: 'این جهان هنوز آماده نیست.'),
      );
    }
    final access = ref.watch(accessProvider);
    // صحنه‌ای که از «ادامه» یا کتابخانه باز شده ولی پولی است: صحنه‌ی رایگان نشان داده می‌شود.
    if (access.needsPurchase(_index)) _index = 0;
    final scene = _scenes[_index];
    return Scaffold(
      backgroundColor: PColors.background,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: SceneView(
                    key: _sceneKey,
                    scene: scene,
                    // اهداف آرام در جهان‌ها: فقط یک برچسب و تشویق، بدون پنجره‌ی پایان.
                    onGoalsDone: scene.sticker == null
                        ? null
                        : () async {
                            await ref.sayOneOf('praise');
                            await award(scene.sticker!);
                          },
                  ),
                ),
                SafeArea(
                  child: PTopBar(
                    title: '${_world.title} · ${scene.title}',
                    light: true,
                    actions: [
                      PIconButton(
                        icon: Icons.pause_rounded,
                        label: 'مکث',
                        iconColor: PColors.orange,
                        onPressed: () => showPauseSheet(context, ref, onReset: () => _sceneKey.currentState?.reset()),
                      ),
                    ],
                  ),
                ),
                const SafeArea(
                  child: Padding(padding: EdgeInsets.only(top: 72), child: CaptionBubble()),
                ),
              ],
            ),
          ),
          if (_scenes.length > 1)
            _SceneTabs(
              scenes: _scenes,
              index: _index,
              locked: (i) => access.needsPurchase(i),
              onSelect: (i) {
                // صحنه‌ی اول هر جهان رایگان است؛ بقیه در نسخه‌ی کامل (پشت دروازه‌ی والدین).
                if (access.needsPurchase(i)) {
                  ref.say('full.locked');
                  showPaywall(context);
                  return;
                }
                setState(() => _index = i);
              },
            ),
        ],
      ),
    );
  }
}

/// نوار صحنه‌ها با تصویر هر اتاق/مکان (مثل نوار پایین تصویر مرجع).
class _SceneTabs extends StatelessWidget {
  const _SceneTabs({required this.scenes, required this.index, required this.onSelect, required this.locked});

  final List<SceneDef> scenes;
  final int index;
  final ValueChanged<int> onSelect;
  final bool Function(int index) locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: PShadow.soft()),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 104,
          child: Center(
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: PSpace.xs),
              itemCount: scenes.length,
              separatorBuilder: (_, _) => const SizedBox(width: PSpace.sm),
              itemBuilder: (context, i) => SizedBox(
                width: 92,
                child: PTile(
                  label: scenes[i].title,
                  selected: i == index,
                  locked: locked(i),
                  semanticHint: locked(i) ? 'در نسخه‌ی کامل' : null,
                  color: i == index ? PColors.tint(PColors.orange, .3) : Colors.white,
                  onTap: () => onSelect(i),
                  child: ArtImage(scenes[i].icon),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
