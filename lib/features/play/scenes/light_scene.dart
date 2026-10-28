import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/audio/popo_audio.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import 'scene_base.dart';

/// روشنایی: اتاق تاریک است. کودک چراغ (یا فانوس، یا شیشه‌ی کرم شب‌تاب) را با انگشت می‌برد و نور،
/// چیزهای پنهان را پیدا می‌کند؛ هر چه در نور است لمس‌شدنی است و جرقه می‌زند.
/// تلسکوپ: در دایره‌ی دید، آسمان شب حرکت می‌کند؛ ستاره‌ها را یکی‌یکی لمس می‌کند و صورت فلکی کشیده می‌شود.
class LightScene extends ShowcaseScene {
  const LightScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<LightScene> createState() => _LightSceneState();
}

class _LightSceneState extends ConsumerState<LightScene> with SceneBase {
  late final bool telescope = widget.item.kind == 'lookout';
  late final List<(String, Offset)> hidden = telescope
      ? [for (var i = 0; i < 6; i++) ('star', Offset(.15 + (i * .137) % .7, .2 + (i * .29) % .55))]
      : [
          ('baby_owl', const Offset(.2, .3)),
          ('firefly', const Offset(.75, .25)),
          ('ladybug', const Offset(.3, .75)),
          ('moon', const Offset(.8, .7)),
          ('box', const Offset(.5, .5)),
        ];
  final Set<int> found = {};
  Offset light = const Offset(.5, .55);
  bool on = false;
  int _autoIndex = 0;

  @override
  void initState() {
    super.initState();
    autoPlay(() {
      if (!on) {
        _toggle();
        return;
      }
      if (_autoIndex < hidden.length) {
        setState(() => light = hidden[_autoIndex].$2);
        _find(_autoIndex++);
      }
    }, every: const Duration(milliseconds: 900));
  }

  void _toggle() {
    sfx(widget.item.sound);
    setState(() => on = !on);
    if (on && tries == 0) tried();
  }

  void _find(int i) {
    if (found.contains(i) || !on) return;
    setState(() => found.add(i));
    ui(UiSound.sparkle);
    tried();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = Size(box.maxWidth, box.maxHeight);
      final r = math.min(s.width, s.height) * (telescope ? .32 : .26);
      final lp = Offset(light.dx * s.width, light.dy * s.height);
      return GestureDetector(
        onPanDown: (d) => setState(() => light = Offset(d.localPosition.dx / s.width, d.localPosition.dy / s.height)),
        onPanUpdate: (d) =>
            setState(() => light = Offset((d.localPosition.dx / s.width).clamp(0, 1), (d.localPosition.dy / s.height).clamp(0, 1))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Container(color: const Color(0xFF26318A)),
              for (final (i, (art, at)) in hidden.indexed)
                Positioned(
                  left: at.dx * s.width - 36,
                  top: at.dy * s.height - 36,
                  child: Builder(
                    builder: (c) => GestureDetector(
                      onTap: on && (lp - Offset(at.dx * s.width, at.dy * s.height)).distance < r
                          ? () {
                              c.fx(Fx.sparkle, count: 14);
                              _find(i);
                            }
                          : null,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 300),
                        scale: found.contains(i) ? 1.25 : 1,
                        child: Idle(seed: i, amount: .6, child: GameArt(art, size: 72)),
                      ),
                    ),
                  ),
                ),
              // خطوط صورت فلکی
              if (telescope)
                IgnorePointer(
                  child: CustomPaint(
                    size: s,
                    painter: _Lines([for (final i in found) Offset(hidden[i].$2.dx * s.width, hidden[i].$2.dy * s.height)]),
                  ),
                ),
              IgnorePointer(
                child: CustomPaint(
                  size: s,
                  painter: _Darkness(light: on ? lp : null, r: r, telescope: telescope),
                ),
              ),
              // خود چراغ زیر نور
              if (!telescope)
                Positioned(
                  left: lp.dx - 40,
                  top: lp.dy + r * .55,
                  child: IgnorePointer(child: GameArt(widget.item.id, size: 80)),
                ),
              Positioned(
                left: 8,
                bottom: 8,
                child: GestureDetector(
                  onTap: _toggle,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? G.yellow : Colors.white,
                      boxShadow: [
                        ...G.soft(),
                        if (!on) const BoxShadow(color: Color(0xCCFFE066), blurRadius: 22, spreadRadius: 5),
                      ],
                    ),
                    child: Icon(
                      on ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                      size: 42,
                      color: on ? Colors.white : G.orange,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: CountChip(icon: Icons.search_rounded, value: found.length, color: G.yellow, label: 'پیدا شده'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Darkness extends CustomPainter {
  _Darkness({required this.light, required this.r, required this.telescope});

  final Offset? light;
  final double r;
  final bool telescope;

  @override
  void paint(Canvas canvas, Size s) {
    canvas.saveLayer(Offset.zero & s, Paint());
    canvas.drawRect(Offset.zero & s, Paint()..color = const Color(0xF20A0D2A));
    final l = light;
    if (l != null) {
      final clear = Paint()
        ..blendMode = BlendMode.dstOut
        ..shader = RadialGradient(
          colors: const [Colors.black, Colors.black, Colors.transparent],
          stops: telescope ? const [0, .92, 1] : const [0, .55, 1],
        ).createShader(Rect.fromCircle(center: l, radius: r));
      canvas.drawCircle(l, r, clear);
    }
    canvas.restore();
    if (l != null) {
      // هاله‌ی گرم نور
      canvas.drawCircle(
        l,
        r,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x33FFF3B0), Color(0x00FFF3B0)])
              .createShader(Rect.fromCircle(center: l, radius: r)),
      );
      if (telescope) {
        canvas.drawCircle(
          l,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 10
            ..color = const Color(0xFF455A64),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Darkness old) => old.light != light;
}

class _Lines extends CustomPainter {
  _Lines(this.points);

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xCCFFF59D)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < points.length; i++) {
      canvas.drawLine(points[i - 1], points[i], p);
    }
  }

  @override
  bool shouldRepaint(_Lines old) => old.points.length != points.length;
}
