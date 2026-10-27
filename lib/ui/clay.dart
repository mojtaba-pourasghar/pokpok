import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../app/theme/theme.dart';
import '../core/audio/popo_audio.dart';
import '../features/mascot/popo_mascot.dart';
import '../game/game_state.dart';

/// رنگ‌های بازی، هم‌خانواده‌ی گوش‌یار: بنفش عمیق برای عنوان‌ها و دکمه‌های اصلی، نارنجی گرم،
/// آبی، سبز و صورتی شاد روی آسمان روشن.
abstract final class G {
  static const purple = Color(0xFF5B2BC4);
  static const purpleSoft = Color(0xFFEDE6FF);
  static const orange = Color(0xFFFF8A1F);
  static const yellow = Color(0xFFFFC83D);
  static const blue = Color(0xFF3B82F6);
  static const sky = Color(0xFFE8F3FF);
  static const green = Color(0xFF2FBF71);
  static const red = Color(0xFFF0524F);
  static const pink = Color(0xFFE9478F);
  static const teal = Color(0xFF14B8A6);
  static const ink = Color(0xFF2A2250);
  static const inkSoft = Color(0xFF5E5A7A);
  static const line = Color(0xFFE6E3F3);
  static const locked = Color(0xFFBDBACB);

  static Color shade(Color c, [double amount = .16]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  static Color tint(Color c, [double amount = .38]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  static Color hex(String h) => Color(int.parse('FF${h.replaceFirst('#', '')}', radix: 16));

  static List<BoxShadow> soft([Color tint = const Color(0xFF4B3C9E)]) => [
    BoxShadow(color: tint.withValues(alpha: .10), blurRadius: 18, offset: const Offset(0, 8)),
    BoxShadow(color: tint.withValues(alpha: .06), blurRadius: 4, offset: const Offset(0, 2)),
  ];
}

/// لمس‌پذیر سه‌بعدی: با فشار کمی پایین می‌رود و لبه‌ی تیره‌ی زیرش کوتاه می‌شود.
class Pressable extends ConsumerStatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.color = G.purple,
    this.radius = 999,
    this.depth = 6,
    this.semanticLabel,
    this.sound = UiSound.tap,
    this.padding = EdgeInsets.zero,
    this.gradient = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final double depth;
  final String? semanticLabel;
  final UiSound? sound;
  final EdgeInsets padding;
  final bool gradient;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = enabled ? widget.color : Color.lerp(widget.color, G.locked, .7)!;
    final edge = G.shade(base, .16);
    final depth = _down ? widget.depth * .3 : widget.depth;
    final r = BorderRadius.circular(widget.radius);
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapCancel: () => _set(false),
        onTapUp: enabled ? (_) => _set(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                if (widget.sound != null) ref.read(audioProvider).ui(widget.sound!);
                widget.onTap!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.only(top: widget.depth - depth),
          decoration: BoxDecoration(color: edge, borderRadius: r, boxShadow: _down ? null : G.soft(edge)),
          padding: EdgeInsets.only(bottom: depth),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: r,
              color: base,
              gradient: widget.gradient
                  ? LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [G.tint(base, .08), base])
                  : null,
            ),
            padding: widget.padding,
            child: widget.semanticLabel == null ? widget.child : ExcludeSemantics(child: widget.child),
          ),
        ),
      ),
    );
  }
}

class ClayButton extends StatelessWidget {
  const ClayButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = G.purple,
    this.big = false,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color color;
  final bool big;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final h = big ? 76.0 : 64.0;
    return Pressable(
      onTap: onTap,
      color: color,
      semanticLabel: label,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: h - 6,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, color: Colors.white, size: big ? 30 : 26), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                style: PText.button.copyWith(fontSize: big ? 23 : 20),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClayIconButton extends StatelessWidget {
  const ClayIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.iconColor = G.purple,
    this.size = 56,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Pressable(
      onTap: onTap,
      color: color,
      depth: 4,
      semanticLabel: label,
      gradient: false,
      child: SizedBox(
        width: size,
        height: size - 4,
        child: Icon(icon, color: iconColor, size: size * .5),
      ),
    ),
  );
}

class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.radius = 28,
    this.border,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final double radius;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border == null ? null : Border.all(color: border!, width: 3),
      boxShadow: G.soft(),
    ),
    child: child,
  );
}

class SectionPill extends StatelessWidget {
  const SectionPill(this.text, {super.key, this.color = G.purple});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
    child: Text(
      text,
      style: PText.label.copyWith(color: Colors.white, fontSize: 16),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// نشان کوچک سفید با آیکون و عدد (ستاره، سکه).
class CountChip extends StatelessWidget {
  const CountChip({super.key, required this.icon, required this.value, required this.color, this.label});

  final IconData icon;
  final int value;
  final Color color;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${label ?? ''} ${fa(value)}',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 10, 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 4),
          Text(fa(value), style: PText.heading.copyWith(fontSize: 17)),
        ],
      ),
    ),
  );
}

/// ستاره‌ها و سکه‌های کودک، بالای صفحه‌ها.
class WalletBar extends ConsumerWidget {
  const WalletBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final g = ref.watch(gameProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CountChip(icon: Icons.star_rounded, value: g.stars, color: G.yellow, label: 'ستاره'),
        const SizedBox(width: 8),
        CountChip(icon: Icons.monetization_on_rounded, value: g.coins, color: G.orange, label: 'سکه'),
      ],
    );
  }
}

class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 22, this.max = 3});

  final int stars;
  final double size;
  final int max;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${fa(stars)} ستاره از ${fa(max)}',
    excludeSemantics: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < max; i++)
          Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: i < stars ? G.yellow : Colors.white70),
      ],
    ),
  );
}

/// عدد فارسی.
String fa(int n) {
  const d = '۰۱۲۳۴۵۶۷۸۹';
  return n.toString().split('').map((c) => int.tryParse(c) == null ? c : d[int.parse(c)]).join();
}

/// تصویر یک شیء یا شخصیت: نسخه‌ی رستری اگر هست (art/items، art/characters)، وگرنه شکلک
/// روی دایره‌ی رنگی تا بازی همیشه قابل بازی باشد.
class GameArt extends ConsumerWidget {
  const GameArt(this.id, {super.key, this.size = 96, this.label});

  final String id;
  final double size;
  final String? label;

  static String? pathOf(WidgetRef ref, String id) {
    final assets = ref.read(assetsProvider);
    for (final p in ['art/items/$id.webp', 'art/characters/$id.webp']) {
      if (assets.exists(p)) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final path = pathOf(ref, id);
    final provider = path == null ? null : assets.image(path);
    final Widget img;
    if (provider != null) {
      img = Image(
        image: provider,
        width: size,
        height: size,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
      );
    } else {
      final data = ref.watch(gameDataProvider);
      final emoji = data.emoji[id] ?? data.friends[id]?.emoji ?? '✨';
      img = SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * .86,
            height: size * .86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [Colors.white, Color(0xFFFFF3E0)]),
              boxShadow: G.soft(),
            ),
            alignment: Alignment.center,
            child: Text(emoji, style: TextStyle(fontSize: size * .5, height: 1.1)),
          ),
        ),
      );
    }
    return label == null ? ExcludeSemantics(child: img) : Semantics(label: label, image: true, child: img);
  }
}

/// آسمان و تپه‌های نقاشی‌شده (مثل گوش‌یار)؛ زیر همه‌ی صفحه‌ها. [image] اگر باشد روی آن.
class SkyScene extends ConsumerWidget {
  const SkyScene({super.key, this.image, this.night = false, this.child, this.dim = 0, this.hills = true});

  final String? image;
  final bool night;
  final Widget? child;
  final double dim;
  final bool hills;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetsProvider);
    final img = image != null && assets.exists(image!) ? assets.image(image!) : null;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (img != null)
          Image(image: img, fit: BoxFit.cover, filterQuality: FilterQuality.medium)
        else
          RepaintBoundary(
            child: CustomPaint(
              painter: _SkyPainter(night: night, hills: hills),
            ),
          ),
        if (dim > 0) ColoredBox(color: Colors.black.withValues(alpha: dim)),
        ?child,
      ],
    );
  }
}

class _SkyPainter extends CustomPainter {
  _SkyPainter({required this.night, required this.hills});

  final bool night;
  final bool hills;

  @override
  void paint(Canvas canvas, Size s) {
    final sky = night
        ? const [Color(0xFF1B2470), Color(0xFF3549B8), Color(0xFF4F6BD8)]
        : const [Color(0xFF7CC8FF), Color(0xFFB9E3FF), Color(0xFFE8F6FF)];
    canvas.drawRect(
      Offset.zero & s,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Offset.zero & s),
    );
    final rnd = math.Random(7);
    if (night) {
      final star = Paint()..color = Colors.white.withValues(alpha: .85);
      for (var i = 0; i < 40; i++) {
        canvas.drawCircle(Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .5), rnd.nextDouble() * 1.8 + .6, star);
      }
      final c = Offset(s.width * .2, s.height * .12);
      final r = s.shortestSide * .085;
      canvas.drawCircle(c, r * 1.8, Paint()..color = const Color(0x33FFF3B0));
      canvas.drawCircle(c, r, Paint()..color = const Color(0xFFFFE27A));
      canvas.drawCircle(c + Offset(r * .45, -r * .2), r * .85, Paint()..color = const Color(0xFF26318A));
    } else {
      final sun = Offset(s.width * .16, s.height * .14);
      final r = s.shortestSide * .07;
      canvas.drawCircle(sun, r * 2, Paint()..color = const Color(0x33FFE066));
      canvas.drawCircle(sun, r, Paint()..color = const Color(0xFFFFD43B));
      final cloud = Paint()..color = Colors.white.withValues(alpha: .95);
      for (final (x, y, k) in [(.72, .1, 1.0), (.42, .2, .7), (.9, .27, .6)]) {
        final o = Offset(s.width * x, s.height * y);
        final u = s.shortestSide * .05 * k;
        canvas.drawCircle(o, u, cloud);
        canvas.drawCircle(o + Offset(u * 1.1, u * .2), u * .8, cloud);
        canvas.drawCircle(o + Offset(-u * 1.1, u * .3), u * .7, cloud);
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, u * .55), width: u * 3.4, height: u * .9), Radius.circular(u)),
          cloud,
        );
      }
    }
    if (!hills) return;
    void hill(double top, Color c, double phase) {
      final p = Path()..moveTo(0, s.height);
      for (var x = 0.0; x <= s.width; x += 8) {
        p.lineTo(x, s.height * top + math.sin(x / s.width * math.pi * 2 + phase) * s.height * .035);
      }
      p
        ..lineTo(s.width, s.height)
        ..close();
      canvas.drawPath(p, Paint()..color = c);
    }

    hill(.62, night ? const Color(0xFF2E7D5B) : const Color(0xFF9BE07A), 0);
    hill(.72, night ? const Color(0xFF256B4D) : const Color(0xFF7BD162), 2);
    hill(.84, night ? const Color(0xFF1E5A40) : const Color(0xFF5DC04A), 4);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.night != night || old.hills != hills;
}

/// حباب حرف پوپو کنار تصویرش (مثل گوش‌یار). متن همان زیرنویس گوینده است.
class PopoSays extends ConsumerWidget {
  const PopoSays({super.key, this.text, this.pose = PopoPose.idle, this.size = 76});

  /// اگر null باشد، آخرین جمله‌ی گوینده نشان داده می‌شود.
  final String? text;
  final PopoPose pose;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    return ValueListenableBuilder(
      valueListenable: audio.caption,
      builder: (context, line, _) {
        final t = text ?? line?.text;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            PopoMascot(pose: pose, size: size),
            const SizedBox(width: 6),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: t == null
                    ? const SizedBox.shrink()
                    : Container(
                        key: ValueKey(t),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: G.soft()),
                        child: Text(
                          t,
                          style: PText.bodyStrong.copyWith(fontSize: 16, color: G.ink),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// نوار بالای صفحه‌های بازی: بازگشت، عنوان، کیف ستاره و سکه.
class GameTopBar extends StatelessWidget {
  const GameTopBar({super.key, required this.title, this.onBack, this.trailing, this.light = false});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool light;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Row(
      children: [
        if (onBack != null) ClayIconButton(icon: Icons.arrow_forward_rounded, label: 'برگشت', onTap: onBack),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: PText.title.copyWith(color: light ? Colors.white : G.purple, fontSize: 22),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        trailing ?? const WalletBar(),
      ],
    ),
  );
}
