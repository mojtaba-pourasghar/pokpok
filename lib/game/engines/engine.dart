import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/audio/popo_audio.dart';
import '../../data/models/models.dart';
import '../game_data.dart';

/// رابط بین یک گام بازی و صفحه‌ی بخش: درست، اشتباه، تمام، و پله‌های راهنما.
///
/// راهنما سه پله دارد که با بی‌کاری بالا می‌رود (یا با دکمه‌ی لامپ):
///   ۱. جای درست می‌درخشد (رایگان)  ۲. پوپو با صدا کمک می‌کند  ۳. دست راهنما حرکت را نشان می‌دهد.
/// پله‌ی ۲ و ۳ «راهنما» حساب می‌شوند. سه اشتباه پشت سر هم، پله‌ی ۳ را می‌آورد.
class EngineHost {
  EngineHost({
    required this.onDone,
    required this.onMistake,
    required this.onPoints,
    required this.onHint,
    required this.age,
    required this.data,
    this.backpack = const {},
    this.onRight,
  });

  /// هر کار درست (برای واکنش پوپو).
  final VoidCallback? onRight;

  final VoidCallback onDone;
  final VoidCallback onMistake;
  final void Function(int) onPoints;

  /// پله‌ی راهنمایی که برای اولین بار رسید (۲ یا ۳) — صفحه‌ی بخش آن را می‌شمارد و پوپو حرف می‌زند.
  final void Function(int level) onHint;
  final AgeBand age;
  final GameData data;

  /// آنچه کودک تا حالا ساخته (برای گام‌های «استفاده از کوله‌پشتی»).
  final Set<String> backpack;

  final hint = ValueNotifier<int>(0);
  int _mistakesInRow = 0;
  int mistakes = 0;
  Timer? _idle;
  bool _finished = false;

  Duration get _wait => age == AgeBand.toddler ? const Duration(seconds: 6) : const Duration(seconds: 9);

  /// بزرگ‌تر برای کوچک‌ترها: تعداد چیزها بر اساس سن.
  int scaled(int n) => switch (age) {
    AgeBand.toddler => math.max(1, (n * .6).round()),
    AgeBand.preschool => n,
    AgeBand.early => n,
  };

  void start() => touch();

  /// هر لمس کودک زمان‌سنج بی‌کاری را از نو می‌کند.
  void touch() {
    _idle?.cancel();
    if (_finished) return;
    _idle = Timer(_wait, () => raiseHint());
  }

  void raiseHint() {
    if (_finished || hint.value >= 3) return;
    hint.value++;
    if (hint.value >= 2) onHint(hint.value);
    touch();
  }

  void right() {
    _mistakesInRow = 0;
    onRight?.call();
    touch();
  }

  void wrong() {
    mistakes++;
    _mistakesInRow++;
    onMistake();
    touch();
    if (_mistakesInRow >= 3) {
      while (hint.value < 3) {
        raiseHint();
      }
    }
  }

  void points(int n) => onPoints(n);

  void done() {
    if (_finished) return;
    _finished = true;
    _idle?.cancel();
    onDone();
  }

  void dispose() {
    _idle?.cancel();
    hint.dispose();
  }
}

/// پایه‌ی همه‌ی موتورها.
abstract class EngineView extends ConsumerStatefulWidget {
  const EngineView({super.key, required this.step, required this.host});

  final StepDef step;
  final EngineHost host;
}

mixin EngineSounds<T extends EngineView> on ConsumerState<T> {
  void sfx(String? path) {
    if (path != null && path.isNotEmpty) ref.read(audioProvider).play(path);
  }

  void ui(UiSound s) => ref.read(audioProvider).ui(s);

  void good([String? sound]) {
    sound == null ? ui(UiSound.pop) : sfx(sound);
    widget.host.right();
  }

  void bad() {
    ui(UiSound.softNo);
    widget.host.wrong();
  }
}

/// چیزی که در پله‌ی ۱ راهنما می‌درخشد.
class HintGlow extends StatefulWidget {
  const HintGlow({super.key, required this.on, required this.child, this.color = const Color(0xFFFFE066)});

  final bool on;
  final Widget child;
  final Color color;

  @override
  State<HintGlow> createState() => _HintGlowState();
}

class _HintGlowState extends State<HintGlow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.on) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .35 + .45 * _c.value),
              blurRadius: 18 + 18 * _c.value,
              spreadRadius: 4 + 8 * _c.value,
            ),
          ],
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// دست راهنما که از [from] به [to] حرکت می‌کند (پله‌ی ۳)؛ اگر [to] نباشد روی [from] ضربه می‌زند.
class HintHand extends StatefulWidget {
  const HintHand({super.key, required this.from, this.to});

  final Offset from;
  final Offset? to;

  @override
  State<HintHand> createState() => _HintHandState();
}

class _HintHandState extends State<HintHand> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_c.value);
        final to = widget.to;
        final pos = to == null ? widget.from + Offset(0, math.sin(_c.value * math.pi * 2) * 10) : Offset.lerp(widget.from, to, t)!;
        return Stack(
          children: [
            Positioned(
              left: pos.dx - 8,
              top: pos.dy - 4,
              child: Opacity(
                opacity: to == null ? 1 : (1 - (t - .9).clamp(0, .1) * 10),
                child: const Text('👆', style: TextStyle(fontSize: 52)),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// لرزش کوتاه برای پاسخ اشتباه.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  /// هر بار که عوض شود یک بار می‌لرزد.
  final int trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) =>
        Transform.translate(offset: Offset(math.sin(_c.value * math.pi * 6) * 10 * (1 - _c.value), 0), child: child),
    child: widget.child,
  );
}

/// تکان کوچک برای پاسخ درست/لمس.
class Bounce extends StatefulWidget {
  const Bounce({super.key, required this.trigger, required this.child, this.scale = .18});

  final int trigger;
  final Widget child;
  final double scale;

  @override
  State<Bounce> createState() => _BounceState();
}

class _BounceState extends State<Bounce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(Bounce old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, child) => Transform.scale(scale: 1 + math.sin(_c.value * math.pi) * widget.scale, child: child),
    child: widget.child,
  );
}

/// شمارنده‌ی پیشرفت گام (مثلاً ۲ از ۴) به شکل نقطه‌ها.
class StepDots extends StatelessWidget {
  const StepDots({super.key, required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < total; i++)
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i < done ? 22 : 14,
          height: 14,
          decoration: BoxDecoration(
            color: i < done ? const Color(0xFF2FBF71) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE6E3F3), width: 2),
          ),
        ),
    ],
  );
}

/// ستاره‌ها و حباب‌های کوچک دور یک نقطه هنگام موفقیت.
class Sparkles extends StatefulWidget {
  const Sparkles({super.key, required this.trigger, this.color = const Color(0xFFFFC83D)});

  final int trigger;
  final Color color;

  @override
  State<Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<Sparkles> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didUpdateWidget(Sparkles old) {
    super.didUpdateWidget(old);
    if (old.trigger != widget.trigger) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (context, _) =>
          _c.isAnimating ? CustomPaint(painter: _SparklePainter(_c.value, widget.color), size: Size.infinite) : const SizedBox.shrink(),
    ),
  );
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t, this.color);

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.shortestSide * .2 + s.shortestSide * .35 * Curves.easeOut.transform(t);
    final p = Paint()..color = color.withValues(alpha: 1 - t);
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2;
      final o = c + Offset(math.cos(a), math.sin(a)) * r;
      final path = Path();
      for (var k = 0; k < 10; k++) {
        final rr = k.isEven ? 9.0 : 4.0;
        final aa = k / 10 * math.pi * 2 - math.pi / 2;
        final pt = o + Offset(math.cos(aa), math.sin(aa)) * rr;
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path..close(), p);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
