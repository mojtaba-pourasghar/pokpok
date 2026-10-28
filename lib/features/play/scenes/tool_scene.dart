import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/audio/popo_audio.dart';
import '../../../ui/clay.dart';
import '../../../game/engines/engine.dart';
import '../../../ui/fx.dart';
import 'scene_base.dart';

/// چکش و میخ: سه میخ بیرون زده از تخته. با هر لمس روی یک میخ، چکش در کمان پایین می‌آید،
/// جرقه و تراشه می‌پرد، صحنه می‌لرزد و میخ یک پله پایین می‌رود. سه ضربه برای هر میخ؛ وقتی همه
/// رفتند، دو تخته به هم وصل می‌شوند.
class ToolScene extends ShowcaseScene {
  const ToolScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<ToolScene> createState() => _ToolSceneState();
}

class _ToolSceneState extends ConsumerState<ToolScene> with SceneBase, TickerProviderStateMixin {
  static const hitsPerNail = 3;
  late final AnimationController _swing = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  final _nailKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final List<int> hits = [0, 0, 0];
  int target = 0;
  int shake = 0;
  bool joined = false;

  @override
  void initState() {
    super.initState();
    autoPlay(() {
      final next = hits.indexWhere((h) => h < hitsPerNail);
      if (next >= 0) _hit(next);
    }, every: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  Future<void> _hit(int i) async {
    if (hits[i] >= hitsPerNail || _swing.isAnimating) return;
    setState(() => target = i);
    await _swing.forward(from: 0);
    if (!mounted) return;
    sfx(widget.item.sound);
    burstAt(_nailKeys[i], Fx.sparks, offset: const Offset(0, -18));
    burstAt(_nailKeys[i], Fx.dust, offset: const Offset(0, 6), count: 8);
    setState(() {
      hits[i]++;
      shake++;
    });
    _swing.reverse();
    if (hits[i] == hitsPerNail) tried();
    if (hits.every((h) => h >= hitsPerNail) && !joined) {
      setState(() => joined = true);
      ui(UiSound.success);
      fx?.burst(context.globalCenter, Fx.sparkle, count: 24);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) {
          setState(() {
            for (var k = 0; k < hits.length; k++) {
              hits[k] = 0;
            }
            joined = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final w = math.min(box.maxWidth, box.maxHeight * 1.3);
      final plankY = box.maxHeight * .62;
      final nailX = [for (var k = 0; k < 3; k++) box.maxWidth / 2 + (k - 1) * w * .26];
      final h = w * .34;
      return ShakeScene(
        trigger: shake,
        strength: 4,
        child: Stack(
          children: [
            // دو تخته، که وقتی میخ‌ها تمام شدند به هم می‌چسبند
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              left: box.maxWidth / 2 - w * .48,
              top: plankY,
              child: GameArt('plank', size: w * .52),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              left: box.maxWidth / 2 - (joined ? w * .02 : -w * .02),
              top: plankY,
              child: GameArt('plank', size: w * .5),
            ),
            for (var k = 0; k < 3; k++)
              Positioned(
                left: nailX[k] - 26,
                top: plankY - 30 + hits[k] * 12,
                child: GestureDetector(
                  onTap: () => _hit(k),
                  child: SizedBox(
                    key: _nailKeys[k],
                    width: 52,
                    height: 60,
                    child: HintGlow(on: !widget.auto && tries == 0 && k == 0, child: const GameArt('nail', size: 52)),
                  ),
                ),
              ),
            // چکش: دسته پایین سمت راست، سر در کمان روی میخ هدف می‌آید
            AnimatedBuilder(
              animation: _swing,
              builder: (context, child) {
                final t = Curves.easeIn.transform(_swing.value);
                return Positioned(
                  left: nailX[target] - h * .1,
                  top: plankY - h * 1.05,
                  child: Transform.rotate(alignment: Alignment.bottomRight, angle: -1.0 + t * 1.0, child: child),
                );
              },
              child: IgnorePointer(child: GameArt(widget.item.id, size: h)),
            ),
            if (joined)
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: PopIn(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: G.green,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Text('تخته‌ها وصل شدند!', style: PText.title.copyWith(color: Colors.white, fontSize: 19)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
