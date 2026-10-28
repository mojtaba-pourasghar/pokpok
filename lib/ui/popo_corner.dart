import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme/theme.dart';
import '../features/mascot/popo_mascot.dart';
import 'clay.dart';

/// پوپوی بزرگ در گوشه‌ی صحنه با حباب حرف (دم‌دار) بالای سرش. متن همان جمله‌ای است که می‌گوید،
/// یا [text] اگر داده شود. ژست با [pose] عوض می‌شود (شاد، فکر، اشاره).
class PopoCorner extends ConsumerWidget {
  const PopoCorner({super.key, required this.pose, this.text, this.size = 118});

  final PopoPose pose;
  final String? text;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    return ValueListenableBuilder(
      valueListenable: audio.caption,
      builder: (context, line, _) {
        final t = text ?? line?.text;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (c, a) => ScaleTransition(
                scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                child: c,
              ),
              child: PopoMascot(key: ValueKey(pose), pose: pose, size: size),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: size * .45),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (c, a) => ScaleTransition(
                    alignment: Directionality.of(context) == TextDirection.rtl ? Alignment.bottomRight : Alignment.bottomLeft,
                    scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
                    child: FadeTransition(opacity: a, child: c),
                  ),
                  child: t == null ? const SizedBox(key: ValueKey('none'), height: 10) : _Bubble(key: ValueKey(t), text: t),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _BubblePainter(Directionality.of(context)),
    child: Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(22, 12, 16, 14),
      child: Text(
        text,
        style: PText.bodyStrong.copyWith(fontSize: 17, color: G.ink, height: 1.45),
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}

/// حباب سفید با دمی که رو به پوپو (سمت شروع خط) است.
class _BubblePainter extends CustomPainter {
  _BubblePainter(this.dir);

  final TextDirection dir;

  @override
  void paint(Canvas canvas, Size s) {
    final rtl = dir == TextDirection.rtl;
    const tail = 12.0;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(rtl ? 0 : tail, 0, s.width - tail, s.height), const Radius.circular(22));
    final x = rtl ? s.width - tail : tail;
    final tip = Offset(rtl ? s.width : 0, s.height - 6);
    final path = Path()
      ..addRRect(body)
      ..moveTo(x, s.height - 30)
      ..quadraticBezierTo(x + (rtl ? 6 : -6), s.height - 10, tip.dx, tip.dy)
      ..quadraticBezierTo(x + (rtl ? -2 : 2), s.height - 6, x + (rtl ? -14 : 14), s.height - 4)
      ..close();
    canvas.drawShadow(path, const Color(0x664B3C9E), 6, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.dir != dir;
}
