import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/content/content.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../mascot/popo_mascot.dart';
import 'engine/scene_controller.dart';
import 'engine/scene_stage.dart';

/// یک صحنه‌ی کامل: صحنه‌ی تعاملی + پوپوی واکنش‌دهنده + راهنمای آرام پس از بی‌کاری.
/// هم در جهان‌ها و هم در نقش‌آفرینی استفاده می‌شود.
class SceneView extends ConsumerStatefulWidget {
  const SceneView({super.key, required this.scene, this.onGoalsDone, this.mascotSize = .22});

  final SceneDef scene;
  final VoidCallback? onGoalsDone;
  final double mascotSize;

  @override
  ConsumerState<SceneView> createState() => SceneViewState();
}

class SceneViewState extends ConsumerState<SceneView> {
  late SceneController controller;
  PopoPose _pose = PopoPose.idle;
  Timer? _poseReset;
  Timer? _idle;
  late final String _profile = ref.read(activeIdProvider);

  @override
  void initState() {
    super.initState();
    controller = _build(widget.scene);
    WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
  }

  SceneController _build(SceneDef s) {
    final repo = ref.read(sceneRepoProvider);
    final profile = _profile;
    return SceneController(scene: s, saved: repo.load(profile, s.id), onPersist: (states) => repo.save(profile, s.id, states));
  }

  void _enter() {
    if (!mounted) return;
    ref.say(widget.scene.intro);
    final amb = widget.scene.ambient;
    final audio = ref.read(audioProvider);
    if (amb != null && amb.startsWith('audio/ambient/')) {
      audio.startAmbient(amb);
    } else {
      audio.stopAmbient();
    }
    _armIdle();
  }

  @override
  void didUpdateWidget(SceneView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene.id != widget.scene.id) {
      controller.dispose();
      controller = _build(widget.scene);
      _pose = PopoPose.idle;
      WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
    }
  }

  /// پس از چند ثانیه بی‌کاری، پوپو با اشاره یک چیز را پیشنهاد می‌کند (فقط یک بار در هر بی‌کاری).
  void _armIdle() {
    _idle?.cancel();
    _idle = Timer(const Duration(seconds: 18), () {
      if (!mounted) return;
      setState(() => _pose = PopoPose.pointing);
      ref.sayOneOf('idle');
      _poseLater();
    });
  }

  void _poseLater([Duration d = const Duration(seconds: 3)]) {
    _poseReset?.cancel();
    _poseReset = Timer(d, () {
      if (mounted) setState(() => _pose = PopoPose.idle);
    });
  }

  void _onResult(InteractionResult r) {
    _armIdle();
    ref.sound(r.sound);
    if (r.say != null) ref.say(r.say);
    if (r.matched) {
      setState(() => _pose = PopoPose.happy);
      _poseLater();
    } else if (r.animate.isNotEmpty && _pose == PopoPose.idle) {
      setState(() => _pose = PopoPose.curious);
      _poseLater(const Duration(milliseconds: 1500));
    }
    if (r.goalCompleted) {
      ref.read(audioProvider).ui(UiSound.success);
      widget.onGoalsDone?.call();
    }
  }

  void reset() {
    controller.reset();
    ref.read(audioProvider).ui(UiSound.whoosh);
  }

  @override
  void dispose() {
    _idle?.cancel();
    _poseReset?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    return LayoutBuilder(
      builder: (context, box) {
        final u = box.biggest.shortestSide;
        return Stack(
          children: [
            Positioned.fill(
              child: SceneStage(controller: controller, reducedMotion: reduced, onResult: _onResult, onInteract: _armIdle),
            ),
            PositionedDirectional(
              start: 0,
              bottom: 0,
              child: IgnorePointer(
                child: PopoMascot(pose: _pose, size: u * widget.mascotSize * 1.3, reducedMotion: reduced, pointRight: false),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// منوی مکث: ادامه، از نو، بازگشت به نقشه. صحنه پیش از نمایش ذخیره شده است.
Future<void> showPauseSheet(BuildContext context, WidgetRef ref, {VoidCallback? onReset}) async {
  ref.read(audioProvider).stopAll();
  unawaited(ref.say('session.pause'));
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PSpace.lg, 0, PSpace.lg, PSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PopoMascot(pose: PopoPose.idle, size: 110, reducedMotion: ref.read(settingsProvider).reducedMotion),
            const Text('بازی ایستاد', style: PText.title),
            const SizedBox(height: PSpace.md),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: PSpace.sm,
              runSpacing: PSpace.sm,
              children: [
                PButton(label: 'ادامه', icon: Icons.play_arrow_rounded, color: PColors.success, onPressed: () => Navigator.pop(ctx)),
                if (onReset != null)
                  PButton(
                    label: 'از نو',
                    icon: Icons.refresh_rounded,
                    color: PColors.orange,
                    onPressed: () {
                      Navigator.pop(ctx);
                      onReset();
                    },
                  ),
                PButton(
                  label: 'نقشه',
                  icon: Icons.map_rounded,
                  color: PColors.blue,
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref.read(progressProvider.notifier).setLastRoute(null);
                    context.go('/map');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
