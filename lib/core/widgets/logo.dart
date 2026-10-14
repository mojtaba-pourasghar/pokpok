import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';

/// نشان‌واژه‌ی «پوپو»: حروف گرد با رنگ‌های برند و دورگیری سفید. (نشان اصلی و مستقل؛ هیچ
/// شباهتی به نشان برندهای دیگر ندارد.)
class PopoLogo extends StatelessWidget {
  const PopoLogo({super.key, this.size = 72, this.tagline = true});

  final double size;
  final bool tagline;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontFamily: PText.family, fontSize: size, fontWeight: FontWeight.w900, height: 1.1);
    return Semantics(
      label: 'پوپو — ببین، لمس کن، کشف کن!',
      header: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Text(
                'پوپو',
                style: style.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = size * .2
                    ..strokeJoin = StrokeJoin.round
                    ..color = Colors.white,
                ),
              ),
              Text(
                'پوپو',
                style: style
                    .copyWith(
                      shadows: [Shadow(color: PColors.blue.withValues(alpha: .35), offset: Offset(0, size * .06))],
                    )
                    .copyWith(
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [PColors.orange, PColors.yellow, PColors.green, PColors.turquoise, PColors.purple],
                        ).createShader(Rect.fromLTWH(0, 0, size * 2.2, size)),
                    ),
              ),
            ],
          ),
          if (tagline)
            Container(
              margin: EdgeInsets.only(top: size * .05),
              padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: PSpace.xxs),
              decoration: BoxDecoration(
                color: PColors.blue,
                borderRadius: BorderRadius.circular(PRadius.pill),
                boxShadow: PShadow.soft(PColors.blue),
              ),
              child: Text(
                'ببین، لمس کن، کشف کن!',
                style: PText.bodyStrong.copyWith(color: Colors.white, fontSize: (size * .24).clamp(14, 22)),
              ),
            ),
        ],
      ),
    );
  }
}
