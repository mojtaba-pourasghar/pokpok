import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../features/mascot/popo_mascot.dart';
import '../assets/asset_resolver.dart';
import '../content/content.dart';
import 'buttons.dart';

final _svgCache = <String, String>{};

/// SVG دانلودشده یک بار از دیسک خوانده و نگه داشته می‌شود.
String _downloadedSvg(String path) => _svgCache[path] ??= File(path).readAsStringSync();

/// تصویر یک شیء با شناسه‌ی art_manifest. اگر نسخه‌ی رستری دانلودشده باشد همان نشان داده
/// می‌شود؛ وگرنه طرح برداری داخلی.
class ArtImage extends ConsumerWidget {
  const ArtImage(this.id, {super.key, this.size, this.fit = BoxFit.contain, this.semanticLabel});

  final String id;
  final double? size;
  final BoxFit fit;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentProvider);
    final assets = ref.watch(assetsProvider);
    final path = content.artPath(id);
    final raster = path.endsWith('.svg') ? assets.rasterOverride(path) : path;
    Widget img;
    if (raster != null) {
      final provider = assets.image(raster);
      img = provider == null
          ? SizedBox(width: size, height: size)
          : Image(image: provider, width: size, height: size, fit: fit, gaplessPlayback: true, filterQuality: FilterQuality.medium);
    } else {
      final r = assets.resolve(path);
      img = r != null && r.source == AssetSource.downloaded
          ? SvgPicture.string(_downloadedSvg(r.key), width: size, height: size, fit: fit)
          : SvgPicture.asset('assets/$path', width: size, height: size, fit: fit);
    }
    return semanticLabel == null ? ExcludeSemantics(child: img) : Semantics(label: semanticLabel, image: true, child: img);
  }
}

/// پوسته‌ی مشترک صفحه‌ها: پس‌زمینه‌ی آسمانی، نوار بالا با دکمه‌ی بازگشت و عنوان.
class PScaffold extends StatelessWidget {
  const PScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
    this.color = PColors.background,
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final Color color;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      body: SafeArea(
        bottom: bottom == null,
        // stretch: بدنه همیشه پهنای کامل دارد، حتی اگر Stack درونش فرزند بی‌جای بزرگی نداشته باشد.
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PTopBar(title: title, actions: actions, onBack: onBack, showBack: showBack),
            Expanded(child: body),
            ?bottom,
          ],
        ),
      ),
    );
  }
}

class PTopBar extends StatelessWidget {
  const PTopBar({super.key, required this.title, this.actions = const [], this.onBack, this.showBack = true, this.light = false});

  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final bool showBack;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.md, PSpace.sm, PSpace.md, PSpace.xs),
      child: Row(
        children: [
          if (showBack)
            PIconButton(
              icon: Icons.arrow_back_rounded,
              label: 'بازگشت',
              onPressed: onBack ?? () => context.canPop() ? context.pop() : context.go('/map'),
            ),
          const SizedBox(width: PSpace.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: PSpace.xs),
              decoration: BoxDecoration(
                color: light ? Colors.white.withValues(alpha: .9) : Colors.transparent,
                borderRadius: BorderRadius.circular(PRadius.pill),
              ),
              child: Semantics(
                header: true,
                child: Text(title, style: PText.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
          for (final a in actions)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: PSpace.xs),
              child: a,
            ),
        ],
      ),
    );
  }
}

class PCard extends StatelessWidget {
  const PCard({super.key, required this.child, this.padding = const EdgeInsets.all(PSpace.md), this.color = Colors.white});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(PRadius.lg), boxShadow: PShadow.soft()),
    child: child,
  );
}

class PProgressBar extends StatelessWidget {
  const PProgressBar({super.key, required this.value, this.color = PColors.success, this.height = 14, this.label});

  final double value;
  final Color color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    value: '${(value * 100).round()}٪',
    child: Container(
      height: height,
      decoration: BoxDecoration(color: PColors.line, borderRadius: BorderRadius.circular(height)),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value.clamp(0, 1).toDouble(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [PColors.tint(color, .1), color]),
            borderRadius: BorderRadius.circular(height),
          ),
        ),
      ),
    ),
  );
}

/// حباب زیرنویس حرف‌های پوپو؛ تا وقتی صدای گوینده ضبط نشده یا صدا خاموش است، کودک متن را می‌بیند.
class CaptionBubble extends ConsumerWidget {
  const CaptionBubble({super.key, this.alignment = Alignment.topCenter});

  final Alignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioProvider);
    final show = ref.watch(settingsProvider.select((s) => s.captions));
    return ValueListenableBuilder<VoiceLine?>(
      valueListenable: audio.caption,
      builder: (context, line, _) {
        final visible = show && line != null;
        return IgnorePointer(
          child: AnimatedSwitcher(
            duration: PMotion.quick,
            child: !visible
                ? const SizedBox.shrink()
                : Align(
                    key: ValueKey(line.id),
                    alignment: alignment,
                    child: Semantics(
                      liveRegion: true,
                      label: 'پوپو می‌گوید: ${line.text}',
                      excludeSemantics: true,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 520),
                        margin: const EdgeInsets.symmetric(horizontal: PSpace.lg, vertical: PSpace.xs),
                        padding: const EdgeInsets.symmetric(horizontal: PSpace.lg, vertical: PSpace.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(PRadius.lg),
                          border: Border.all(color: PColors.tint(PColors.orange, .2), width: 3),
                          boxShadow: PShadow.soft(),
                        ),
                        child: Text(line.text, style: PText.bodyStrong.copyWith(fontSize: 18), textAlign: TextAlign.center),
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}

enum ViewState { loading, empty, offline, error, success, pending }

/// حالت‌های بارگذاری، خالی، آفلاین، خطا، موفقیت و در انتظار؛ با پوپو و یک کار مشخص.
class StateView extends StatelessWidget {
  const StateView({super.key, required this.state, required this.message, this.actionLabel, this.onAction, this.compact = false});

  final ViewState state;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final pose = switch (state) {
      ViewState.loading || ViewState.pending => PopoPose.thinking,
      ViewState.empty => PopoPose.curious,
      ViewState.offline || ViewState.error => PopoPose.surprised,
      ViewState.success => PopoPose.happy,
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(PSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) PopoMascot(pose: pose, size: 150),
            if (state == ViewState.loading || state == ViewState.pending) ...[
              const SizedBox(height: PSpace.sm),
              const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 4)),
            ],
            const SizedBox(height: PSpace.md),
            Text(message, style: PText.heading, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: PSpace.lg),
              PButton(label: actionLabel!, onPressed: onAction, color: PColors.orange),
            ],
          ],
        ),
      ),
    );
  }
}

class SettingRow extends StatelessWidget {
  const SettingRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color = PColors.blue,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(PRadius.md),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: PTouch.min),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: PSpace.sm, vertical: PSpace.xs),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: PColors.tint(color, .3), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: PSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: PText.bodyStrong),
                    if (subtitle != null) Text(subtitle!, style: PText.caption),
                  ],
                ),
              ),
              ?trailing,
              if (trailing == null && onTap != null) const Icon(Icons.chevron_left_rounded, color: PColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

/// پرسش تأیید (حذف، پاک کردن). دکمه‌ها بزرگ و رنگشان معنادار است.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? message,
  String yes = 'بله',
  String no = 'نه',
  Color yesColor = PColors.danger,
  PopoPose pose = PopoPose.thinking,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      contentPadding: const EdgeInsets.all(PSpace.lg),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopoMascot(pose: pose, size: 110),
          const SizedBox(height: PSpace.sm),
          Text(title, style: PText.title, textAlign: TextAlign.center),
          if (message != null) ...[const SizedBox(height: PSpace.xs), Text(message, style: PText.body, textAlign: TextAlign.center)],
          const SizedBox(height: PSpace.lg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: PSpace.sm,
            runSpacing: PSpace.sm,
            children: [
              PButton(label: no, color: PColors.turquoise, onPressed: () => Navigator.pop(ctx, false)),
              PButton(label: yes, color: yesColor, onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        ],
      ),
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String message, {Color color = PColors.ink}) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PRadius.md)),
        content: Text(message, style: PText.bodyStrong.copyWith(color: Colors.white)),
      ),
    );
}

/// ستاره‌های جشن کوچک در یک نقطه (بازخورد لمس). با حرکت کمتر فقط یک درخشش کوتاه است.
class Burst extends StatefulWidget {
  const Burst({super.key, required this.onDone, this.color = PColors.yellow, this.count = 8, this.radius = 60, this.reduced = false});

  final VoidCallback onDone;
  final Color color;
  final int count;
  final double radius;
  final bool reduced;

  @override
  State<Burst> createState() => _BurstState();
}

class _BurstState extends State<Burst> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
    ..forward().whenComplete(widget.onDone);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) =>
          CustomPaint(size: Size.square(widget.radius * 2), painter: _BurstPainter(_c.value, widget.color, widget.count, widget.reduced)),
    ),
  );
}

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t, this.color, this.count, this.reduced);

  final double t;
  final Color color;
  final int count;
  final bool reduced;

  @override
  void paint(Canvas c, Size s) {
    final center = s.center(Offset.zero);
    final fade = (1 - t).clamp(0.0, 1.0);
    if (reduced) {
      c.drawCircle(center, s.width * .3, Paint()..color = color.withValues(alpha: .35 * fade));
      return;
    }
    final colors = [color, PColors.pink, PColors.turquoise, PColors.orange];
    for (var i = 0; i < count; i++) {
      final a = i * math.pi * 2 / count;
      final d = s.width / 2 * Curves.easeOut.transform(t);
      final p = center + Offset(math.cos(a), math.sin(a)) * d;
      _star(c, p, 7 * (1 - t * .5), Paint()..color = colors[i % colors.length].withValues(alpha: fade));
    }
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rr = i.isEven ? r : r * .45;
      final pt = o + Offset(math.cos(a), math.sin(a)) * rr;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}
