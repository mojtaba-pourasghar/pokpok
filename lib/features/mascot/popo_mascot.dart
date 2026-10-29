import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'popo_painter.dart';

export 'popo_painter.dart' show PopoPose;

/// پوپوی زنده: نفس آرام، پلک زدن گاه‌به‌گاه، تکان دادن دست در حالت خوشامد.
///
/// حرکت‌ها آرام و کم‌دامنه‌اند تا حواس کودک را از بازی پرت نکنند. با [reducedMotion]
/// (تنظیم «حرکت کمتر» یا تنظیم دسترس‌پذیری سیستم) پوپو ثابت می‌ماند.
class PopoMascot extends StatefulWidget {
  const PopoMascot({
    super.key,
    this.pose = PopoPose.idle,
    this.size = 160,
    this.look = Offset.zero,
    this.pointRight = true,
    this.reducedMotion = false,
    this.semanticLabel = 'پوپو، روباه کوچولو',
  });

  final PopoPose pose;

  /// ارتفاع؛ پهنا به نسبت ۲۰۰:۲۶۰.
  final double size;
  final Offset look;
  final bool pointRight;
  final bool reducedMotion;
  final String semanticLabel;

  @override
  State<PopoMascot> createState() => _PopoMascotState();
}

class _PopoMascotState extends State<PopoMascot> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _blink = AnimationController(vsync: this, duration: const Duration(milliseconds: 170));
  Timer? _blinkTimer;
  Timer? _waveStop;
  final _rand = math.Random();

  bool get _still => widget.reducedMotion || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(PopoMascot old) {
    super.didUpdateWidget(old);
    if (old.pose != widget.pose || old.reducedMotion != widget.reducedMotion) _sync();
  }

  void _sync() {
    _blinkTimer?.cancel();
    _waveStop?.cancel();
    if (_still) {
      _breath.stop();
      _wave.stop();
      _breath.value = 0;
      _wave.value = 0;
      return;
    }
    if (!_breath.isAnimating) _breath.repeat();
    final waving = widget.pose == PopoPose.welcome || widget.pose == PopoPose.happy || widget.pose == PopoPose.pointing;
    if (waving) {
      // چند بار تکان، بعد مکث؛ دست بی‌وقفه تکان نمی‌خورد.
      _wave.repeat();
      _waveStop = Timer(const Duration(milliseconds: 2700), () {
        if (mounted && _wave.isAnimating) _wave.animateTo(1).then((_) => _wave.value = 0);
      });
    } else {
      _wave.stop();
      _wave.value = 0;
    }
    if (widget.pose != PopoPose.sleepy && widget.pose != PopoPose.happy) _scheduleBlink();
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(Duration(milliseconds: 2200 + _rand.nextInt(2800)), () async {
      if (!mounted) return;
      await _blink.forward();
      if (!mounted) return;
      await _blink.reverse();
      if (mounted && !_still) _scheduleBlink();
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _waveStop?.cancel();
    _breath.dispose();
    _wave.dispose();
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.size;
    final w = h * PopoPainter.designSize.width / PopoPainter.designSize.height;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: SizedBox(
        width: w,
        height: h,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: Listenable.merge([_breath, _wave, _blink]),
            builder: (context, _) => CustomPaint(
              painter: PopoPainter(
                pose: widget.pose,
                breath: _breath.value,
                wave: _wave.value,
                blink: _blink.value,
                look: widget.look,
                pointRight: widget.pointRight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
