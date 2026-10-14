import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// هشت حالت پوپو. همه از یک مدل (همین نقاش) کشیده می‌شوند تا شخصیت در همه‌ی صفحه‌ها یکی بماند.
enum PopoPose { welcome, curious, thinking, happy, surprised, sleepy, pointing, idle }

/// پوپو: خرس کوچولوی نارنجی با پوزه‌ی کرم، چشم‌های درشت، گوش‌های گرد، هدفون آبی بزرگ،
/// لباس فیروزه‌ای با ستاره‌ی زرد، کوله‌ی کوچک و کفش.
///
/// همه‌ی اندازه‌ها روی یک بوم ۲۰۰×۲۶۰ تعریف شده‌اند و به اندازه‌ی واقعی مقیاس می‌شوند.
class PopoPainter extends CustomPainter {
  PopoPainter({required this.pose, this.blink = 0, this.breath = 0, this.wave = 0, this.look = Offset.zero, this.pointRight = true});

  final PopoPose pose;

  /// ۰ چشم باز، ۱ چشم بسته.
  final double blink;

  /// ۰ تا ۱، دم و بازدم آرام.
  final double breath;

  /// ۰ تا ۱، فاز دست تکان دادن.
  final double wave;

  /// جهت نگاه (−۱ تا ۱ در هر محور).
  final Offset look;
  final bool pointRight;

  static const designSize = Size(200, 260);

  Offset? _frontPaw;

  static const _fur = PColors.fur;
  static const _furDark = PColors.furDark;
  static const _muzzle = PColors.muzzle;
  static const _outfit = PColors.outfit;
  static const _phones = PColors.headphones;
  static const _ink = Color(0xFF2B2140);

  Paint _fill(Color c, Rect r, {Alignment center = const Alignment(-.35, -.45)}) => Paint()
    ..shader = RadialGradient(
      center: center,
      radius: 1.05,
      colors: [PColors.tint(c, .1), c, PColors.shade(c, .1)],
      stops: const [0, .55, 1],
    ).createShader(r);

  Paint _stroke(Color c, [double w = 3]) => Paint()
    ..color = PColors.shade(c, .2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _blob(Canvas c, Path p, Color color) {
    c.drawPath(p, _fill(color, p.getBounds()));
    c.drawPath(p, _stroke(color));
  }

  void _oval(Canvas c, Rect r, Color color) => _blob(c, Path()..addOval(r), color);

  void _capsule(Canvas c, Offset a, Offset b, double w, Color color) {
    final d = b - a;
    final len = d.distance;
    c.save();
    c.translate(a.dx, a.dy);
    c.rotate(math.atan2(d.dy, d.dx));
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(-w / 2, -w / 2, len + w, w), Radius.circular(w / 2));
    c.drawRRect(r, _fill(color, r.outerRect));
    c.drawRRect(r, _stroke(color));
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / designSize.width, size.height / designSize.height);
    canvas.save();
    canvas.translate((size.width - designSize.width * s) / 2, (size.height - designSize.height * s) / 2);
    canvas.scale(s);

    final bob = math.sin(breath * math.pi * 2) * 1.6;
    final happyHop = pose == PopoPose.happy ? -math.sin(wave * math.pi * 2).abs() * 6 : 0.0;

    // سایه‌ی زمین
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 250), width: 120 - happyHop.abs(), height: 14),
      Paint()..color = const Color(0xFF2A2250).withValues(alpha: .13),
    );

    canvas.save();
    canvas.translate(0, happyHop);
    _legs(canvas);
    canvas.save();
    canvas.translate(0, bob * .4);
    _backpack(canvas);
    _body(canvas);
    _arms(canvas);
    canvas.restore();

    // سر کمی با نفس بالا و پایین می‌رود؛ در حالت‌های کنجکاو و خواب‌آلود کج می‌شود.
    final tilt = switch (pose) {
      PopoPose.curious => -.12,
      PopoPose.sleepy => .14,
      PopoPose.thinking => .07,
      _ => 0.0,
    };
    canvas.save();
    canvas.translate(100, 150 + bob);
    canvas.rotate(tilt);
    canvas.translate(-100, -150);
    _head(canvas);
    canvas.restore();
    // پنجه‌ای که جلوی صورت است (زیر چانه در حالت فکر، جلوی دهان در حالت خواب‌آلود)
    final paw = _frontPaw;
    if (paw != null) {
      final at = pose == PopoPose.thinking ? const Offset(118, 146) : const Offset(110, 136);
      _capsule(canvas, Offset(136, 160 + bob * .4), at, 22, _outfit);
      _oval(canvas, Rect.fromCircle(center: at, radius: 13), _fur);
    }
    canvas.restore();

    if (pose == PopoPose.sleepy) _zzz(canvas);
    if (pose == PopoPose.thinking) _thought(canvas);
    if (pose == PopoPose.happy) _sparkles(canvas);
    canvas.restore();
  }

  void _legs(Canvas c) {
    for (final x in [78.0, 122.0]) {
      final leg = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 222), width: 30, height: 36), const Radius.circular(14));
      c.drawRRect(leg, _fill(_outfit, leg.outerRect));
      c.drawRRect(leg, _stroke(_outfit));
      // کفش
      final shoe = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(x + (x < 100 ? -3 : 3), 242), width: 40, height: 18),
            const Radius.circular(9),
          ),
        );
      _blob(c, shoe, PColors.blue);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + (x < 100 ? -3 : 3), 248), width: 38, height: 5),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withValues(alpha: .9),
      );
    }
  }

  void _backpack(Canvas c) {
    final bag = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(46, 150, 108, 66), const Radius.circular(24)));
    _blob(c, bag, PColors.yellow);
  }

  void _body(Canvas c) {
    final body = Path()
      ..moveTo(58, 176)
      ..cubicTo(56, 146, 74, 136, 100, 136)
      ..cubicTo(126, 136, 144, 146, 142, 176)
      ..cubicTo(144, 204, 130, 216, 100, 216)
      ..cubicTo(70, 216, 56, 204, 58, 176)
      ..close();
    _blob(c, body, _outfit);
    // بند کوله
    final strap = Paint()
      ..color = PColors.shade(PColors.yellow, .05)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(const Offset(72, 146), const Offset(76, 196), strap);
    c.drawLine(const Offset(128, 146), const Offset(124, 196), strap);
    // جیب جلو
    final pocket = RRect.fromRectAndRadius(const Rect.fromLTWH(80, 192, 40, 16), const Radius.circular(8));
    c.drawRRect(pocket, Paint()..color = PColors.shade(_outfit, .06));
    // ستاره‌ی زرد
    _star(c, const Offset(100, 172), 17);
  }

  void _star(Canvas c, Offset center, double r) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * .48;
      final pt = center + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    p.close();
    _blob(c, p, PColors.yellow);
  }

  void _arms(Canvas c) {
    const lShoulder = Offset(64, 156);
    const rShoulder = Offset(136, 156);
    late Offset lHand, rHand;
    final w = math.sin(wave * math.pi * 2);
    switch (pose) {
      case PopoPose.welcome:
        lHand = const Offset(52, 196);
        rHand = Offset(180 + w * 6, 84 - w.abs() * 4);
      case PopoPose.happy:
        lHand = Offset(18 - w * 3, 88);
        rHand = Offset(182 + w * 3, 88);
      case PopoPose.surprised:
        lHand = const Offset(32, 150);
        rHand = const Offset(168, 150);
      case PopoPose.thinking:
        lHand = const Offset(52, 196);
        rHand = const Offset(112, 138);
      case PopoPose.pointing:
        lHand = const Offset(52, 196);
        rHand = Offset(184 + w * 2, 146);
      case PopoPose.curious:
        lHand = const Offset(50, 194);
        rHand = const Offset(150, 196);
      case PopoPose.sleepy:
        lHand = const Offset(58, 200);
        rHand = const Offset(118, 138);
      case PopoPose.idle:
        lHand = const Offset(52, 198);
        rHand = const Offset(148, 198);
    }
    final flip = pose == PopoPose.pointing && !pointRight;
    if (flip) {
      // دست اشاره به سمت چپ: جای دو دست عوض می‌شود.
      final tmp = lHand;
      lHand = Offset(200 - rHand.dx, rHand.dy);
      rHand = Offset(200 - tmp.dx, tmp.dy);
    }
    for (final (shoulder, hand) in [(lShoulder, lHand), (rShoulder, rHand)]) {
      _capsule(c, shoulder, hand, 22, _outfit);
      _oval(c, Rect.fromCircle(center: hand, radius: 12), _fur);
    }
    _frontPaw = (pose == PopoPose.thinking || pose == PopoPose.sleepy) ? rHand : null;
    if (pose == PopoPose.pointing) {
      final hand = flip ? lHand : rHand;
      final dir = flip ? -1.0 : 1.0;
      _capsule(c, hand, hand + Offset(14 * dir, -2), 7, _fur);
    }
  }

  void _head(Canvas c) {
    // گوش‌ها
    for (final x in [56.0, 144.0]) {
      _oval(c, Rect.fromCircle(center: Offset(x, 46), radius: 21), _fur);
      c.drawOval(Rect.fromCircle(center: Offset(x, 47), radius: 11), Paint()..color = _muzzle);
    }
    // بند هدفون پشت سر
    final band = Paint()
      ..color = _phones
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round;
    c.drawArc(Rect.fromCenter(center: const Offset(100, 96), width: 142, height: 136), math.pi * 1.06, math.pi * .88, false, band);
    c.drawArc(
      Rect.fromCenter(center: const Offset(100, 96), width: 142, height: 136),
      math.pi * 1.2,
      math.pi * .25,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // سر
    final head = Path()..addOval(Rect.fromCenter(center: const Offset(100, 98), width: 132, height: 120));
    _blob(c, head, _fur);
    // رگه‌ی پیشانی
    final tuft = Path()
      ..moveTo(92, 42)
      ..quadraticBezierTo(100, 30, 104, 42)
      ..quadraticBezierTo(110, 34, 112, 44);
    c.drawPath(tuft, _stroke(_fur, 3));
    // هدفون‌ها
    for (final x in [36.0, 164.0]) {
      final cup = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 104), width: 30, height: 50), const Radius.circular(14));
      c.drawRRect(cup, _fill(_phones, cup.outerRect));
      c.drawRRect(cup, _stroke(_phones));
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x + (x < 100 ? 8 : -8), 104), width: 10, height: 38),
          const Radius.circular(5),
        ),
        Paint()..color = PColors.shade(_phones, .12),
      );
      c.drawCircle(Offset(x + (x < 100 ? -4 : 4), 92), 4, Paint()..color = Colors.white.withValues(alpha: .5));
    }
    // پوزه
    c.drawOval(Rect.fromCenter(center: const Offset(100, 124), width: 62, height: 44), Paint()..color = _muzzle);
    // گونه‌ها
    final cheek = Paint()..color = PColors.pink.withValues(alpha: .5);
    c.drawOval(Rect.fromCenter(center: const Offset(62, 118), width: 20, height: 12), cheek);
    c.drawOval(Rect.fromCenter(center: const Offset(138, 118), width: 20, height: 12), cheek);
    _eyes(c);
    _brows(c);
    // بینی
    c.drawOval(Rect.fromCenter(center: const Offset(100, 112), width: 18, height: 12), Paint()..color = _ink);
    c.drawOval(Rect.fromCenter(center: const Offset(96, 109), width: 6, height: 3.5), Paint()..color = Colors.white.withValues(alpha: .7));
    _mouth(c);
    // براقی بالای سر
    c.drawOval(Rect.fromCenter(center: const Offset(70, 62), width: 30, height: 14), Paint()..color = Colors.white.withValues(alpha: .25));
  }

  void _eyes(Canvas c) {
    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [76.0, 124.0]) {
      final center = Offset(x, 90);
      if (pose == PopoPose.happy) {
        // چشم‌های خندان (کمان)
        c.drawArc(Rect.fromCenter(center: center + const Offset(0, 4), width: 22, height: 18), math.pi * 1.1, math.pi * .8, false, line);
        continue;
      }
      if (pose == PopoPose.sleepy) {
        c.drawArc(Rect.fromCenter(center: center, width: 22, height: 12), math.pi * .1, math.pi * .8, false, line);
        continue;
      }
      final big = pose == PopoPose.surprised ? 1.18 : 1.0;
      final open = (1 - blink).clamp(.08, 1.0);
      final w = 24.0 * big, h = 28.0 * big * open;
      c.drawOval(Rect.fromCenter(center: center, width: w, height: h), ink);
      if (open > .3) {
        final l = pose == PopoPose.thinking ? const Offset(.4, -.8) : look;
        final hl = center + Offset(-4 + l.dx * 3, -6 * open + l.dy * 3);
        c.drawCircle(hl, 5 * big, Paint()..color = Colors.white);
        c.drawCircle(center + Offset(5 + l.dx * 2, 6 * open + l.dy * 2), 2.4 * big, Paint()..color = Colors.white.withValues(alpha: .8));
      }
    }
  }

  void _brows(Canvas c) {
    final brow = Paint()
      ..color = PColors.shade(_furDark, .1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    switch (pose) {
      case PopoPose.surprised:
        c.drawArc(Rect.fromCenter(center: const Offset(76, 64), width: 22, height: 10), math.pi * 1.15, math.pi * .7, false, brow);
        c.drawArc(Rect.fromCenter(center: const Offset(124, 64), width: 22, height: 10), math.pi * 1.15, math.pi * .7, false, brow);
      case PopoPose.thinking:
        c.drawLine(const Offset(66, 70), const Offset(84, 68), brow);
        c.drawLine(const Offset(116, 66), const Offset(134, 70), brow);
      case PopoPose.curious:
        c.drawArc(Rect.fromCenter(center: const Offset(124, 68), width: 22, height: 10), math.pi * 1.15, math.pi * .7, false, brow);
      default:
        break;
    }
  }

  void _mouth(Canvas c) {
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    switch (pose) {
      case PopoPose.happy:
      case PopoPose.welcome:
        final open = Path()
          ..moveTo(86, 124)
          ..quadraticBezierTo(100, 146, 114, 124)
          ..close();
        c.drawPath(open, Paint()..color = const Color(0xFF8E2F3C));
        c.drawOval(Rect.fromCenter(center: const Offset(100, 136), width: 14, height: 7), Paint()..color = const Color(0xFFFF7A8A));
        c.drawPath(open, line..strokeWidth = 3);
      case PopoPose.surprised:
        c.drawOval(Rect.fromCenter(center: const Offset(100, 132), width: 14, height: 18), Paint()..color = const Color(0xFF8E2F3C));
      case PopoPose.thinking:
        c.drawLine(const Offset(94, 130), const Offset(108, 128), line);
      case PopoPose.sleepy:
        c.drawOval(Rect.fromCenter(center: const Offset(100, 130), width: 8, height: 6), Paint()..color = const Color(0xFF8E2F3C));
      default:
        final p = Path()
          ..moveTo(90, 124)
          ..quadraticBezierTo(100, 134, 110, 124);
        c.drawPath(p, line);
        c.drawLine(const Offset(100, 117), const Offset(100, 125), line..strokeWidth = 3);
    }
  }

  void _zzz(Canvas c) {
    final tp = TextPainter(
      text: TextSpan(
        text: 'z Z',
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 26 + breath * 4,
          fontWeight: FontWeight.w900,
          color: PColors.purple.withValues(alpha: .8),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(150, 18 - breath * 6));
  }

  void _thought(Canvas c) {
    final p = Paint()..color = Colors.white;
    final o = _stroke(PColors.line, 2.5);
    for (final (pt, r) in [(const Offset(156, 44), 5.0), (const Offset(168, 28), 8.0)]) {
      c.drawCircle(pt, r, p);
      c.drawCircle(pt, r, o);
    }
    final bubble = Rect.fromCenter(center: const Offset(180, 4), width: 34, height: 26);
    c.drawOval(bubble, p);
    c.drawOval(bubble, o);
    final tp = TextPainter(
      text: const TextSpan(
        text: '?',
        style: TextStyle(fontFamily: 'Vazirmatn', fontSize: 20, fontWeight: FontWeight.w900, color: PColors.blue),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, bubble.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _sparkles(Canvas c) {
    for (final (pt, r) in [(const Offset(22, 70), 9.0), (const Offset(182, 60), 11.0), (const Offset(170, 10), 7.0)]) {
      final scale = .8 + .2 * math.sin((wave + pt.dx / 200) * math.pi * 2);
      _star(c, pt, r * scale);
    }
  }

  @override
  bool shouldRepaint(PopoPainter old) =>
      old.pose != pose ||
      old.blink != blink ||
      old.breath != breath ||
      old.wave != wave ||
      old.look != look ||
      old.pointRight != pointRight;
}
