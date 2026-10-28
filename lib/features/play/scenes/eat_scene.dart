import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import '../../mascot/popo_mascot.dart';
import 'scene_base.dart';

/// خوردن و نوشیدن: کودک غذا را به دهان پوپو (یا دوست) می‌برد؛ هر گاز یک تکه از غذا برمی‌دارد،
/// خرده‌ها می‌ریزند، پوپو له و کش می‌شود و مزه را می‌گوید. نوشیدنی کم‌کم پایین می‌رود و حباب می‌دهد.
class EatScene extends ShowcaseScene {
  const EatScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<EatScene> createState() => _EatSceneState();
}

class _EatSceneState extends ConsumerState<EatScene> with SceneBase {
  static const bitesPerServing = 3;
  final _popo = GlobalKey();
  final _friend = GlobalKey();
  final _plate = GlobalKey();
  int bites = 0;
  int chew = 0;
  int friendChew = 0;
  bool showTaste = false;
  final List<Offset> _bitePoints = [];
  final _rnd = math.Random(4);

  bool get drink => widget.item.kind == 'drink';

  @override
  void initState() {
    super.initState();
    autoPlay(() => _eat(toFriend: false));
  }

  void _eat({required bool toFriend}) {
    sfx(widget.item.sound);
    final target = toFriend ? _friend : _popo;
    // خرده یا حباب از دهان
    burstAt(target, drink ? Fx.bubbles : Fx.crumbs, offset: const Offset(0, -10), count: drink ? 8 : 12);
    setState(() {
      if (toFriend) {
        friendChew++;
      } else {
        chew++;
      }
      bites++;
      _bitePoints.add(Offset(_rnd.nextDouble() * .6 + .2, _rnd.nextDouble() * .5 + .1));
    });
    if (bites == 1 && widget.item.taste != null) {
      setState(() => showTaste = true);
      say('item.${widget.item.id}.taste');
    }
    if (bites % bitesPerServing == 0) {
      // تمام شد: قلب‌ها، و یک بشقاب تازه
      burstAt(target, Fx.hearts, offset: const Offset(0, -40));
      Future.delayed(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(_bitePoints.clear);
        burstAt(_plate, Fx.sparkle, count: 10);
      });
    }
    tried();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      final left = bitesPerServing - bites % bitesPerServing;
      final food = _Bitten(id: widget.item.id, size: s * .36, drink: drink, level: left / bitesPerServing, bites: _bitePoints);
      final friend = widget.friend;
      return Stack(
        children: [
          // پوپو
          Positioned(
            left: 0,
            bottom: 0,
            child: DragTarget<String>(
              onAcceptWithDetails: (_) => _eat(toFriend: false),
              builder: (context, cand, _) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Squash(
                    key: _popo,
                    trigger: chew,
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: cand.isNotEmpty ? 1.08 : 1,
                      child: PopoMascot(pose: chew > 0 ? PopoPose.happy : PopoPose.curious, size: s * .5),
                    ),
                  ),
                  GroundShadow(width: s * .3),
                ],
              ),
            ),
          ),
          // دوست (در بازی آزاد)
          if (friend != null && widget.play)
            Positioned(
              right: 0,
              bottom: 0,
              child: DragTarget<String>(
                onAcceptWithDetails: (_) => _eat(toFriend: true),
                builder: (context, cand, _) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Squash(
                      key: _friend,
                      trigger: friendChew,
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 200),
                        scale: cand.isNotEmpty ? 1.08 : 1,
                        child: GameArt(friend, size: s * .42),
                      ),
                    ),
                    GroundShadow(width: s * .26),
                  ],
                ),
              ),
            ),
          // بشقاب و غذا
          Positioned(
            right: friend != null && widget.play ? box.maxWidth * .32 : box.maxWidth * .08,
            top: box.maxHeight * .12,
            child: Column(
              key: _plate,
              mainAxisSize: MainAxisSize.min,
              children: [
                Draggable<String>(
                  data: widget.item.id,
                  feedback: Transform.scale(scale: 1.1, child: food),
                  childWhenDragging: Opacity(opacity: .25, child: food),
                  child: GestureDetector(
                    onTap: () => _eat(toFriend: false),
                    child: Idle(seed: 5, amount: .5, child: food),
                  ),
                ),
                Container(
                  width: s * .44,
                  height: s * .08,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.elliptical(s * .22, s * .04)),
                    boxShadow: G.soft(),
                  ),
                ),
              ],
            ),
          ),
          if (showTaste && widget.item.taste != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: PopIn(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: G.orange,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: G.soft(),
                    ),
                    child: Text('مزه: ${widget.item.taste}', style: PText.title.copyWith(color: Colors.white, fontSize: 20)),
                  ),
                ),
              ),
            ),
          if (bites == 0 && !widget.auto)
            Positioned(
              right: box.maxWidth * .3,
              top: box.maxHeight * .45,
              child: IgnorePointer(child: HandHint(dx: -box.maxWidth * .35)),
            ),
        ],
      );
    },
  );
}

/// غذای گازخورده: دایره‌هایی از لبه‌اش برداشته شده؛ نوشیدنی از بالا کم می‌شود.
class _Bitten extends StatelessWidget {
  const _Bitten({required this.id, required this.size, required this.drink, required this.level, required this.bites});

  final String id;
  final double size;
  final bool drink;
  final double level;
  final List<Offset> bites;

  @override
  Widget build(BuildContext context) {
    final art = GameArt(id, size: size);
    if (drink) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Opacity(opacity: .3, child: art),
            ClipRect(
              child: Align(alignment: Alignment.bottomCenter, heightFactor: .25 + .75 * level, child: art),
            ),
          ],
        ),
      );
    }
    return ClipPath(clipper: _BiteClipper(bites), child: art);
  }
}

class _BiteClipper extends CustomClipper<Path> {
  _BiteClipper(this.bites);

  final List<Offset> bites;

  @override
  Path getClip(Size s) {
    var p = Path()..addRect(Offset.zero & s);
    for (final b in bites) {
      // گاز از لبه‌ی بالایی/کناری: سه دایره‌ی کنار هم مثل جای دندان
      final c = Offset(b.dx * s.width, b.dy * s.height * .7);
      final r = s.width * .17;
      final bite = Path()
        ..addOval(Rect.fromCircle(center: c, radius: r))
        ..addOval(Rect.fromCircle(center: c + Offset(r * .8, r * .2), radius: r * .7))
        ..addOval(Rect.fromCircle(center: c + Offset(-r * .8, r * .2), radius: r * .7));
      p = Path.combine(PathOperation.difference, p, bite);
    }
    return p;
  }

  @override
  bool shouldReclip(_BiteClipper old) => old.bites.length != bites.length;
}

/// دست راهنمایی که آرام از جایی به جایی می‌کشد (پیش از اولین کار کودک).
class HandHint extends StatefulWidget {
  const HandHint({super.key, this.dx = 0, this.dy = 0});

  final double dx;
  final double dy;

  @override
  State<HandHint> createState() => _HandHintState();
}

class _HandHintState extends State<HandHint> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) {
      final t = Curves.easeInOut.transform(_c.value);
      return Opacity(
        opacity: _c.value < .85 ? 1 : (1 - _c.value) / .15,
        child: Transform.translate(
          offset: Offset(widget.dx * t, widget.dy * t + (widget.dx == 0 && widget.dy == 0 ? math.sin(_c.value * math.pi * 4) * 8 : 0)),
          child: const Text('👆', style: TextStyle(fontSize: 50)),
        ),
      );
    },
  );
}
