import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../app/theme/theme.dart';
import '../../../core/audio/popo_audio.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import 'scene_base.dart';

/// وسیله‌ی نقلیه: اول کلید (روشن شدن: لرزش، دود، چراغ‌ها)، بعد با نگه داشتن پدال راه می‌افتد —
/// جاده و درخت‌ها و خانه‌ها رد می‌شوند، چرخ‌ها بالا و پایین می‌پرند، دود از اگزوز بیرون می‌آید؛
/// دکمه‌ی بوق صدای خودش را دارد. موشک به جای جاده بالا می‌رود، زیردریایی زیر آب حرکت می‌کند.
class DriveScene extends ShowcaseScene {
  const DriveScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<DriveScene> createState() => _DriveSceneState();
}

class _DriveSceneState extends ConsumerState<DriveScene> with SceneBase, SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick)..start();
  final _vehicle = GlobalKey();
  final _horn = GlobalKey();
  bool started = false;
  bool gas = false;
  double speed = 0;
  double distance = 0;
  double _lastLap = 0;
  int shake = 0;
  Duration _last = Duration.zero;
  double _smokeAcc = 0;

  String get kind => widget.item.kind;
  bool get rocket => kind == 'rocket';
  bool get underwater => kind == 'submarine';

  String get hornSound => switch (widget.item.id) {
    'bus' => 'audio/sfx/bus_horn.mp3',
    'bicycle' => 'audio/sfx/bike_bell.mp3',
    'train' => 'audio/sfx/train.mp3',
    'submarine' => 'audio/sfx/bubbles.mp3',
    'rocket' => 'audio/ui/whoosh.mp3',
    'cart' => 'audio/sfx/squeak.mp3',
    _ => 'audio/sfx/car_horn.mp3',
  };

  @override
  void initState() {
    super.initState();
    if (widget.auto) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        _start();
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => gas = true);
        });
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _start() {
    if (started) return;
    sfx(widget.item.sound);
    setState(() {
      started = true;
      shake++;
    });
    burstAt(_vehicle, Fx.smoke, offset: const Offset(-60, 20), count: 10);
    tried();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : ((now - _last).inMicroseconds / 1e6).clamp(0.0, .05);
    _last = now;
    final target = started && gas ? 1.0 : 0.0;
    speed += (target - speed) * dt * (gas ? 1.6 : 2.4);
    if (speed < .002 && !gas) {
      if (speed != 0) setState(() => speed = 0);
      return;
    }
    distance += speed * dt * 420;
    _smokeAcc += speed * dt;
    if (_smokeAcc > .12) {
      _smokeAcc = 0;
      if (rocket) {
        burstAt(_vehicle, Fx.smoke, offset: const Offset(0, 70), count: 3, color: const Color(0xFFFFCC80));
      } else if (underwater) {
        burstAt(_vehicle, Fx.bubbles, offset: const Offset(-60, 0), count: 2);
      } else if (kind != 'cart' && widget.item.id != 'bicycle') {
        burstAt(_vehicle, Fx.smoke, offset: const Offset(-70, 25), count: 1);
      }
    }
    if (distance - _lastLap > 900) {
      _lastLap = distance;
      tried();
      burstAt(_vehicle, Fx.sparkle, count: 10);
      ui(UiSound.chime);
    }
    setState(() {});
  }

  void _honk() {
    sfx(hornSound);
    burstAt(_horn, Fx.notes, count: 3);
    burstAt(_vehicle, Fx.notes, offset: const Offset(40, -40), count: 3);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      final size = s * .48;
      final bounce = started ? math.sin(distance / 18) * 3 * speed + (speed > .05 ? 0 : math.sin(_last.inMilliseconds / 60) * 1.2) : 0.0;
      final rise = rocket ? -math.min(distance / 4, box.maxHeight * .35) : 0.0;
      return Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WorldPainter(distance: distance, rocket: rocket, underwater: underwater),
            ),
          ),
          // چیزهای کنار راه که رد می‌شوند
          if (!rocket)
            for (var k = 0; k < 4; k++)
              Positioned(
                left: (box.maxWidth + 140) - ((distance * .8 + k * (box.maxWidth + 140) / 4) % (box.maxWidth + 140)) - 70,
                top: box.maxHeight * (underwater ? .15 + k % 2 * .3 : .2),
                child: IgnorePointer(
                  child: GameArt(
                    underwater ? 'fish' : const ['flower_pot', 'dollhouse', 'traffic_light', 'bird_house'][k % 4],
                    size: underwater ? s * .16 : s * .22,
                  ),
                ),
              ),
          Positioned(
            left: box.maxWidth / 2 - size / 2,
            top: (rocket ? box.maxHeight * .45 : box.maxHeight * .5) - size / 2 + rise + bounce,
            child: ShakeScene(
              trigger: shake,
              strength: 7,
              child: Stack(
                key: _vehicle,
                clipBehavior: Clip.none,
                children: [
                  if (rocket && speed > .05)
                    Positioned(
                      left: size * .38,
                      top: size * .82,
                      child: _Flame(width: size * .24, power: speed),
                    ),
                  GameArt(widget.item.id, size: size, label: widget.item.title),
                  if (started && !rocket && !underwater)
                    // چراغ جلو
                    Positioned(
                      right: -size * .25,
                      top: size * .42,
                      child: IgnorePointer(
                        child: Container(
                          width: size * .45,
                          height: size * .22,
                          decoration: BoxDecoration(
                            gradient: const RadialGradient(colors: [Color(0x99FFF3B0), Color(0x00FFF3B0)]),
                            borderRadius: BorderRadius.circular(size),
                          ),
                        ),
                      ),
                    ),
                  if (widget.play && widget.friend != null)
                    Positioned(
                      left: size * .3,
                      top: -size * .22,
                      child: GameArt(widget.friend!, size: size * .38),
                    ),
                ],
              ),
            ),
          ),
          // کنترل‌ها
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!started)
                  _Control(icon: Icons.key_rounded, label: rocket ? 'روشن کن' : 'استارت', color: G.orange, glow: true, onDown: _start)
                else
                  _Control(
                    icon: rocket ? Icons.rocket_launch_rounded : Icons.speed_rounded,
                    label: rocket ? 'نگه دار تا پرواز کند' : 'نگه دار تا برود',
                    color: G.green,
                    glow: distance == 0,
                    onDown: () => setState(() => gas = true),
                    onUp: () => setState(() => gas = false),
                  ),
                _Control(key: _horn, icon: Icons.campaign_rounded, label: 'بوق', color: G.blue, onDown: _honk),
              ],
            ),
          ),
          Positioned(
            top: 4,
            left: 8,
            child: CountChip(icon: Icons.flag_rounded, value: (distance / 90).floor(), color: G.green, label: 'متر'),
          ),
        ],
      );
    },
  );
}

class _Control extends StatelessWidget {
  const _Control({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onDown,
    this.onUp,
    this.glow = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onDown;
  final VoidCallback? onUp;
  final bool glow;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    // Listener: نگه داشتن طولانی با ژست فشار طولانی لغو نمی‌شود.
    child: Listener(
      onPointerDown: (_) => onDown(),
      onPointerUp: (_) => onUp?.call(),
      onPointerCancel: (_) => onUp?.call(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: [
                ...G.soft(),
                if (glow) const BoxShadow(color: Color(0xCCFFE066), blurRadius: 24, spreadRadius: 6),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999)),
            child: Text(label, style: PText.label.copyWith(fontSize: 14)),
          ),
        ],
      ),
    ),
  );
}

/// جاده (یا آسمان یا زیر آب) که با [distance] حرکت می‌کند.
class _WorldPainter extends CustomPainter {
  _WorldPainter({required this.distance, required this.rocket, required this.underwater});

  final double distance;
  final bool rocket;
  final bool underwater;

  @override
  void paint(Canvas canvas, Size s) {
    if (rocket) {
      // آسمان که با بالا رفتن تیره می‌شود و ستاره‌ها
      final h = (distance / 2000).clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(const Color(0x00000000), const Color(0xEE101438), h)!,
              Color.lerp(const Color(0x00000000), const Color(0xAA26318A), h)!,
            ],
          ).createShader(Offset.zero & s),
      );
      final star = Paint()..color = Colors.white.withValues(alpha: h);
      final rnd = math.Random(3);
      for (var i = 0; i < 40; i++) {
        final y = (rnd.nextDouble() * s.height + distance * .6) % s.height;
        canvas.drawCircle(Offset(rnd.nextDouble() * s.width, y), rnd.nextDouble() * 2 + .6, star);
      }
      return;
    }
    if (underwater) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(24)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x884FC3F7), Color(0xCC0D47A1)],
          ).createShader(Offset.zero & s),
      );
      return;
    }
    // جاده با خط‌چین وسط که عقب می‌رود
    final top = s.height * .5;
    final road = Rect.fromLTWH(0, top, s.width, s.height * .3);
    canvas.drawRRect(RRect.fromRectAndRadius(road, const Radius.circular(18)), Paint()..color = const Color(0xFF6D6E78));
    final line = Paint()..color = Colors.white;
    final y = road.center.dy;
    for (var x = -((distance) % 70); x < s.width; x += 70) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y - 4, 38, 8), const Radius.circular(4)), line);
    }
    canvas.drawRect(Rect.fromLTWH(0, road.top - 6, s.width, 6), Paint()..color = const Color(0xFF9E9E9E));
  }

  @override
  bool shouldRepaint(_WorldPainter old) => old.distance != distance;
}

/// شعله‌ی موشک: لرزان، بلندی با قدرت.
class _Flame extends StatefulWidget {
  const _Flame({required this.width, required this.power});

  final double width;
  final double power;

  @override
  State<_Flame> createState() => _FlameState();
}

class _FlameState extends State<_Flame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) =>
        CustomPaint(size: Size(widget.width, widget.width * (1.4 + widget.power * 1.4 + _c.value * .4)), painter: _FlamePainter()),
  );
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(s.width * .1, s.height * .6, s.width / 2, s.height)
      ..quadraticBezierTo(s.width * .9, s.height * .6, s.width, 0)
      ..close();
    canvas.drawPath(
      p,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF59D), Color(0xFFFF9800), Color(0x00F44336)],
        ).createShader(Offset.zero & s),
    );
  }

  @override
  bool shouldRepaint(_FlamePainter old) => false;
}
