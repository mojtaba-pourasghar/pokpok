import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/audio/popo_audio.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import '../../mascot/popo_mascot.dart';
import 'scene_base.dart';

/// کاردستی‌ها:
/// - پوشیدنی (ماسک، گردنبند، مدال): روی پوپو بکش تا بپوشد؛ پوپو می‌خندد و دور خودش می‌چرخد.
/// - رنگ‌ها: با انگشت روی بوم نقاشی کن.
/// - تزئینات و پرچم: جاهای خالی روی نخ را لمس کن تا آویزان شوند.
/// - کارت دعوت: پاکت را باز کن؛ کارت بیرون می‌پرد.
/// - قاب عکس: دکمه‌ی دوربین؛ فلاش و عکس پوپو در قاب.
/// - نقشه: پوپو را روی راه نقطه‌چین تا گنج ببر.
class CraftScene extends ShowcaseScene {
  const CraftScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<CraftScene> createState() => _CraftSceneState();
}

class _CraftSceneState extends ConsumerState<CraftScene> with SceneBase, SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  final _popo = GlobalKey();
  final _spots = List.generate(6, (_) => GlobalKey());
  bool worn = false;
  final Set<int> hung = {};
  final List<List<Offset>> strokes = [];
  final List<Color> strokeColors = [];
  Color brush = const Color(0xFFF44336);
  bool opened = false;
  bool flash = false;
  double mapT = 0;

  String get id => widget.item.id;
  String get mode => switch (id) {
    'mask' || 'necklace' || 'medal' => 'wear',
    'paints' => 'paint',
    'invitation' => 'letter',
    'photo_frame' => 'photo',
    'map' => 'map',
    _ => 'hang',
  };

  @override
  void initState() {
    super.initState();
    autoPlay(() {
      switch (mode) {
        case 'wear':
          _wear();
        case 'letter':
          _open();
        case 'photo':
          _photo();
        case 'map':
          setState(() => mapT = math.min(1, mapT + .25));
          if (mapT >= 1) _treasure();
        case 'paint':
          setState(() {
            strokes.add([for (var k = 0; k < 20; k++) Offset(40 + k * 12.0, 120 + math.sin(k / 3 + strokes.length) * 40)]);
            strokeColors.add(const [Color(0xFFF44336), Color(0xFF4CAF50), Color(0xFF2196F3)][strokes.length % 3]);
          });
        default:
          final i = List.generate(6, (k) => k).firstWhere((k) => !hung.contains(k), orElse: () => -1);
          if (i >= 0) _hang(i);
      }
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _wear() {
    setState(() => worn = !worn);
    if (worn) {
      sfx(widget.item.sound);
      burstAt(_popo, Fx.confetti, count: 26);
      _spin.forward(from: 0);
      tried();
    } else {
      ui(UiSound.pop);
    }
  }

  void _hang(int i) {
    if (hung.contains(i)) return;
    setState(() => hung.add(i));
    sfx(widget.item.sound);
    burstAt(_spots[i], Fx.sparkle, count: 8);
    if (hung.length % 2 == 0) tried();
    if (hung.length == 6) {
      fx?.burst(context.globalCenter, Fx.confetti);
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(hung.clear);
      });
    }
  }

  void _open() {
    setState(() => opened = !opened);
    if (opened) {
      sfx(widget.item.sound);
      fx?.burst(context.globalCenter, Fx.hearts, count: 8);
      tried();
    }
  }

  Future<void> _photo() async {
    ui(UiSound.camera);
    setState(() => flash = true);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (!mounted) return;
    setState(() => flash = false);
    burstAt(_popo, Fx.sparkle, count: 12);
    tried();
  }

  void _treasure() {
    sfx('audio/ui/success.mp3');
    fx?.burst(context.globalCenter, Fx.sparkle, count: 24);
    tried();
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => mapT = 0);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      return switch (mode) {
        'wear' => _wearScene(box, s),
        'paint' => _paintScene(box, s),
        'letter' => _letterScene(box, s),
        'photo' => _photoScene(box, s),
        'map' => _mapScene(box, s),
        _ => _hangScene(box, s),
      };
    },
  );

  Widget _wearScene(BoxConstraints box, double s) => Stack(
    children: [
      Positioned(
        left: box.maxWidth * .08,
        bottom: 0,
        child: DragTarget<String>(
          onAcceptWithDetails: (_) => _wear(),
          builder: (context, cand, _) => GestureDetector(
            onTap: worn ? _wear : null,
            child: AnimatedBuilder(
              animation: _spin,
              builder: (context, child) => Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.sin(_spin.value * math.pi) * math.pi * .9),
                child: child,
              ),
              child: SizedBox(
                key: _popo,
                width: s * .55,
                height: s * .62,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PopoMascot(pose: worn ? PopoPose.happy : PopoPose.curious, size: s * .55),
                    if (worn)
                      Positioned(
                        // ماسک روی صورت، گردنبند و مدال روی سینه
                        top: id == 'mask' ? s * .06 : s * .3,
                        child: PopIn(child: GameArt(id, size: id == 'mask' ? s * .28 : s * .18)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      if (!worn)
        Positioned(
          right: box.maxWidth * .08,
          top: box.maxHeight * .2,
          child: Draggable<String>(
            data: id,
            feedback: GameArt(id, size: s * .3),
            childWhenDragging: const SizedBox.shrink(),
            child: Idle(
              seed: 4,
              child: GestureDetector(
                onTap: _wear,
                child: GameArt(id, size: s * .3),
              ),
            ),
          ),
        ),
      if (!worn && tries == 0 && !widget.auto)
        Positioned(
          right: box.maxWidth * .2,
          top: box.maxHeight * .45,
          child: const IgnorePointer(child: Text('👆', style: TextStyle(fontSize: 46))),
        ),
    ],
  );

  Widget _paintScene(BoxConstraints box, double s) {
    const colors = [Color(0xFFF44336), Color(0xFFFF9800), Color(0xFFFFEB3B), Color(0xFF4CAF50), Color(0xFF2196F3), Color(0xFF9C27B0)];
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD7A86E), width: 8),
              boxShadow: G.soft(),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: GestureDetector(
                onPanStart: (d) => setState(() {
                  strokes.add([d.localPosition]);
                  strokeColors.add(brush);
                }),
                onPanUpdate: (d) => setState(() => strokes.last.add(d.localPosition)),
                onPanEnd: (_) {
                  sfx('audio/sfx/rustle.mp3');
                  tried();
                },
                child: CustomPaint(painter: _StrokePainter(strokes, strokeColors), size: Size.infinite),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final c in colors)
              GestureDetector(
                onTap: () => setState(() => brush = c),
                child: Container(
                  width: c == brush ? 50 : 40,
                  height: c == brush ? 50 : 40,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: G.soft(),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _hangScene(BoxConstraints box, double s) => Stack(
    children: [
      // نخ آویزان
      Positioned.fill(child: CustomPaint(painter: _StringPainter())),
      for (var i = 0; i < 6; i++)
        Positioned(
          left: box.maxWidth * (.08 + i * .15),
          top: box.maxHeight * (.18 + math.sin(i / 5 * math.pi) * .14),
          child: GestureDetector(
            onTap: () => _hang(i),
            child: SizedBox(
              key: _spots[i],
              width: 64,
              height: 80,
              child: hung.contains(i)
                  ? PopIn(
                      child: Idle(
                        seed: i,
                        child: GameArt(id == 'decorations' ? const ['lantern', 'flag', 'mask'][i % 3] : 'flag', size: 64),
                      ),
                    )
                  : Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white70,
                          border: Border.all(color: G.purple, width: 3),
                        ),
                        child: const Icon(Icons.add_rounded, color: G.purple),
                      ),
                    ),
            ),
          ),
        ),
      Positioned(
        left: 0,
        bottom: 0,
        child: PopoMascot(pose: hung.length > 3 ? PopoPose.happy : PopoPose.pointing, size: s * .32),
      ),
    ],
  );

  Widget _letterScene(BoxConstraints box, double s) => Center(
    child: GestureDetector(
      onTap: _open,
      child: SizedBox(
        width: s * .7,
        height: s * .7,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedSlide(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              offset: opened ? const Offset(0, -.35) : Offset.zero,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: opened ? 1 : 0,
                child: GameArt('invitation', size: s * .45),
              ),
            ),
            Positioned(bottom: 0, child: GameArt('letter', size: s * .55)),
            if (!opened && tries == 0)
              const Positioned(
                bottom: 10,
                child: IgnorePointer(child: Text('👆', style: TextStyle(fontSize: 46))),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _photoScene(BoxConstraints box, double s) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        key: _popo,
        width: s * .62,
        height: s * .62,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PopoMascot(pose: tries.isEven ? PopoPose.happy : PopoPose.welcome, size: s * .4),
            GameArt(id, size: s * .62),
          ],
        ),
      ),
      Positioned(
        bottom: 0,
        child: GestureDetector(
          onTap: _photo,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: G.blue,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: G.soft(),
            ),
            child: const Icon(Icons.photo_camera_rounded, color: Colors.white, size: 40),
          ),
        ),
      ),
      if (flash)
        Positioned.fill(
          child: IgnorePointer(child: Container(color: Colors.white)),
        ),
    ],
  );

  Widget _mapScene(BoxConstraints box, double s) {
    Offset at(double t) => Offset(box.maxWidth * (.12 + .76 * t), box.maxHeight * (.65 - math.sin(t * math.pi * 2) * .22 - t * .2));
    final p = at(mapT);
    return GestureDetector(
      onPanUpdate: (d) {
        // نزدیک‌ترین نقطه‌ی کمی جلوتر روی راه
        var best = mapT;
        for (var t = mapT; t <= math.min(1, mapT + .1); t += .01) {
          if ((at(t) - d.localPosition).distance < (at(best) - d.localPosition).distance) best = t;
        }
        if (best > mapT) {
          setState(() => mapT = best);
          if (mapT > .98) _treasure();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: .9,
              child: FittedBox(
                fit: BoxFit.cover,
                child: GameArt('map', size: s),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _DotsPainter(at))),
          Positioned(
            left: at(1).dx - 30,
            top: at(1).dy - 30,
            child: const Icon(Icons.close_rounded, color: G.red, size: 60),
          ),
          Positioned(
            left: p.dx - 35,
            top: p.dy - 60,
            child: const IgnorePointer(child: PopoMascot(pose: PopoPose.happy, size: 70)),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes, this.colors);

  final List<List<Offset>> strokes;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (i, s) in strokes.indexed) {
      if (s.length < 2) continue;
      final p = Path()..moveTo(s.first.dx, s.first.dy);
      for (final o in s.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_StrokePainter old) => true;
}

class _StringPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()..moveTo(0, s.height * .18);
    p.quadraticBezierTo(s.width / 2, s.height * .42, s.width, s.height * .18);
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(_StringPainter old) => false;
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.at);

  final Offset Function(double) at;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = G.red;
    for (var t = 0.0; t <= 1; t += .04) {
      canvas.drawCircle(at(t), 5, p);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => false;
}
