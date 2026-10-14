import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../audio/popo_audio.dart';

/// دکمه‌ی گرد «خمیری» با لبه‌ی تیره‌تر پایین که هنگام فشار پایین می‌رود.
class PButton extends ConsumerStatefulWidget {
  const PButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = PColors.blue,
    this.icon,
    this.expand = false,
    this.big = false,
    this.semanticLabel,
    this.sound = UiSound.tap,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final IconData? icon;
  final bool expand;
  final bool big;
  final String? semanticLabel;
  final UiSound? sound;

  @override
  ConsumerState<PButton> createState() => _PButtonState();
}

class _PButtonState extends ConsumerState<PButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final color = enabled ? widget.color : PColors.line;
    final h = widget.big ? PTouch.big : PTouch.button;
    const depth = 6.0;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: enabled ? Colors.white : PColors.inkSoft, size: widget.big ? 30 : 26),
          const SizedBox(width: PSpace.xs),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: PText.button.copyWith(fontSize: widget.big ? 22 : 19, color: enabled ? Colors.white : PColors.inkSoft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                if (widget.sound != null) ref.read(audioProvider).ui(widget.sound!);
                widget.onPressed!();
              }
            : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: h + depth, minWidth: h * 1.6),
          child: Stack(
            children: [
              Positioned.fill(
                top: depth,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: PColors.shade(color, .14), borderRadius: BorderRadius.circular(PRadius.pill)),
                ),
              ),
              AnimatedPadding(
                duration: PMotion.tap,
                padding: EdgeInsets.only(top: _down ? depth : 0, bottom: _down ? 0 : depth),
                child: Container(
                  height: h,
                  padding: const EdgeInsets.symmetric(horizontal: PSpace.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [PColors.tint(color, .08), color],
                    ),
                    borderRadius: BorderRadius.circular(PRadius.pill),
                    boxShadow: _down ? null : PShadow.soft(color),
                  ),
                  alignment: Alignment.center,
                  child: content,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// دکمه‌ی گرد آیکونی (بازگشت، تنظیمات، مکث و…).
class PIconButton extends ConsumerStatefulWidget {
  const PIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = Colors.white,
    this.iconColor = PColors.blue,
    this.size = PTouch.min,
    this.badge,
  });

  final IconData icon;

  /// برچسب دسترس‌پذیری (و راهنمای نگه‌داشتن).
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color iconColor;
  final double size;
  final Widget? badge;

  @override
  ConsumerState<PIconButton> createState() => _PIconButtonState();
}

class _PIconButtonState extends ConsumerState<PIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTapDown: enabled ? (_) => setState(() => _down = true) : null,
          onTapCancel: () => setState(() => _down = false),
          onTapUp: (_) => setState(() => _down = false),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  ref.read(audioProvider).ui(UiSound.tap);
                  widget.onPressed!();
                }
              : null,
          child: AnimatedScale(
            scale: _down ? .9 : 1,
            duration: PMotion.tap,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: enabled ? widget.color : PColors.line,
                    shape: BoxShape.circle,
                    boxShadow: PShadow.soft(),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(widget.icon, color: enabled ? widget.iconColor : PColors.inkSoft, size: widget.size * .5),
                ),
                if (widget.badge != null) PositionedDirectional(top: -4, end: -4, child: widget.badge!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// کاشی بزرگ لمسی (آیکون/تصویر + برچسب) برای کتابخانه‌ی فعالیت‌ها، ابزارها و…
class PTile extends ConsumerStatefulWidget {
  const PTile({
    super.key,
    required this.child,
    required this.label,
    required this.onTap,
    this.color = Colors.white,
    this.selected = false,
    this.showLabel = true,
    this.locked = false,
    this.semanticHint,
    this.labelLines = 1,
  });

  final Widget child;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool selected;
  final bool showLabel;
  final bool locked;
  final String? semanticHint;
  final int labelLines;

  @override
  ConsumerState<PTile> createState() => _PTileState();
}

class _PTileState extends ConsumerState<PTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: widget.selected,
      label: widget.label,
      hint: widget.semanticHint,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                ref.read(audioProvider).ui(UiSound.pop);
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? .94 : (widget.selected ? 1.04 : 1),
          duration: PMotion.tap,
          child: AnimatedContainer(
            duration: PMotion.quick,
            padding: const EdgeInsets.all(PSpace.xs),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(PRadius.md),
              border: Border.all(color: widget.selected ? PColors.orange : Colors.white, width: widget.selected ? 4 : 3),
              boxShadow: widget.selected ? PShadow.glow(PColors.orange) : PShadow.soft(),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Opacity(opacity: widget.locked ? .45 : 1, child: widget.child),
                      if (widget.locked) const Icon(Icons.lock_rounded, color: PColors.inkSoft, size: 32),
                    ],
                  ),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: PSpace.xxs),
                  Text(
                    widget.label,
                    style: PText.label,
                    maxLines: widget.labelLines,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
