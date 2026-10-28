import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../core/audio/popo_audio.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import '../../mascot/popo_mascot.dart';
import 'scene_base.dart';

/// آب و گیاه.
/// - ظرف (آب‌پاش، کاسه): کودک ظرف را روی گل‌های پژمرده می‌برد و نگه می‌دارد؛ آب می‌ریزد و هر گل
///   کم‌کم راست می‌شود و باز می‌شود. کاسه پر می‌شود و چیزی نمی‌ریزد.
/// - گلدان: با هر لمس آب می‌خورد و بزرگ‌تر می‌شود؛ زنبور دورش می‌چرخد و بوی خوش (ذره‌ی صورتی) بالا می‌رود.
/// - چادر: باران می‌بارد؛ دوست را زیر چادر بکش تا خشک و خوشحال بماند.
class WaterScene extends ShowcaseScene {
  const WaterScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<WaterScene> createState() => _WaterSceneState();
}

class _WaterSceneState extends ConsumerState<WaterScene> with SceneBase, SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  final _can = GlobalKey();
  final _flowers = List.generate(3, (_) => GlobalKey());
  final List<double> grow = [0, 0, 0];
  Offset can = const Offset(.25, .25);
  bool pouring = false;
  Timer? _pour;
  double bowl = 0;
  bool inside = false;
  int happy = 0;

  String get kind => widget.item.kind;
  bool get isBowl => widget.item.id == 'clay_bowl';

  @override
  void initState() {
    super.initState();
    if (kind == 'shelter') _rain();
    autoPlay(() {
      switch (kind) {
        case 'plant':
          _waterPlant();
        case 'shelter':
          _shelter();
        default:
          final i = grow.indexWhere((g) => g < 1);
          setState(() => can = Offset(.2 + (i < 0 ? 0 : i) * .3, .25));
          _startPour();
          Future.delayed(const Duration(milliseconds: 900), _stopPour);
      }
    }, every: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _pour?.cancel();
    _rainTimer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  Timer? _rainTimer;

  void _rain() {
    _rainTimer = Timer.periodic(const Duration(milliseconds: 160), (_) {
      if (!mounted) {
        _rainTimer?.cancel();
        return;
      }
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final x = math.Random().nextDouble() * box.size.width;
      fx?.burst(box.localToGlobal(Offset(x, 0)), Fx.drops, count: 2, color: const Color(0xFF64B5F6), spread: .2);
    });
  }

  void _startPour() {
    if (pouring) return;
    setState(() => pouring = true);
    sfx(isBowl ? 'audio/sfx/pour.mp3' : widget.item.sound);
    _pour = Timer.periodic(const Duration(milliseconds: 90), (_) {
      burstAt(_can, Fx.drops, offset: const Offset(-50, 30), count: 2, spread: .4);
      if (isBowl) {
        setState(() => bowl = math.min(1, bowl + .03));
        if (bowl >= 1) {
          _stopPour();
          tried();
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => bowl = 0);
          });
        }
        return;
      }
      // کدام گل زیر قطره‌هاست؟
      final c = _can.currentContext?.globalCenter;
      if (c == null) return;
      for (var i = 0; i < 3; i++) {
        final f = _flowers[i].currentContext?.globalCenter;
        if (f != null && (f.dx - (c.dx - 50)).abs() < 70 && grow[i] < 1) {
          setState(() => grow[i] = math.min(1, grow[i] + .06));
          if (grow[i] >= 1) {
            burstAt(_flowers[i], Fx.sparkle, count: 10);
            tried();
          }
        }
      }
    });
  }

  void _stopPour() {
    _pour?.cancel();
    if (mounted) setState(() => pouring = false);
  }

  void _waterPlant() {
    sfx('audio/sfx/splash.mp3');
    burstAt(_flowers[0], Fx.drops, offset: const Offset(0, -80), count: 10, spread: .5);
    setState(() => grow[0] = math.min(1, grow[0] + .34));
    if (grow[0] >= 1) {
      sfx(widget.item.sound);
      burstAt(_flowers[0], Fx.hearts, count: 4, color: G.pink);
      tried();
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => grow[0] = .2);
      });
    }
  }

  void _shelter() {
    setState(() {
      inside = !inside;
      happy++;
    });
    if (inside) {
      burstAt(_flowers[0], Fx.hearts, count: 5);
      ui(UiSound.pop);
      tried();
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      return switch (kind) {
        'plant' => _plant(box, s),
        'shelter' => _tent(box, s),
        _ => _container(box, s),
      };
    },
  );

  Widget _container(BoxConstraints box, double s) => Stack(
    children: [
      if (isBowl)
        Positioned(
          left: box.maxWidth / 2 - s * .3,
          bottom: s * .05,
          child: SizedBox(
            width: s * .6,
            height: s * .5,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // آب داخل کاسه
                Positioned(
                  bottom: s * .12,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 90),
                    width: s * .38,
                    height: s * .22 * bowl,
                    decoration: BoxDecoration(color: const Color(0xCC4FC3F7), borderRadius: BorderRadius.circular(s)),
                  ),
                ),
                GameArt(widget.item.id, size: s * .6),
              ],
            ),
          ),
        )
      else
        for (var i = 0; i < 3; i++)
          Positioned(
            key: _flowers[i],
            left: box.maxWidth * (.12 + i * .3),
            bottom: 0,
            child: Transform.rotate(
              alignment: Alignment.bottomCenter,
              angle: (1 - grow[i]) * .8 * (i.isEven ? 1 : -1),
              child: Transform.scale(
                alignment: Alignment.bottomCenter,
                scale: .7 + grow[i] * .35,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(Color.lerp(const Color(0xFF9E9E9E), Colors.white, grow[i])!, BlendMode.modulate),
                  child: GameArt('flower_pot', size: s * .3),
                ),
              ),
            ),
          ),
      // ظرف کشیدنی
      Positioned(
        left: can.dx * box.maxWidth - s * .17,
        top: can.dy * box.maxHeight - s * .17,
        child: GestureDetector(
          onPanStart: (_) => _startPour(),
          onPanUpdate: (d) => setState(
            () => can = Offset((can.dx + d.delta.dx / box.maxWidth).clamp(.1, .9), (can.dy + d.delta.dy / box.maxHeight).clamp(.1, .5)),
          ),
          onPanEnd: (_) => _stopPour(),
          onTapDown: (_) => _startPour(),
          onTapUp: (_) => _stopPour(),
          child: AnimatedRotation(
            duration: const Duration(milliseconds: 200),
            turns: pouring ? -.1 : 0,
            child: SizedBox(
              key: _can,
              child: GameArt(isBowl ? 'water_jug' : widget.item.id, size: s * .34),
            ),
          ),
        ),
      ),
      if (tries == 0 && !pouring && !widget.auto)
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Center(child: _Label(isBowl ? 'نگه دار تا کاسه پر شود' : 'آب‌پاش را روی گل‌ها ببر و نگه دار')),
        ),
    ],
  );

  Widget _plant(BoxConstraints box, double s) => AnimatedBuilder(
    animation: _clock,
    builder: (context, _) {
      final a = _clock.value * math.pi * 2;
      return Stack(
        children: [
          Positioned(
            left: box.maxWidth / 2 - s * .25,
            bottom: 0,
            child: GestureDetector(
              onTap: _waterPlant,
              child: Transform.scale(
                key: _flowers[0],
                alignment: Alignment.bottomCenter,
                scale: .7 + grow[0] * .45,
                child: GameArt(widget.item.id, size: s * .5),
              ),
            ),
          ),
          // زنبور روی مسیر بیضی
          Positioned(
            left: box.maxWidth / 2 + math.cos(a) * s * .32 - 30,
            top: box.maxHeight * .35 + math.sin(a * 2) * s * .12 - 30,
            child: GestureDetector(
              onTap: () {
                sfx('audio/sfx/buzz.mp3');
                tried();
              },
              child: Transform.scale(scaleX: math.sin(a) > 0 ? -1 : 1, child: const GameArt('bee', size: 60)),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: PopoMascot(pose: grow[0] > .6 ? PopoPose.happy : PopoPose.curious, size: s * .3),
          ),
          if (tries == 0 && !widget.auto)
            const Positioned(left: 0, right: 0, top: 0, child: Center(child: _Label('گلدان را لمس کن تا آب بخورد'))),
        ],
      );
    },
  );

  Widget _tent(BoxConstraints box, double s) => Stack(
    children: [
      Positioned(
        right: box.maxWidth * .08,
        bottom: 0,
        child: GameArt(widget.item.id, size: s * .55),
      ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutBack,
        left: inside ? box.maxWidth * .58 : box.maxWidth * .05,
        bottom: inside ? s * .05 : 0,
        child: GestureDetector(
          onTap: _shelter,
          child: Squash(
            key: _flowers[0],
            trigger: happy,
            child: inside
                ? PopoMascot(pose: PopoPose.happy, size: s * .3)
                : ColorFiltered(
                    colorFilter: const ColorFilter.mode(Color(0xFFB0BEC5), BlendMode.modulate),
                    child: PopoMascot(pose: PopoPose.sleepy, size: s * .3),
                  ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: Center(child: _Label(inside ? 'زیر چادر خشک است!' : 'خیس شد! لمسش کن تا برود زیر چادر')),
      ),
    ],
  );
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
    child: Text(text, style: PText.heading.copyWith(color: G.purple, fontSize: 16)),
  );
}
