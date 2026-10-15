import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';

/// هشت حالت پوپو. همه از یک مدل (همین نقاش) کشیده می‌شوند تا شخصیت در همه‌ی صفحه‌ها یکی بماند.
enum PopoPose { welcome, curious, thinking, happy, surprised, sleepy, pointing, idle }

/// پوپو: یک روباه کوچولوی دختر — خز نارنجی با صورت و نوک دم سفید، گوش‌های نوک‌تیز با
/// نوک قهوه‌ای، پاپیون صورتی بزرگ، مژه‌های بلند، پیراهن بنفش با یقه‌ی سفید و گل زرد،
/// جوراب سفید و کفش صورتی، و دم پف‌دار که با نفس تکان می‌خورد.
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
  static const _white = PColors.muzzle;
  static const _dress = PColors.outfit;
  static const _bow = PColors.bow;
  static const _paw = Color(0xFF6B3A24);
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
    _tail(canvas, bob);
    _legs(canvas);
    canvas.save();
    canvas.translate(0, bob * .4);
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
      final at = pose == PopoPose.thinking ? const Offset(116, 150) : const Offset(108, 140);
      _capsule(canvas, Offset(134, 162 + bob * .4), at, 18, _fur);
      _oval(canvas, Rect.fromCircle(center: const Offset(134, 162), radius: 13), _dress);
      _oval(canvas, Rect.fromCircle(center: at, radius: 11), _paw);
    }
    canvas.restore();

    if (pose == PopoPose.sleepy) _zzz(canvas);
    if (pose == PopoPose.thinking) _thought(canvas);
    if (pose == PopoPose.happy) _sparkles(canvas);
    canvas.restore();
  }

  /// دم پف‌دار روباه با نوک سفید؛ با نفس آرام تاب می‌خورد.
  void _tail(Canvas c, double bob) {
    c.save();
    c.translate(132, 206);
    c.rotate(-.15 + bob * .03 + (pose == PopoPose.happy ? math.sin(wave * math.pi * 2) * .12 : 0));
    final tail = Path()
      ..moveTo(0, 6)
      ..cubicTo(26, 4, 52, -16, 58, -52)
      ..cubicTo(62, -78, 46, -96, 34, -92)
      ..cubicTo(40, -70, 30, -40, 2, -18)
      ..close();
    _blob(c, tail, _fur);
    final tip = Path()
      ..moveTo(44, -60)
      ..cubicTo(58, -64, 60, -84, 48, -94)
      ..cubicTo(40, -96, 33, -92, 34, -92)
      ..cubicTo(38, -80, 40, -70, 44, -60)
      ..close();
    c.drawPath(tip, Paint()..color = _white);
    c.drawPath(tail, _stroke(_fur, 2.5));
    c.restore();
  }

  void _legs(Canvas c) {
    for (final x in [82.0, 118.0]) {
      final leg = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 226), width: 20, height: 30), const Radius.circular(10));
      c.drawRRect(leg, _fill(_fur, leg.outerRect));
      // جوراب سفید
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 234), width: 20, height: 10), const Radius.circular(4)),
        Paint()..color = Colors.white,
      );
      // کفش صورتی با بند
      final dx = x < 100 ? -3.0 : 3.0;
      final shoe = Path()
        ..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + dx, 244), width: 34, height: 16), const Radius.circular(8)));
      _blob(c, shoe, _bow);
      c.drawLine(Offset(x - 9, 238), Offset(x + 9, 238), _stroke(_bow, 3));
      c.drawCircle(Offset(x + dx - 6, 241), 3, Paint()..color = Colors.white.withValues(alpha: .7));
    }
  }

  void _body(Canvas c) {
    // پیراهن کلوش با لبه‌ی موج‌دار
    final dress = Path()..moveTo(76, 146);
    dress
      ..quadraticBezierTo(100, 138, 124, 146)
      ..quadraticBezierTo(140, 182, 152, 214);
    for (var i = 0; i < 5; i++) {
      final x0 = 152 - i * 20.8;
      dress.quadraticBezierTo(x0 - 10.4, 226, x0 - 20.8, 214);
    }
    dress
      ..quadraticBezierTo(60, 182, 76, 146)
      ..close();
    _blob(c, dress, _dress);
    // نوار کمر
    c.drawLine(const Offset(68, 186), const Offset(132, 186), _stroke(_dress, 5));
    // یقه‌ی سفید گرد
    for (final dir in [-1.0, 1.0]) {
      final collar = Path()
        ..moveTo(100, 148)
        ..quadraticBezierTo(100 + dir * 22, 142, 100 + dir * 24, 154)
        ..quadraticBezierTo(100 + dir * 14, 166, 100, 154)
        ..close();
      c.drawPath(collar, Paint()..color = Colors.white);
      c.drawPath(collar, _stroke(PColors.line, 2));
    }
    // گل زرد روی پیراهن
    _flower(c, const Offset(118, 202), 9);
    // نقطه‌های پیراهن
    final dot = Paint()..color = Colors.white.withValues(alpha: .55);
    for (final o in const [Offset(84, 170), Offset(110, 176), Offset(76, 204), Offset(96, 196), Offset(136, 206)]) {
      c.drawCircle(o, 2.6, dot);
    }
  }

  void _flower(Canvas c, Offset o, double r) {
    for (var i = 0; i < 5; i++) {
      final a = i * math.pi * 2 / 5 - math.pi / 2;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * .7, r * .55, Paint()..color = PColors.yellow);
    }
    c.drawCircle(o, r * .4, Paint()..color = PColors.orange);
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
    const lShoulder = Offset(70, 160);
    const rShoulder = Offset(130, 160);
    late Offset lHand, rHand;
    final w = math.sin(wave * math.pi * 2);
    switch (pose) {
      case PopoPose.welcome:
        lHand = const Offset(56, 196);
        rHand = Offset(176 + w * 6, 90 - w.abs() * 4);
      case PopoPose.happy:
        lHand = Offset(22 - w * 3, 96);
        rHand = Offset(178 + w * 3, 96);
      case PopoPose.surprised:
        lHand = const Offset(34, 152);
        rHand = const Offset(166, 152);
      case PopoPose.thinking:
        lHand = const Offset(56, 196);
        rHand = const Offset(116, 150);
      case PopoPose.pointing:
        lHand = const Offset(56, 196);
        rHand = Offset(180 + w * 2, 150);
      case PopoPose.curious:
        lHand = const Offset(54, 194);
        rHand = const Offset(146, 196);
      case PopoPose.sleepy:
        lHand = const Offset(60, 200);
        rHand = const Offset(108, 140);
      case PopoPose.idle:
        lHand = const Offset(56, 198);
        rHand = const Offset(144, 198);
    }
    final flip = pose == PopoPose.pointing && !pointRight;
    if (flip) {
      // دست اشاره به سمت چپ: جای دو دست عوض می‌شود.
      final tmp = lHand;
      lHand = Offset(200 - rHand.dx, rHand.dy);
      rHand = Offset(200 - tmp.dx, tmp.dy);
    }
    _frontPaw = (pose == PopoPose.thinking || pose == PopoPose.sleepy) ? rHand : null;
    for (final (shoulder, hand) in [(lShoulder, lHand), (rShoulder, rHand)]) {
      if (_frontPaw != null && identical(hand, rHand)) continue;
      _capsule(c, shoulder, hand, 18, _fur);
      // آستین پفی
      _oval(c, Rect.fromCircle(center: shoulder, radius: 13), _dress);
      _oval(c, Rect.fromCircle(center: hand, radius: 11), _paw);
    }
    if (pose == PopoPose.pointing) {
      final hand = flip ? lHand : rHand;
      final dir = flip ? -1.0 : 1.0;
      _capsule(c, hand, hand + Offset(13 * dir, -2), 7, _paw);
    }
  }

  void _head(Canvas c) {
    // گوش‌های نوک‌تیز با نوک قهوه‌ای
    for (final dir in [-1.0, 1.0]) {
      Offset p(double x, double y) => Offset(100 + dir * x, y);
      final ear = Path()
        ..moveTo(p(26, 62).dx, p(26, 62).dy)
        ..quadraticBezierTo(p(44, 14).dx, p(44, 14).dy, p(58, 6).dx, p(58, 6).dy)
        ..quadraticBezierTo(p(70, 30).dx, p(70, 30).dy, p(64, 70).dx, p(64, 70).dy)
        ..close();
      _blob(c, ear, _fur);
      final inner = Path()
        ..moveTo(p(36, 58).dx, p(36, 58).dy)
        ..quadraticBezierTo(p(48, 30).dx, p(48, 30).dy, p(56, 24).dx, p(56, 24).dy)
        ..quadraticBezierTo(p(62, 40).dx, p(62, 40).dy, p(58, 62).dx, p(58, 62).dy)
        ..close();
      c.drawPath(inner, Paint()..color = PColors.tint(_bow, .12));
      final tip = Path()
        ..moveTo(p(50, 16).dx, p(50, 16).dy)
        ..quadraticBezierTo(p(54, 8).dx, p(54, 8).dy, p(58, 6).dx, p(58, 6).dy)
        ..quadraticBezierTo(p(64, 16).dx, p(64, 16).dy, p(65, 26).dx, p(65, 26).dy)
        ..close();
      c.drawPath(tip, Paint()..color = _paw);
    }
    // سر با کرک گونه‌ها
    final head = Path()
      ..moveTo(100, 40)
      ..cubicTo(140, 40, 166, 66, 164, 102)
      ..lineTo(176, 116)
      ..lineTo(160, 122)
      ..cubicTo(150, 148, 128, 158, 100, 158)
      ..cubicTo(72, 158, 50, 148, 40, 122)
      ..lineTo(24, 116)
      ..lineTo(36, 102)
      ..cubicTo(34, 66, 60, 40, 100, 40)
      ..close();
    _blob(c, head, _fur);
    // ماسک سفید روباه: گونه‌ها و پوزه
    final mask = Path()
      ..moveTo(38, 112)
      ..quadraticBezierTo(62, 98, 86, 108)
      ..quadraticBezierTo(100, 116, 114, 108)
      ..quadraticBezierTo(138, 98, 162, 112)
      ..quadraticBezierTo(152, 154, 100, 156)
      ..quadraticBezierTo(48, 154, 38, 112)
      ..close();
    c.drawPath(mask, Paint()..color = _white);
    // پیشانی: رگه‌ی تیره‌تر بین چشم‌ها
    final stripe = Path()
      ..moveTo(92, 44)
      ..quadraticBezierTo(100, 70, 108, 44)
      ..close();
    c.drawPath(stripe, Paint()..color = PColors.shade(_fur, .06));
    // طره‌ی مو
    final curl = Path()
      ..moveTo(94, 42)
      ..quadraticBezierTo(98, 26, 110, 30)
      ..quadraticBezierTo(102, 34, 104, 44);
    c.drawPath(curl, Paint()..color = _fur);
    c.drawPath(curl, _stroke(_fur, 2.5));
    _bowTie(c);
    // گونه‌ها
    final cheek = Paint()..color = PColors.pink.withValues(alpha: .55);
    c.drawOval(Rect.fromCenter(center: const Offset(60, 122), width: 22, height: 13), cheek);
    c.drawOval(Rect.fromCenter(center: const Offset(140, 122), width: 22, height: 13), cheek);
    _eyes(c);
    _brows(c);
    // بینی کوچک
    final nose = Path()
      ..moveTo(92, 112)
      ..quadraticBezierTo(100, 108, 108, 112)
      ..quadraticBezierTo(104, 120, 100, 120)
      ..quadraticBezierTo(96, 120, 92, 112)
      ..close();
    c.drawPath(nose, Paint()..color = _ink);
    c.drawOval(Rect.fromCenter(center: const Offset(97, 112), width: 5, height: 3), Paint()..color = Colors.white.withValues(alpha: .7));
    _mouth(c);
    // براقی بالای سر
    c.drawOval(Rect.fromCenter(center: const Offset(74, 60), width: 26, height: 12), Paint()..color = Colors.white.withValues(alpha: .25));
  }

  /// پاپیون صورتی بزرگ کنار گوش راست.
  void _bowTie(Canvas c) {
    c.save();
    c.translate(140, 44);
    c.rotate(.35);
    final left = Path()
      ..moveTo(0, 0)
      ..cubicTo(-10, -18, -30, -16, -28, 0)
      ..cubicTo(-30, 16, -10, 18, 0, 0)
      ..close();
    final right = Path()
      ..moveTo(0, 0)
      ..cubicTo(10, -18, 30, -16, 28, 0)
      ..cubicTo(30, 16, 10, 18, 0, 0)
      ..close();
    _blob(c, left, _bow);
    _blob(c, right, _bow);
    for (final dir in [-1.0, 1.0]) {
      final ribbon = Path()
        ..moveTo(0, 2)
        ..lineTo(dir * 8, 22)
        ..lineTo(dir * 14, 18)
        ..close();
      _blob(c, ribbon, _bow);
    }
    _oval(c, Rect.fromCircle(center: Offset.zero, radius: 7), PColors.shade(_bow, .04));
    c.drawCircle(const Offset(-16, -5), 3.5, Paint()..color = Colors.white.withValues(alpha: .6));
    c.restore();
  }

  void _eyes(Canvas c) {
    final ink = Paint()..color = _ink;
    final line = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [76.0, 124.0]) {
      final center = Offset(x, 92);
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
      // مژه‌ها در گوشه‌ی بیرونی هر چشم
      final out = x < 100 ? -1.0 : 1.0;
      final lash = Paint()
        ..color = _ink
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 3; k++) {
        final a = -math.pi / 2 + out * (.55 + k * .32);
        final from = center + Offset(math.cos(a) * w * .46, math.sin(a) * h * .46);
        c.drawLine(from, from + Offset(math.cos(a), math.sin(a)) * 7, lash);
      }
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
