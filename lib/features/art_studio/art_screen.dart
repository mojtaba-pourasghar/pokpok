import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../mascot/popo_mascot.dart';
import 'drawing.dart';

const artColors = <Color>[
  Color(0xFFF2574E),
  Color(0xFFFF9D37),
  Color(0xFFFFD34F),
  Color(0xFFA6D943),
  Color(0xFF3DBE6B),
  Color(0xFF16B9D1),
  Color(0xFF3778F6),
  Color(0xFFA77BEF),
  Color(0xFFFF8FB8),
  Color(0xFF8B5A3C),
  Color(0xFF2B2A4C),
  Color(0xFFFFFFFF),
];

/// پهنای قلم نسبت به ضلع کوچک بوم.
const brushSizes = <double>[.012, .028, .06];

/// استودیوی نقاشی: بوم، رنگ، اندازه‌ی قلم، پاک‌کن، برگرداندن، پاک کردن همه (با پرسش) و ذخیره.
/// هر خط پس از تمام شدن در پیش‌نویس ذخیره می‌شود؛ بسته شدن برنامه نقاشی را گم نمی‌کند.
class ArtScreen extends ConsumerStatefulWidget {
  const ArtScreen({super.key, this.artworkId});

  final String? artworkId;

  @override
  ConsumerState<ArtScreen> createState() => _ArtScreenState();
}

class _ArtScreenState extends ConsumerState<ArtScreen> with ActivitySession {
  late final ArtworkRepository _repo = ref.read(artworkRepoProvider);
  late final String _profile = ref.read(activeIdProvider);
  final List<Stroke> _strokes = [];
  final _live = ValueNotifier<Stroke?>(null);
  int _rev = 0;
  Color _color = artColors[6];
  double _width = brushSizes[1];
  bool _eraser = false;
  String? _editingId;
  DateTime _created = DateTime.now();
  static const _bg = Colors.white;

  @override
  String get activityId => 'art.draw';
  @override
  String get activityTitle => 'نقاشی';
  @override
  String? get resumeRoute => '/art';

  @override
  void initState() {
    super.initState();
    final open = widget.artworkId == null ? null : _repo.get(_profile, widget.artworkId!);
    final source = open ?? _repo.draft(_profile);
    if (source != null) {
      _strokes.addAll(source.strokes);
      _created = source.createdAt;
      _editingId = open?.id;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider).startMusic('audio/music/play_loop.mp3');
      ref.say('art.hello');
      award('world.art');
    });
  }

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  Artwork get _artwork => Artwork(id: _editingId ?? '_draft', createdAt: _created, strokes: List.of(_strokes), background: _bg.toARGB32());

  void _saveDraft() => _repo.saveDraft(_profile, _artwork);

  void _start(Offset p, Size size) {
    _live.value = Stroke(color: _color, width: _width, eraser: _eraser, points: [_norm(p, size)]);
  }

  void _move(Offset p, Size size) {
    final s = _live.value;
    if (s == null) return;
    _live.value = Stroke(color: s.color, width: s.width, eraser: s.eraser, points: [...s.points, _norm(p, size)]);
  }

  void _end() {
    final s = _live.value;
    if (s == null) return;
    setState(() {
      _strokes.add(s);
      _rev++;
    });
    _live.value = null;
    _saveDraft();
  }

  Offset _norm(Offset p, Size s) => Offset((p.dx / s.width).clamp(0, 1), (p.dy / s.height).clamp(0, 1));

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.removeLast();
      _rev++;
    });
    ref.read(audioProvider).play('audio/sfx/eraser.mp3');
    _saveDraft();
  }

  Future<void> _clear() async {
    unawaited(ref.say('art.clear.ask'));
    final ok = await confirm(context, title: 'همه‌ی نقاشی پاک شود؟', yes: 'پاک کن', no: 'نه، بماند');
    if (!ok) return;
    setState(() {
      _strokes.clear();
      _rev++;
    });
    ref.read(audioProvider).ui(UiSound.whoosh);
    _saveDraft();
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      toast(context, 'اول یک چیزی بکش!');
      return;
    }
    final id = _editingId ?? newId('a');
    await _repo.save(_profile, Artwork(id: id, createdAt: _created, strokes: List.of(_strokes), background: _bg.toARGB32()));
    await _repo.clearDraft(_profile);
    ref.read(audioProvider).ui(UiSound.camera);
    if (!mounted) return;
    setState(() {
      _editingId = null;
      _strokes.clear();
      _created = DateTime.now();
      _rev++;
    });
    await ref.say('art.saved');
    await award('art.saved');
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    return PScaffold(
      title: 'هنر و نقاشی',
      color: PColors.tint(PColors.pink, .2),
      actions: [
        PIconButton(
          icon: Icons.photo_library_rounded,
          label: 'نقاشی‌های من',
          iconColor: PColors.purple,
          onPressed: () => context.push('/art/gallery'),
        ),
        PIconButton(icon: Icons.check_rounded, label: 'ذخیره', iconColor: PColors.success, onPressed: _save),
      ],
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth > box.maxHeight;
          final canvas = Padding(
            padding: const EdgeInsets.all(PSpace.sm),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PRadius.lg),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.white, width: 6),
                  borderRadius: BorderRadius.circular(PRadius.lg),
                  boxShadow: PShadow.soft(PColors.pink),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final size = c.biggest;
                    return Semantics(
                      label: 'بوم نقاشی؛ با انگشت بکش',
                      child: GestureDetector(
                        onPanStart: (d) => _start(d.localPosition, size),
                        onPanUpdate: (d) => _move(d.localPosition, size),
                        onPanEnd: (_) => _end(),
                        onTapDown: (d) => _start(d.localPosition, size),
                        onTapUp: (_) => _end(),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: RepaintBoundary(
                                child: CustomPaint(painter: StrokesPainter(_strokes, _bg, revision: _rev)),
                              ),
                            ),
                            Positioned.fill(
                              child: RepaintBoundary(child: CustomPaint(painter: LiveStrokePainter(_live, _bg))),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
          final tools = _Tools(
            vertical: wide,
            color: _color,
            width: _width,
            eraser: _eraser,
            canUndo: _strokes.isNotEmpty,
            onColor: (c) => setState(() {
              _color = c;
              _eraser = false;
            }),
            onWidth: (w) => setState(() => _width = w),
            onEraser: () => setState(() => _eraser = !_eraser),
            onUndo: _undo,
            onClear: _clear,
          );
          return Stack(
            children: [
              wide
                  ? Row(
                      children: [
                        Expanded(child: canvas),
                        SizedBox(width: 200, child: tools),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(child: canvas),
                        tools,
                      ],
                    ),
              PositionedDirectional(
                bottom: wide ? 0 : 150,
                start: 0,
                child: IgnorePointer(
                  child: PopoMascot(pose: PopoPose.pointing, size: 96, pointRight: false, reducedMotion: reduced),
                ),
              ),
              const CaptionBubble(),
            ],
          );
        },
      ),
    );
  }
}

class _Tools extends StatelessWidget {
  const _Tools({
    required this.vertical,
    required this.color,
    required this.width,
    required this.eraser,
    required this.canUndo,
    required this.onColor,
    required this.onWidth,
    required this.onEraser,
    required this.onUndo,
    required this.onClear,
  });

  final bool vertical;
  final Color color;
  final double width;
  final bool eraser;
  final bool canUndo;
  final ValueChanged<Color> onColor;
  final ValueChanged<double> onWidth;
  final VoidCallback onEraser;
  final VoidCallback onUndo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final swatches = Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final c in artColors)
          Semantics(
            button: true,
            selected: c == color && !eraser,
            label: 'رنگ',
            child: GestureDetector(
              onTap: () => onColor(c),
              child: AnimatedContainer(
                duration: PMotion.tap,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: c == color && !eraser ? PColors.ink : Colors.white, width: c == color && !eraser ? 4 : 3),
                  boxShadow: PShadow.soft(),
                ),
              ),
            ),
          ),
      ],
    );
    final buttons = Wrap(
      alignment: WrapAlignment.center,
      spacing: PSpace.xs,
      runSpacing: PSpace.xs,
      children: [
        for (final (i, w) in brushSizes.indexed)
          Semantics(
            button: true,
            selected: w == width,
            label: ['قلم نازک', 'قلم متوسط', 'قلم کلفت'][i],
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onWidth(w),
              child: AnimatedContainer(
                duration: PMotion.tap,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: w == width ? PColors.tint(PColors.orange, .32) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: PShadow.soft(),
                ),
                alignment: Alignment.center,
                child: Container(
                  width: [10.0, 18.0, 28.0][i],
                  height: [10.0, 18.0, 28.0][i],
                  decoration: BoxDecoration(color: eraser || color == Colors.white ? PColors.inkSoft : color, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        PIconButton(
          icon: Icons.auto_fix_normal_rounded,
          label: 'پاک‌کن',
          size: 52,
          iconColor: eraser ? Colors.white : PColors.pink,
          color: eraser ? PColors.pink : Colors.white,
          onPressed: onEraser,
        ),
        PIconButton(icon: Icons.undo_rounded, label: 'برگرداندن', size: 52, iconColor: PColors.blue, onPressed: canUndo ? onUndo : null),
        PIconButton(
          icon: Icons.delete_sweep_rounded,
          label: 'پاک کردن همه',
          size: 52,
          iconColor: PColors.danger,
          onPressed: canUndo ? onClear : null,
        ),
      ],
    );
    return Container(
      margin: const EdgeInsets.fromLTRB(PSpace.sm, 0, PSpace.sm, PSpace.sm),
      padding: const EdgeInsets.all(PSpace.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(PRadius.lg),
        boxShadow: PShadow.soft(),
      ),
      child: SafeArea(
        top: false,
        child: vertical
            ? SingleChildScrollView(
                child: Column(
                  children: [
                    swatches,
                    const SizedBox(height: PSpace.md),
                    buttons,
                  ],
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  swatches,
                  const SizedBox(height: PSpace.xs),
                  buttons,
                ],
              ),
      ),
    );
  }
}
