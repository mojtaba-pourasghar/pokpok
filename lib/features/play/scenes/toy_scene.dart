import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/theme.dart';
import '../../../core/audio/popo_audio.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import '../../mascot/popo_mascot.dart';
import 'scene_base.dart';

/// اسباب‌بازی‌ها و ساخته‌های دیگر، هر کدام با بازی خودش:
/// حباب (ساختن و ترکاندن)، بادبادک (با انگشت در باد ببر)، ربات (با دکمه‌های جهت تا گل)،
/// آسیاب بادی (فوت کن تا بچرخد)، ماهیگیری آهن‌ربایی، خانه (چراغ پنجره‌ها)، عروسک (بغل)،
/// چراغ راهنمایی (ماشین می‌ایستد و می‌رود)، پل (ماشین‌ها رد می‌شوند).
class ToyScene extends ShowcaseScene {
  const ToyScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<ToyScene> createState() => _ToySceneState();
}

class _ToySceneState extends ConsumerState<ToyScene> with SceneBase, SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  final _main = GlobalKey();
  Duration _now = Duration.zero;
  double t = 0;

  // حباب
  final List<(Offset, double, double)> bubbles = [];
  // بادبادک
  Offset kite = const Offset(.6, .3);
  Offset kiteAt = const Offset(.6, .3);
  // ربات روی شبکه‌ی ۴×۳
  (int, int) robot = (0, 2);
  final (int, int) flower = (3, 0);
  // آسیاب
  double spin = 0;
  double spinSpeed = 0;
  // ماهی‌ها
  final Set<int> caught = {};
  Offset rod = const Offset(.5, .2);
  // خانه
  final Set<int> lights = {};
  // چراغ راهنمایی: 0 قرمز، 1 زرد، 2 سبز
  int signal = 0;
  double carX = 0;
  int hugs = 0;

  String get kind => widget.item.kind;

  @override
  void initState() {
    super.initState();
    // فقط اسباب‌بازی‌هایی که خودشان حرکت می‌کنند هر فریم به‌روز می‌شوند (باتری و گوشی‌های ضعیف).
    if (const {'bubbles', 'kite', 'windmill', 'magnet', 'signal', 'build', 'house'}.contains(kind)) _ticker.start();
    autoPlay(() {
      switch (kind) {
        case 'bubbles':
          _blow();
        case 'robot':
          _move(1, 0);
        case 'windmill':
          _blowMill();
        case 'signal':
          _switchSignal();
        case 'house':
          _light(lights.length % 4);
        case 'doll':
          _hug();
        case 'magnet':
          _catch(caught.length % 4);
        default:
          tried();
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = _now == Duration.zero ? 1 / 60 : ((now - _now).inMicroseconds / 1e6).clamp(0.0, .05);
    _now = now;
    t += dt;
    setState(() {
      for (var i = 0; i < bubbles.length; i++) {
        final (p, r, born) = bubbles[i];
        bubbles[i] = (p + Offset(math.sin(t * 2 + born) * .002, -.0025), r, born);
      }
      bubbles.removeWhere((b) => b.$1.dy < -.1);
      kite = Offset.lerp(kite, kiteAt, dt * 2.5)!;
      spin += spinSpeed * dt;
      spinSpeed *= math.pow(.6, dt).toDouble();
      // ماشین: پشت چراغ قرمز می‌ایستد
      final stopLine = .38;
      final next = carX + dt * .25;
      if (!(signal == 0 && carX < stopLine && next >= stopLine)) carX = next > 1.15 ? -.15 : next;
    });
  }

  void _blow() {
    sfx(widget.item.sound);
    final rnd = math.Random();
    setState(() {
      for (var k = 0; k < 4; k++) {
        bubbles.add((Offset(.3 + rnd.nextDouble() * .4, .75), 22 + rnd.nextDouble() * 26, t + k));
      }
    });
  }

  void _pop(int i, BuildContext c) {
    c.fx(Fx.bubbles, count: 6);
    ui(UiSound.pop);
    setState(() => bubbles.removeAt(i));
    tried();
  }

  void _move(int dx, int dy) {
    final (x, y) = robot;
    final nx = (x + dx).clamp(0, 3), ny = (y + dy).clamp(0, 2);
    setState(() => robot = (nx, ny));
    sfx('audio/sfx/robot.mp3', volume: .7);
    if (robot == flower) {
      burstAt(_main, Fx.drops, count: 12);
      burstAt(_main, Fx.hearts, count: 4);
      tried();
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) setState(() => robot = (0, 2));
      });
    }
  }

  void _blowMill() {
    sfx(widget.item.sound);
    setState(() => spinSpeed += 9);
    burstAt(_main, Fx.dust, count: 6, color: Colors.white);
    tried();
  }

  void _catch(int i) {
    if (caught.contains(i)) return;
    sfx(widget.item.sound);
    setState(() => caught.add(i));
    tried();
    if (caught.length == 4) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) setState(caught.clear);
      });
    }
  }

  void _light(int i) {
    setState(() => lights.contains(i) ? lights.remove(i) : lights.add(i));
    sfx('audio/sfx/light_switch.mp3');
    if (lights.length == 4) {
      burstAt(_main, Fx.sparkle, count: 16);
      tried();
    }
  }

  void _switchSignal() {
    setState(() => signal = (signal + 1) % 3);
    sfx(widget.item.sound);
    if (signal == 2) tried();
  }

  void _hug() {
    setState(() => hugs++);
    sfx(widget.item.sound);
    burstAt(_main, Fx.hearts, count: 7);
    tried();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      return switch (kind) {
        'bubbles' => _bubbles(box, s),
        'kite' => _kite(box, s),
        'robot' => _robot(box, s),
        'windmill' => _windmill(box, s),
        'magnet' => _magnet(box, s),
        'house' => _house(box, s),
        'signal' => _signal(box, s),
        'build' => _bridge(box, s),
        _ => _doll(box, s),
      };
    },
  );

  Widget _bubbles(BoxConstraints box, double s) => Stack(
    children: [
      for (final (i, (p, r, _)) in bubbles.indexed)
        Positioned(
          left: p.dx * box.maxWidth - r,
          top: p.dy * box.maxHeight - r,
          child: Builder(
            builder: (c) => GestureDetector(
              onTap: () => _pop(i, c),
              child: Container(
                width: r * 2,
                height: r * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    center: Alignment(-.4, -.4),
                    colors: [Color(0xCCFFFFFF), Color(0x55B3E5FC), Color(0x66F8BBD0)],
                  ),
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ),
        ),
      Positioned(
        left: box.maxWidth / 2 - s * .18,
        bottom: 0,
        child: GestureDetector(
          onTap: _blow,
          child: SizedBox(
            key: _main,
            child: GameArt(widget.item.id, size: s * .36),
          ),
        ),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: PopoMascot(pose: bubbles.isEmpty ? PopoPose.curious : PopoPose.happy, size: s * .3),
      ),
      if (tries == 0 && bubbles.isEmpty && !widget.auto)
        const Positioned(top: 0, left: 0, right: 0, child: Center(child: _Tip('حباب‌ساز را لمس کن، بعد حباب‌ها را بترکان!'))),
    ],
  );

  Widget _kite(BoxConstraints box, double s) {
    final k = Offset(kite.dx * box.maxWidth, kite.dy * box.maxHeight);
    final hand = Offset(box.maxWidth * .18, box.maxHeight * .8);
    return GestureDetector(
      onPanUpdate: (d) {
        setState(
          () => kiteAt = Offset((d.localPosition.dx / box.maxWidth).clamp(.2, .9), (d.localPosition.dy / box.maxHeight).clamp(.08, .6)),
        );
        if ((d.delta.distance) > 12) {
          sfx(widget.item.sound, volume: .4);
        }
      },
      onPanEnd: (_) => tried(),
      child: Stack(
        children: [
          Container(color: Colors.transparent),
          Positioned.fill(child: CustomPaint(painter: _KiteString(hand, k + Offset(0, s * .1), t))),
          Positioned(
            left: k.dx - s * .14,
            top: k.dy - s * .14,
            child: Transform.rotate(
              angle: math.sin(t * 3) * .18,
              child: GameArt(widget.item.id, size: s * .28),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: PopoMascot(pose: PopoPose.happy, size: s * .3),
          ),
          if (tries == 0 && !widget.auto)
            const Positioned(top: 0, left: 0, right: 0, child: Center(child: _Tip('با انگشت بادبادک را در باد ببر!'))),
        ],
      ),
    );
  }

  Widget _robot(BoxConstraints box, double s) {
    final cell = math.min(box.maxWidth / 4.4, (box.maxHeight - 110) / 3.2);
    final (rx, ry) = robot;
    return Column(
      children: [
        SizedBox(
          width: cell * 4,
          height: cell * 3,
          child: Stack(
            children: [
              for (var y = 0; y < 3; y++)
                for (var x = 0; x < 4; x++)
                  Positioned(
                    left: x * cell,
                    top: y * cell,
                    child: Container(
                      width: cell - 4,
                      height: cell - 4,
                      decoration: BoxDecoration(
                        color: (x + y).isEven ? const Color(0xAAFFFFFF) : const Color(0x88E8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              Positioned(
                left: flower.$1 * cell,
                top: flower.$2 * cell,
                child: GameArt('flower_pot', size: cell - 4),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: rx * cell,
                top: ry * cell,
                child: SizedBox(
                  key: _main,
                  child: GameArt(widget.item.id, size: cell - 4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Arrow(Icons.arrow_upward_rounded, () => _move(0, -1)),
            _Arrow(Icons.arrow_downward_rounded, () => _move(0, 1)),
            // راست‌چین: «جلو» به سمت گل یعنی x بیشتر
            _Arrow(Icons.arrow_back_rounded, () => _move(1, 0)),
            _Arrow(Icons.arrow_forward_rounded, () => _move(-1, 0)),
          ],
        ),
      ],
    );
  }

  Widget _windmill(BoxConstraints box, double s) => Stack(
    alignment: Alignment.center,
    children: [
      GestureDetector(
        onTap: _blowMill,
        onPanUpdate: (d) {
          if (d.delta.distance > 6) setState(() => spinSpeed += .4);
        },
        child: Transform.rotate(
          key: _main,
          angle: spin,
          child: GameArt(widget.item.id, size: s * .65),
        ),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: PopoMascot(pose: spinSpeed > 2 ? PopoPose.happy : PopoPose.curious, size: s * .3),
      ),
      if (tries == 0 && !widget.auto) const Positioned(top: 0, child: _Tip('فوت کن! (لمس کن یا انگشتت را بکش)')),
    ],
  );

  Widget _magnet(BoxConstraints box, double s) => GestureDetector(
    onPanUpdate: (d) =>
        setState(() => rod = Offset((d.localPosition.dx / box.maxWidth).clamp(0, 1), (d.localPosition.dy / box.maxHeight).clamp(0, 1))),
    child: Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: box.maxHeight * .55,
          child: Container(
            decoration: BoxDecoration(color: const Color(0x884FC3F7), borderRadius: BorderRadius.circular(26)),
          ),
        ),
        for (var i = 0; i < 4; i++)
          Builder(
            builder: (c) {
              final x = caught.contains(i) ? rod.dx : (.15 + i * .22 + math.sin(t * (1 + i * .2) + i) * .06);
              final y = caught.contains(i) ? rod.dy + .1 : .62 + (i % 2) * .15;
              final near =
                  (Offset(x * box.maxWidth, y * box.maxHeight) - Offset(rod.dx * box.maxWidth, rod.dy * box.maxHeight + 40)).distance < 60;
              if (near && !caught.contains(i)) {
                WidgetsBinding.instance.addPostFrameCallback((_) => _catch(i));
              }
              return Positioned(left: x * box.maxWidth - 32, top: y * box.maxHeight - 32, child: const GameArt('fish', size: 64));
            },
          ),
        Positioned(
          left: rod.dx * box.maxWidth - 40,
          top: rod.dy * box.maxHeight - 40,
          child: IgnorePointer(
            child: SizedBox(key: _main, child: const GameArt('magnet', size: 80)),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: CountChip(icon: Icons.set_meal_rounded, value: caught.length, color: G.orange, label: 'ماهی'),
        ),
        if (tries == 0 && !widget.auto)
          const Positioned(top: 0, left: 0, right: 60, child: Center(child: _Tip('آهن‌ربا را روی ماهی‌ها ببر!'))),
      ],
    ),
  );

  Widget _house(BoxConstraints box, double s) => Stack(
    alignment: Alignment.center,
    children: [
      SizedBox(
        key: _main,
        child: GameArt(widget.item.id, size: s * .7),
      ),
      for (var i = 0; i < 4; i++)
        Positioned(
          left: box.maxWidth / 2 + (i.isEven ? -s * .17 : s * .07),
          top: box.maxHeight / 2 + (i < 2 ? -s * .1 : s * .08),
          child: GestureDetector(
            onTap: () => _light(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: s * .1,
              height: s * .1,
              decoration: BoxDecoration(
                color: lights.contains(i) ? const Color(0xFFFFE082) : const Color(0x553949AB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: lights.contains(i) ? const [BoxShadow(color: Color(0xAAFFE082), blurRadius: 18, spreadRadius: 4)] : null,
              ),
            ),
          ),
        ),
      if (widget.item.id == 'bird_house')
        Positioned(
          right: box.maxWidth * .1 + math.sin(t) * 30,
          top: box.maxHeight * .1 + math.cos(t * 1.3) * 16,
          child: GestureDetector(
            onTap: () {
              sfx('audio/animals/bird.mp3');
              tried();
            },
            child: const Text('🐦', style: TextStyle(fontSize: 46)),
          ),
        ),
      if (tries == 0 && !widget.auto) const Positioned(top: 0, child: _Tip('پنجره‌ها را لمس کن تا چراغ‌ها روشن شوند!')),
    ],
  );

  Widget _signal(BoxConstraints box, double s) => Stack(
    children: [
      Positioned(
        left: 0,
        right: 0,
        top: box.maxHeight * .62,
        height: box.maxHeight * .2,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFF6D6E78), borderRadius: BorderRadius.circular(16)),
        ),
      ),
      Positioned(
        left: box.maxWidth * .38 + 20,
        top: box.maxHeight * .62,
        height: box.maxHeight * .2,
        child: Container(width: 8, color: Colors.white),
      ),
      Positioned(
        left: carX * box.maxWidth - s * .12,
        top: box.maxHeight * .6,
        child: GameArt('toy_car', size: s * .24),
      ),
      Positioned(
        left: box.maxWidth * .45,
        top: box.maxHeight * .05,
        child: GestureDetector(
          onTap: _switchSignal,
          child: Container(
            key: _main,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF37474F),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 4),
            ),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: s * .12,
                    height: s * .12,
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: [
                        const Color(0xFFF44336),
                        const Color(0xFFFFEB3B),
                        const Color(0xFF4CAF50),
                      ][i].withValues(alpha: signal == i ? 1 : .2),
                      boxShadow: signal == i
                          ? [
                              BoxShadow(
                                color: [const Color(0xFFF44336), const Color(0xFFFFEB3B), const Color(0xFF4CAF50)][i],
                                blurRadius: 18,
                              ),
                            ]
                          : null,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 0,
        top: 0,
        child: _Tip(
          signal == 0
              ? 'قرمز: ماشین بایست!'
              : signal == 1
              ? 'زرد: آماده باش'
              : 'سبز: برو!',
        ),
      ),
    ],
  );

  Widget _bridge(BoxConstraints box, double s) => Stack(
    children: [
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: box.maxHeight * .35,
        child: Container(
          decoration: BoxDecoration(color: const Color(0xAA4FC3F7), borderRadius: BorderRadius.circular(26)),
        ),
      ),
      Positioned(
        left: box.maxWidth / 2 - s * .4,
        top: box.maxHeight * .3,
        child: SizedBox(
          key: _main,
          child: GameArt(widget.item.id, size: s * .8),
        ),
      ),
      Positioned(
        left: carX * box.maxWidth - s * .1,
        top: box.maxHeight * .32 - math.sin(carX.clamp(0, 1) * math.pi) * s * .08,
        child: GestureDetector(
          onTap: () {
            sfx('audio/sfx/car_horn.mp3');
            burstAt(_main, Fx.notes, count: 3);
            tried();
          },
          child: GameArt('bus', size: s * .2),
        ),
      ),
      if (tries == 0 && !widget.auto)
        const Positioned(top: 0, left: 0, right: 0, child: Center(child: _Tip('روی اتوبوس بزن تا بوق بزند!'))),
    ],
  );

  Widget _doll(BoxConstraints box, double s) => Stack(
    children: [
      Positioned(
        left: 0,
        bottom: 0,
        child: PopoMascot(pose: hugs > 0 ? PopoPose.happy : PopoPose.curious, size: s * .5),
      ),
      Positioned(
        right: box.maxWidth * .1,
        bottom: box.maxHeight * .1,
        child: GestureDetector(
          onTap: _hug,
          child: Squash(
            key: _main,
            trigger: hugs,
            child: GameArt(widget.item.id, size: s * .45),
          ),
        ),
      ),
      if (tries == 0 && !widget.auto) const Positioned(top: 0, left: 0, right: 0, child: Center(child: _Tip('لمسش کن تا بغلش کنی!'))),
    ],
  );
}

class _Arrow extends StatelessWidget {
  const _Arrow(this.icon, this.onTap);

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Pressable(
      onTap: onTap,
      color: G.blue,
      depth: 5,
      sound: null,
      child: SizedBox(width: 64, height: 58, child: Icon(icon, color: Colors.white, size: 34)),
    ),
  );
}

class _Tip extends StatelessWidget {
  const _Tip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
    child: Text(text, style: PText.heading.copyWith(color: G.purple, fontSize: 15)),
  );
}

class _KiteString extends CustomPainter {
  _KiteString(this.from, this.to, this.t);

  final Offset from, to;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = Offset.lerp(from, to, .5)! + Offset(math.sin(t * 2) * 20, 30);
    final p = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
    canvas.drawPath(
      p,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_KiteString old) => true;
}
