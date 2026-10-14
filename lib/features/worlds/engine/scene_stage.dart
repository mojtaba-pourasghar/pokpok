import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/tokens.dart';
import '../../../core/content/content.dart';
import '../../../core/widgets/common.dart';
import '../../../data/models/models.dart';
import '../backgrounds/scene_backgrounds.dart';
import 'scene_controller.dart';

/// صحنه‌ی تعاملی: پس‌زمینه + اشیا. هر شیء لایه و شنونده‌ی جدای خودش را دارد.
///
/// [onResult] نتیجه‌ی هر تعامل را می‌گیرد تا صفحه صدا پخش کند، پوپو واکنش نشان دهد و…
class SceneStage extends StatefulWidget {
  const SceneStage({super.key, required this.controller, required this.onResult, this.reducedMotion = false, this.onInteract});

  final SceneController controller;
  final void Function(InteractionResult result) onResult;
  final VoidCallback? onInteract;
  final bool reducedMotion;

  @override
  State<SceneStage> createState() => _SceneStageState();
}

class _SceneStageState extends State<SceneStage> {
  final _bursts = ValueNotifier<List<(int, Offset)>>(const []);
  int _burstId = 0;
  late List<SceneObjectRuntime> _order;

  @override
  void initState() {
    super.initState();
    _sortObjects();
    widget.controller.addListener(_onController);
  }

  @override
  void didUpdateWidget(SceneStage old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onController);
      widget.controller.addListener(_onController);
      _sortObjects();
    }
  }

  void _sortObjects() {
    // لایه‌ها: اول z، بعد هرچه پایین‌تر روی صفحه، جلوتر (عمق ساده).
    _order = widget.controller.objects.values.toList()
      ..sort((a, b) {
        final z = a.def.z.compareTo(b.def.z);
        return z != 0 ? z : a.def.y.compareTo(b.def.y);
      });
  }

  void _onController() {
    // فقط شیء در حال کشیدن به بالای لایه‌ها می‌رود؛ این تنها بازسازی کل صحنه است.
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _bursts.dispose();
    super.dispose();
  }

  void _handle(InteractionResult r) {
    widget.onInteract?.call();
    if (r.burstAt != null) {
      final id = _burstId++;
      _bursts.value = [..._bursts.value, (id, r.burstAt!)];
    }
    widget.onResult(r);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        final u = math.min(size.width, size.height);
        final dragging = c.dragging;
        final layers = [
          for (final o in _order)
            if (o.def.id != dragging) o,
          if (dragging != null) c.objects[dragging]!,
        ];
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: SceneBackground(id: c.scene.background, paths: c.scene.paths),
            ),
            for (final o in layers)
              _SceneObjectView(
                key: ValueKey(o.def.id),
                runtime: o,
                controller: c,
                stage: size,
                unit: u,
                lifted: o.def.id == dragging,
                reducedMotion: widget.reducedMotion,
                onResult: _handle,
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<List<(int, Offset)>>(
                  valueListenable: _bursts,
                  builder: (context, list, _) => Stack(
                    children: [
                      for (final (id, at) in list)
                        Positioned(
                          key: ValueKey('burst$id'),
                          left: at.dx * size.width - u * .14,
                          top: at.dy * size.height - u * .14,
                          child: Burst(
                            radius: u * .14,
                            reduced: widget.reducedMotion,
                            onDone: () => _bursts.value = [
                              for (final b in _bursts.value)
                                if (b.$1 != id) b,
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SceneObjectView extends StatefulWidget {
  const _SceneObjectView({
    super.key,
    required this.runtime,
    required this.controller,
    required this.stage,
    required this.unit,
    required this.lifted,
    required this.reducedMotion,
    required this.onResult,
  });

  final SceneObjectRuntime runtime;
  final SceneController controller;
  final Size stage;
  final double unit;
  final bool lifted;
  final bool reducedMotion;
  final void Function(InteractionResult) onResult;

  @override
  State<_SceneObjectView> createState() => _SceneObjectViewState();
}

class _SceneObjectViewState extends State<_SceneObjectView> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));

  @override
  void initState() {
    super.initState();
    widget.runtime.animTick.addListener(_play);
  }

  @override
  void dispose() {
    widget.runtime.animTick.removeListener(_play);
    _anim.dispose();
    super.dispose();
  }

  void _play() => _anim.forward(from: 0);

  /// حرکت هر نوع واکنش. با «حرکت کمتر» همه به یک تپش کوچک تبدیل می‌شوند.
  Matrix4 _transform(double t, double size) {
    final m = Matrix4.identity();
    if (t == 0 || t == 1) return m;
    final name = widget.reducedMotion ? 'pop' : widget.runtime.anim;
    final wave = math.sin(t * math.pi);
    switch (name) {
      case 'jump':
        m.translateByDouble(0, -size * .28 * math.sin(t * math.pi).abs(), 0, 1);
      case 'wiggle':
        m.rotateZ(math.sin(t * math.pi * 6) * .12 * (1 - t));
      case 'squash':
        final k = 1 - .18 * math.sin(t * math.pi * 2) * (1 - t);
        m.translateByDouble(0, size / 2 * (1 - k), 0, 1);
        m.scaleByDouble(2 - k, k, 1, 1);
      case 'spin':
        m.rotateZ(Curves.easeInOut.transform(t) * math.pi * 2);
      case 'grow':
        final k = .7 + .3 * Curves.elasticOut.transform(t);
        m.scaleByDouble(k, k, 1, 1);
      case 'pop':
        final k = 1 + .08 * wave;
        m.scaleByDouble(k, k, 1, 1);
      default: // bounce
        final k = 1 + .14 * math.sin(t * math.pi) * (1 - t * .5);
        m.scaleByDouble(k, k, 1, 1);
    }
    return m;
  }

  void _tap() {
    HapticFeedback.lightImpact();
    widget.onResult(widget.controller.tap(widget.runtime.def.id));
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.runtime.def;
    final size = def.size * widget.unit;
    final stage = widget.stage;
    final canDrag = def.drag != DragMode.none;
    return ValueListenableBuilder<ObjectState>(
      valueListenable: widget.runtime.state,
      builder: (context, s, _) {
        if (s.hidden) return const SizedBox.shrink();
        final left = s.x * stage.width - size / 2;
        final top = s.y * stage.height - size / 2;
        final hit = def.hit;
        Widget art = ValueListenableBuilder<bool>(
          valueListenable: widget.runtime.facingLeft,
          builder: (context, left, child) {
            // تصویرها رو به راست کشیده شده‌اند؛ ماشینی که به چپ می‌رود برگردانده می‌شود.
            return Transform.flip(flipX: def.flip != left, child: child);
          },
          child: ArtImage(def.artFor(s.stage), size: size),
        );
        if (def.glow) {
          art = Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedOpacity(
                opacity: s.on ? 1 : 0,
                duration: PMotion.quick,
                child: Container(
                  width: size * 1.5,
                  height: size * 1.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [PColors.yellow.withValues(alpha: .65), PColors.yellow.withValues(alpha: 0)]),
                  ),
                ),
              ),
              art,
            ],
          );
        }
        return Positioned(
          left: left,
          top: top,
          width: size,
          height: size,
          child: AnimatedScale(
            scale: widget.lifted ? 1.12 : 1,
            duration: PMotion.tap,
            child: AnimatedBuilder(
              animation: _anim,
              builder: (context, child) => Transform(alignment: Alignment.center, transform: _transform(_anim.value, size), child: child),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: IgnorePointer(child: art)),
                  Positioned(
                    left: hit.left * size,
                    top: hit.top * size,
                    width: hit.width * size,
                    height: hit.height * size,
                    child: Semantics(
                      button: true,
                      label: def.label ?? def.id,
                      hint: canDrag ? 'لمس کن یا بکش' : 'لمس کن',
                      onTap: _tap,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _tap,
                        onPanStart: canDrag
                            ? (_) {
                                widget.controller.startDrag(def.id);
                                HapticFeedback.selectionClick();
                              }
                            : null,
                        onPanUpdate: canDrag
                            ? (d) {
                                final o = widget.runtime.state.value;
                                final p = Offset(o.x * stage.width, o.y * stage.height) + d.delta;
                                widget.controller.moveTo(def.id, Offset(p.dx / stage.width, p.dy / stage.height));
                              }
                            : null,
                        onPanEnd: canDrag ? (_) => _end() : null,
                        onPanCancel: canDrag ? _end : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _end() {
    if (widget.controller.dragging != widget.runtime.def.id) return;
    widget.onResult(widget.controller.endDrag(widget.runtime.def.id, widget.stage));
  }
}
