import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import 'popo_painter.dart';

/// پس‌زمینه‌ی صفحه‌ی بارگذاری؛ همان شیبِ اسپلشِ اندروید (res/drawable/launch_background.xml)،
/// تا جابه‌جایی از اسپلشِ سیستم به برنامه دیده نشود.
const popoLoadingGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFE07A), PColors.orange],
);

/// اندازه‌ی سرِ پوپو روی صفحه‌ی بارگذاری (dp). تصویرِ اسپلشِ اندروید (launch_fox.png) هم با همین
/// اندازه ساخته می‌شود: test/tools/make_splash_test.dart.
const popoLoaderHeadSize = 160.0;

/// فقط سرِ پوپو (گوش‌ها تا یقه) در یک مربع. بُرشِ همان آیکونِ برنامه است.
class PopoHeadPainter extends CustomPainter {
  PopoHeadPainter({this.pose = PopoPose.happy, this.wave = 0, this.breath = 0, this.blink = 0});

  final PopoPose pose;
  final double wave;
  final double breath;
  final double blink;

  // ناحیه‌ی سر روی بومِ ۲۰۰×۲۶۰ پوپو، با کمی جا برای گوش‌ها و ستاره‌ها.
  static const region = Rect.fromLTWH(-20, -20, 240, 182);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / region.width;
    canvas.save();
    canvas.translate(0, (size.height - region.height * k) / 2);
    canvas.scale(k);
    canvas.translate(-region.left, -region.top);
    canvas.clipRect(region);
    PopoPainter(pose: pose, wave: wave, breath: breath, blink: blink).paint(canvas, PopoPainter.designSize);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PopoHeadPainter old) => old.wave != wave || old.breath != breath || old.blink != blink || old.pose != pose;
}

/// بارگذاری با خودِ پوپو: سرش بالا و پایین می‌پرد و سه نقطه زیرش می‌جهند.
/// سر دقیقاً وسطِ صفحه است، همان‌جا که اسپلشِ اندروید آن را کشیده بود.
class PopoLoader extends StatefulWidget {
  const PopoLoader({super.key, this.reducedMotion = false, this.label = 'پوپو دارد می‌آید…'});

  final bool reducedMotion;
  final String label;

  @override
  State<PopoLoader> createState() => _PopoLoaderState();
}

class _PopoLoaderState extends State<PopoLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  bool get _still => widget.reducedMotion || MediaQuery.maybeDisableAnimationsOf(context) == true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_still) {
      _t.stop();
      _t.value = 0;
    } else if (!_t.isAnimating) {
      _t.repeat();
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      liveRegion: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: popoLoadingGradient),
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final t = _t.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: SizedBox.square(
                    dimension: popoLoaderHeadSize,
                    child: CustomPaint(
                      painter: PopoHeadPainter(wave: t, breath: t),
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: popoLoaderHeadSize + 56),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(mainAxisSize: MainAxisSize.min, children: [for (var i = 0; i < 3; i++) _dot(t, i)]),
                        const SizedBox(height: 14),
                        Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            shadows: [Shadow(color: Color(0x55B4500A), offset: Offset(0, 2), blurRadius: 4)],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(double t, int i) {
    final phase = (t - i * .16) % 1.0;
    final lift = phase < .5 ? math.sin(phase * 2 * math.pi) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Transform.translate(
        offset: Offset(0, -12 * lift.clamp(0.0, 1.0)),
        child: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: PColors.furDark.withValues(alpha: .35), offset: const Offset(0, 3), blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}
