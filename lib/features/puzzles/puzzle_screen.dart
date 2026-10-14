import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../construction/build_screen.dart' show BlockShape, PieceArt, PieceKind;
import '../mascot/popo_mascot.dart';
import 'puzzle_logic.dart';

/// پازل‌ها: جور کردن شکل‌ها، مرتب‌سازی رنگ‌ها، کامل کردن الگو، بازی حافظه.
class PuzzleScreen extends ConsumerStatefulWidget {
  const PuzzleScreen({super.key, required this.kind});

  final String kind;

  @override
  ConsumerState<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends ConsumerState<PuzzleScreen> with ActivitySession {
  final _rand = math.Random();
  int _round = 0;
  bool _done = false;
  PopoPose _pose = PopoPose.idle;

  static const titles = {'shapes': 'جور کردن شکل‌ها', 'sort': 'مرتب کردن رنگ‌ها', 'pattern': 'الگو', 'match': 'بازی حافظه'};

  @override
  String get activityId => 'puzzle.${widget.kind}';
  @override
  String get activityTitle => titles[widget.kind] ?? 'پازل';
  @override
  String? get resumeRoute => '/puzzle/${widget.kind}';

  PuzzleLevel get _level => PuzzleLevel.forAge(ref.read(activeProfileProvider)?.ageBand ?? AgeBand.preschool);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider).startMusic('audio/music/play_loop.mp3');
      ref.say('puzzle.${widget.kind}');
    });
  }

  void _good() {
    ref.read(audioProvider).ui(UiSound.pop);
    setState(() => _pose = PopoPose.happy);
  }

  void _miss() {
    // اشتباه تنبیه ندارد: صدای نرم، پوپوی فکور و یک جمله‌ی تشویق.
    ref.read(audioProvider).ui(UiSound.softNo);
    ref.sayOneOf('try');
    setState(() => _pose = PopoPose.thinking);
  }

  Future<void> _complete() async {
    setState(() {
      _done = true;
      _pose = PopoPose.happy;
    });
    ref.read(audioProvider).ui(UiSound.success);
    await ref.read(progressProvider.notifier).complete(activityId);
    await ref.sayOneOf('praise');
    await award(activityId);
  }

  void _again() => setState(() {
    _round++;
    _done = false;
    _pose = PopoPose.idle;
  });

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    final level = _level;
    final key = ValueKey('${widget.kind}#$_round');
    final game = switch (widget.kind) {
      'shapes' => _DropGame(
        key: key,
        items: shapeRound(level.pieces, _rand),
        byColor: false,
        onGood: _good,
        onMiss: _miss,
        onDone: _complete,
      ),
      'sort' => _DropGame(key: key, items: sortRound(level.colors, _rand), byColor: true, onGood: _good, onMiss: _miss, onDone: _complete),
      'pattern' => _PatternGame(key: key, kind: level.patternKind, rand: _rand, onGood: _good, onMiss: _miss, onDone: _complete),
      'match' => _MatchGame(
        key: key,
        pairs: level.pairs,
        rand: _rand,
        onGood: _good,
        onMiss: () => setState(() => _pose = PopoPose.thinking),
        onDone: _complete,
      ),
      _ => const StateView(state: ViewState.empty, message: 'این پازل پیدا نشد.'),
    };
    return PScaffold(
      title: activityTitle,
      color: PColors.tint(PColors.blue, .36),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: game),
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: IgnorePointer(
              child: PopoMascot(pose: _pose, size: 110, reducedMotion: reduced),
            ),
          ),
          const CaptionBubble(alignment: Alignment.bottomCenter),
          if (_done)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: Center(
                  child: PCard(
                    padding: const EdgeInsets.all(PSpace.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopoMascot(pose: PopoPose.happy, size: 150, reducedMotion: reduced),
                        Text('آفرین!', style: PText.display.copyWith(color: PColors.orange)),
                        const SizedBox(height: PSpace.md),
                        Wrap(
                          spacing: PSpace.sm,
                          runSpacing: PSpace.sm,
                          alignment: WrapAlignment.center,
                          children: [
                            PButton(label: 'یکی دیگر', icon: Icons.refresh_rounded, color: PColors.orange, onPressed: _again),
                            PButton(
                              label: 'بازی‌ها',
                              icon: Icons.apps_rounded,
                              color: PColors.blue,
                              onPressed: () => context.go('/library'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

PieceKind _kindFor(ShapeItem s, {bool ghost = false}) {
  final (w, h) = switch (s.shape) {
    BlockShape.long => (.3, .12),
    BlockShape.arch => (.24, .16),
    _ => (.17, .17),
  };
  return PieceKind('p', '', w, h, color: ghost ? const Color(0xFFCBD3E6) : s.color, shape: s.shape);
}

/// جور کردن شکل با سایه‌اش، یا رنگ با سبد هم‌رنگ.
class _DropGame extends StatefulWidget {
  const _DropGame({
    super.key,
    required this.items,
    required this.byColor,
    required this.onGood,
    required this.onMiss,
    required this.onDone,
  });

  final List<ShapeItem> items;
  final bool byColor;
  final VoidCallback onGood;
  final VoidCallback onMiss;
  final VoidCallback onDone;

  @override
  State<_DropGame> createState() => _DropGameState();
}

class _DropGameState extends State<_DropGame> {
  final Set<int> _placed = {};

  List<Color> get _baskets => {for (final i in widget.items) i.color}.toList();

  bool _accepts(int target, int item) => widget.byColor ? _baskets[target] == widget.items[item].color : target == item;

  void _drop(int target, int item) {
    if (_accepts(target, item)) {
      HapticFeedback.mediumImpact();
      setState(() => _placed.add(item));
      widget.onGood();
      if (_placed.length == widget.items.length) widget.onDone();
    } else {
      widget.onMiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final u = box.biggest.shortestSide;
        final targets = widget.byColor ? _baskets.length : widget.items.length;
        return Column(
          children: [
            Expanded(
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  spacing: PSpace.md,
                  runSpacing: PSpace.md,
                  children: [
                    for (var t = 0; t < targets; t++)
                      DragTarget<int>(
                        onWillAcceptWithDetails: (_) => true,
                        onAcceptWithDetails: (d) => _drop(t, d.data),
                        builder: (context, cand, _) => widget.byColor ? _basket(t, u, cand.isNotEmpty) : _slot(t, u, cand.isNotEmpty),
                      ),
                  ],
                ),
              ),
            ),
            Container(
              constraints: BoxConstraints(minHeight: u * .3),
              margin: const EdgeInsets.all(PSpace.md),
              padding: const EdgeInsets.all(PSpace.sm),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(PRadius.lg)),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: PSpace.md,
                  runSpacing: PSpace.sm,
                  children: [
                    for (var i = 0; i < widget.items.length; i++)
                      if (!_placed.contains(i))
                        Draggable<int>(
                          data: i,
                          feedback: Material(color: Colors.transparent, child: _piece(i, u * 1.1)),
                          childWhenDragging: Opacity(opacity: .3, child: _piece(i, u)),
                          child: Semantics(
                            label: widget.byColor ? 'قطعه‌ی ${_colorName(widget.items[i].color)}' : 'شکل',
                            child: _piece(i, u),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 90),
          ],
        );
      },
    );
  }

  String _colorName(Color c) => puzzleColorNames[puzzleColors.indexOf(c).clamp(0, puzzleColorNames.length - 1)];

  Widget _piece(int i, double u) {
    final k = _kindFor(widget.items[i]);
    final scale = widget.byColor ? .7 : 1.0;
    return SizedBox(
      width: k.w * u * scale,
      height: k.h * u * scale,
      child: PieceArt(kind: k),
    );
  }

  Widget _slot(int t, double u, bool hover) {
    final item = widget.items[t];
    final k = _kindFor(item, ghost: !_placed.contains(t));
    return AnimatedContainer(
      duration: PMotion.tap,
      padding: const EdgeInsets.all(PSpace.sm),
      decoration: BoxDecoration(
        color: hover ? PColors.tint(PColors.yellow, .2) : Colors.white.withValues(alpha: .6),
        borderRadius: BorderRadius.circular(PRadius.md),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: SizedBox(
        width: k.w * u,
        height: k.h * u,
        child: PieceArt(kind: _placed.contains(t) ? _kindFor(item) : k),
      ),
    );
  }

  Widget _basket(int t, double u, bool hover) {
    final color = _baskets[t];
    final count = [
      for (final i in _placed)
        if (widget.items[i].color == color) i,
    ].length;
    return AnimatedScale(
      scale: hover ? 1.08 : 1,
      duration: PMotion.tap,
      child: Semantics(
        label: 'سبد ${_colorName(color)}',
        child: Container(
          width: u * .3,
          height: u * .28,
          decoration: BoxDecoration(
            color: PColors.tint(color, .25),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40), top: Radius.circular(12)),
            border: Border.all(color: color, width: 6),
            boxShadow: hover ? PShadow.glow(color) : PShadow.soft(color),
          ),
          alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [for (var i = 0; i < count; i++) Icon(Icons.star_rounded, color: PColors.shade(color, .1), size: 26)],
          ),
        ),
      ),
    );
  }
}

class _PatternGame extends StatefulWidget {
  const _PatternGame({super.key, required this.kind, required this.rand, required this.onGood, required this.onMiss, required this.onDone});

  final int kind;
  final math.Random rand;
  final VoidCallback onGood;
  final VoidCallback onMiss;
  final VoidCallback onDone;

  @override
  State<_PatternGame> createState() => _PatternGameState();
}

class _PatternGameState extends State<_PatternGame> {
  Timer? _next;

  @override
  void dispose() {
    _next?.cancel();
    super.dispose();
  }

  static const rounds = 3;
  int _step = 0;
  late PatternRound _r = patternRound(widget.kind, widget.rand);
  bool _revealed = false;

  void _choose(String art) {
    if (_revealed) return;
    if (art != _r.answer) {
      widget.onMiss();
      return;
    }
    widget.onGood();
    setState(() => _revealed = true);
    _next = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_step + 1 >= rounds) {
        widget.onDone();
      } else {
        setState(() {
          _step++;
          _r = patternRound(widget.kind, widget.rand);
          _revealed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cell = math.min(box.maxWidth / (_r.sequence.length + 1.5), 110.0);
        return Column(
          children: [
            const SizedBox(height: PSpace.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < rounds; i++)
                  Icon(
                    i < _step || (i == _step && _revealed) ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: PColors.orange,
                    size: 34,
                  ),
              ],
            ),
            Expanded(
              child: Center(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      for (final a in _r.sequence)
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: SizedBox(width: cell, height: cell, child: ArtImage(a)),
                        ),
                      Container(
                        width: cell,
                        height: cell,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(PRadius.md),
                          border: Border.all(color: PColors.orange, width: 4),
                        ),
                        child: _revealed
                            ? ArtImage(_r.answer)
                            : const Center(
                                child: Text(
                                  '؟',
                                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: PColors.orange),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 110),
              child: Wrap(
                spacing: PSpace.md,
                children: [
                  for (final o in _r.options)
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: PTile(label: 'گزینه', showLabel: false, onTap: () => _choose(o), child: ArtImage(o)),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MatchGame extends StatefulWidget {
  const _MatchGame({super.key, required this.pairs, required this.rand, required this.onGood, required this.onMiss, required this.onDone});

  final int pairs;
  final math.Random rand;
  final VoidCallback onGood;
  final VoidCallback onMiss;
  final VoidCallback onDone;

  @override
  State<_MatchGame> createState() => _MatchGameState();
}

class _MatchGameState extends State<_MatchGame> {
  Timer? _flipBack;

  @override
  void dispose() {
    _flipBack?.cancel();
    super.dispose();
  }

  late final List<String> _deck = matchDeck(widget.pairs, widget.rand);
  final Set<int> _found = {};
  final List<int> _open = [];
  bool _busy = false;

  void _flip(int i) {
    if (_busy || _found.contains(i) || _open.contains(i)) return;
    setState(() => _open.add(i));
    if (_open.length < 2) return;
    final a = _open[0], b = _open[1];
    if (_deck[a] == _deck[b]) {
      setState(() {
        _found.addAll([a, b]);
        _open.clear();
      });
      widget.onGood();
      if (_found.length == _deck.length) widget.onDone();
    } else {
      _busy = true;
      widget.onMiss();
      _flipBack = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() {
          _open.clear();
          _busy = false;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final cols = box.maxWidth > box.maxHeight ? (_deck.length / 2).ceil() : (_deck.length <= 6 ? 3 : 4);
        return Padding(
          padding: const EdgeInsets.fromLTRB(PSpace.md, PSpace.md, PSpace.md, 110),
          child: Center(
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: cols,
              mainAxisSpacing: PSpace.sm,
              crossAxisSpacing: PSpace.sm,
              children: [
                for (var i = 0; i < _deck.length; i++)
                  Semantics(
                    button: true,
                    label: _found.contains(i) || _open.contains(i) ? 'کارت باز' : 'کارت بسته',
                    child: GestureDetector(
                      onTap: () => _flip(i),
                      child: AnimatedSwitcher(
                        duration: PMotion.quick,
                        transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
                        child: _found.contains(i) || _open.contains(i)
                            ? Container(
                                key: const ValueKey(true),
                                decoration: BoxDecoration(
                                  color: _found.contains(i) ? PColors.tint(PColors.green, .25) : Colors.white,
                                  borderRadius: BorderRadius.circular(PRadius.md),
                                  boxShadow: PShadow.soft(),
                                ),
                                padding: const EdgeInsets.all(PSpace.sm),
                                child: ArtImage(_deck[i]),
                              )
                            : Container(
                                key: const ValueKey(false),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [PColors.purple, PColors.blue]),
                                  borderRadius: BorderRadius.circular(PRadius.md),
                                  border: Border.all(color: Colors.white, width: 4),
                                  boxShadow: PShadow.soft(),
                                ),
                                child: const Icon(Icons.star_rounded, color: Colors.white70, size: 40),
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
