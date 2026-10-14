import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../mascot/popo_mascot.dart';
import '../worlds/backgrounds/scene_backgrounds.dart';

/// یک نوع قطعه در کارگاه.
class PieceKind {
  const PieceKind(this.id, this.label, this.w, this.h, {this.art, this.color, this.shape, this.sound = 'audio/sfx/thunk.mp3'});

  final String id;
  final String label;

  /// اندازه نسبت به ضلع کوچک صحنه.
  final double w, h;
  final String? art;
  final Color? color;
  final BlockShape? shape;
  final String sound;

  bool get isGear => id == 'gear';
}

enum BlockShape { square, long, triangle, round, arch }

const pieceKinds = <PieceKind>[
  PieceKind('block_square', 'مکعب', .15, .15, color: PColors.danger, shape: BlockShape.square),
  PieceKind('block_long', 'تیر', .3, .1, color: PColors.blue, shape: BlockShape.long),
  PieceKind('block_tri', 'شیروانی', .17, .14, color: PColors.yellow, shape: BlockShape.triangle),
  PieceKind('block_round', 'استوانه', .14, .14, color: PColors.success, shape: BlockShape.round),
  PieceKind('block_arch', 'طاق', .22, .14, color: PColors.purple, shape: BlockShape.arch),
  PieceKind('road', 'جاده', .3, .13, art: 'road_piece'),
  PieceKind('bridge', 'پل', .32, .22, art: 'bridge'),
  PieceKind('gear', 'چرخ‌دنده', .17, .17, art: 'gear', sound: 'audio/sfx/gear.mp3'),
  PieceKind('wheel', 'چرخ', .13, .13, art: 'wheel'),
  PieceKind('cone', 'مخروط', .11, .11, art: 'cone'),
  PieceKind('crane', 'جرثقیل', .3, .3, art: 'crane', sound: 'audio/sfx/crane.mp3'),
  PieceKind('flag', 'پرچم', .12, .12, art: 'flag', sound: 'audio/ui/chime.mp3'),
  PieceKind('car', 'ماشین', .17, .17, art: 'car', sound: 'audio/sfx/car_horn.mp3'),
  PieceKind('house', 'خانه', .2, .2, art: 'house', sound: 'audio/sfx/doorbell.mp3'),
];

PieceKind? kindOf(String id) {
  for (final k in pieceKinds) {
    if (k.id == id) return k;
  }
  return null;
}

/// چرخ‌دنده‌هایی که به هم رسیده‌اند (هر کدام دست‌کم یک همسایه‌ی درگیر دارد).
Set<String> meshingGears(List<BuildPiece> pieces, Size stage) {
  final u = stage.shortestSide;
  final gears = pieces.where((p) => p.kind == 'gear').toList();
  final out = <String>{};
  for (var i = 0; i < gears.length; i++) {
    for (var j = i + 1; j < gears.length; j++) {
      final a = Offset(gears[i].x * stage.width, gears[i].y * stage.height);
      final b = Offset(gears[j].x * stage.width, gears[j].y * stage.height);
      final reach = .17 * u * 1.1;
      if ((a - b).distance <= reach && (a - b).distance > reach * .35) {
        out
          ..add(gears[i].uid)
          ..add(gears[j].uid);
      }
    }
  }
  return out;
}

/// کارگاه ساخت‌وساز: قطعه‌ها را از جعبه‌ی پایین بکش، جابه‌جا کن، با لمس بچرخان،
/// روی سطل بکش تا برداشته شود. بدون زمان‌سنج و بدون «شکست».
class BuildScreen extends ConsumerStatefulWidget {
  const BuildScreen({super.key});

  @override
  ConsumerState<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends ConsumerState<BuildScreen> with ActivitySession, SingleTickerProviderStateMixin {
  late final BuildRepository _repo = ref.read(buildRepoProvider);
  late final String _profile = ref.read(activeIdProvider);
  late List<BuildPiece> _pieces = _repo.load(_profile);
  late final AnimationController _spin = AnimationController(vsync: this, duration: const Duration(seconds: 4));
  final _stageKey = GlobalKey();
  final _trashKey = GlobalKey();
  String? _dragging;
  bool _overTrash = false;
  bool _gearsAwarded = false;
  Size _stage = Size.zero;
  static const maxPieces = 40;

  @override
  String get activityId => 'build';
  @override
  String get activityTitle => 'کارگاه ساخت‌وساز';
  @override
  String? get resumeRoute => '/build';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider).startMusic('audio/music/play_loop.mp3');
      ref.say('build.hello');
      award('world.build');
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  void _save() => _repo.save(_profile, _pieces);

  void _add(String kind, Offset local) {
    if (_pieces.length >= maxPieces || _stage == Size.zero) {
      ref.read(audioProvider).ui(UiSound.softNo);
      toast(context, 'جا پر شد! چند قطعه را روی سطل بکش.');
      return;
    }
    final k = kindOf(kind)!;
    setState(
      () => _pieces = [
        ..._pieces,
        BuildPiece(
          uid: newId('b'),
          kind: kind,
          x: (local.dx / _stage.width).clamp(.05, .95),
          y: (local.dy / _stage.height).clamp(.08, .95),
        ),
      ],
    );
    ref.sound(k.sound);
    _save();
    _checkGears();
  }

  void _move(BuildPiece p, Offset delta) {
    final i = _pieces.indexWhere((e) => e.uid == p.uid);
    if (i < 0) return;
    final cur = _pieces[i];
    final next = cur.copyWith(x: (cur.x + delta.dx / _stage.width).clamp(.03, .97), y: (cur.y + delta.dy / _stage.height).clamp(.05, .99));
    setState(() {
      _pieces = [..._pieces]..[i] = next;
      _overTrash = _hitsTrash(next);
    });
  }

  bool _hitsTrash(BuildPiece p) {
    final stageBox = _stageKey.currentContext?.findRenderObject() as RenderBox?;
    final trashBox = _trashKey.currentContext?.findRenderObject() as RenderBox?;
    if (stageBox == null || trashBox == null) return false;
    final global = stageBox.localToGlobal(Offset(p.x * _stage.width, p.y * _stage.height));
    final trash = trashBox.localToGlobal(Offset.zero) & trashBox.size;
    return trash.inflate(16).contains(global);
  }

  void _endMove(BuildPiece p) {
    final cur = _pieces.firstWhere((e) => e.uid == p.uid, orElse: () => p);
    if (_hitsTrash(cur)) {
      setState(() => _pieces = _pieces.where((e) => e.uid != p.uid).toList());
      ref.read(audioProvider).ui(UiSound.whoosh);
    } else {
      ref.sound(kindOf(cur.kind)?.sound);
    }
    setState(() {
      _dragging = null;
      _overTrash = false;
    });
    _save();
    _checkGears();
  }

  void _rotate(BuildPiece p) {
    final i = _pieces.indexWhere((e) => e.uid == p.uid);
    if (i < 0) return;
    setState(() => _pieces = [..._pieces]..[i] = p.copyWith(rotation: (p.rotation + 1) % 4));
    ref.sound(kindOf(p.kind)?.sound);
    _save();
  }

  void _checkGears() {
    final meshing = meshingGears(_pieces, _stage);
    if (meshing.isNotEmpty) {
      if (!_spin.isAnimating && MediaQuery.maybeDisableAnimationsOf(context) != true) _spin.repeat();
      if (!_gearsAwarded) {
        _gearsAwarded = true;
        ref.sound('audio/sfx/gear.mp3');
        ref.say('build.gears');
        award('build.gears');
      }
    } else if (_spin.isAnimating) {
      _spin.stop();
    }
  }

  Future<void> _clear() async {
    final ok = await confirm(context, title: 'همه‌ی قطعه‌ها برداشته شوند؟', yes: 'بردار', no: 'نه');
    if (!ok) return;
    setState(() => _pieces = []);
    ref.read(audioProvider).ui(UiSound.whoosh);
    _save();
    _checkGears();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    return PScaffold(
      title: 'کارگاه ساخت‌وساز',
      color: const Color(0xFFFFF4DA),
      actions: [
        PIconButton(
          icon: Icons.delete_sweep_rounded,
          label: 'برداشتن همه',
          iconColor: PColors.danger,
          onPressed: _pieces.isEmpty ? null : _clear,
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (d) {
                final box = _stageKey.currentContext!.findRenderObject() as RenderBox;
                final k = kindOf(d.data)!;
                final u = _stage.shortestSide;
                _add(d.data, box.globalToLocal(d.offset) + Offset(k.w * u * .5, k.h * u * .5));
              },
              builder: (context, candidates, _) => LayoutBuilder(
                key: _stageKey,
                builder: (context, box) {
                  _stage = box.biggest;
                  final u = _stage.shortestSide;
                  final meshing = meshingGears(_pieces, _stage);
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      const Positioned.fill(child: SceneBackground(id: 'workshop')),
                      if (candidates.isNotEmpty) Positioned.fill(child: ColoredBox(color: PColors.yellow.withValues(alpha: .15))),
                      for (final p in _pieces)
                        _PieceView(
                          key: ValueKey(p.uid),
                          piece: p,
                          stage: _stage,
                          unit: u,
                          lifted: _dragging == p.uid,
                          spin: meshing.contains(p.uid) ? _spin : null,
                          spinReverse: meshing.contains(p.uid) && (_pieces.indexOf(p).isOdd),
                          onStart: () {
                            HapticFeedback.selectionClick();
                            setState(() => _dragging = p.uid);
                          },
                          onMove: (d) => _move(p, d),
                          onEnd: () => _endMove(p),
                          onTap: () => _rotate(p),
                        ),
                      if (_pieces.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(PSpace.xl),
                            child: PCard(
                              child: Text(
                                'قطعه‌ها را از جعبه‌ی پایین بکش و اینجا بگذار',
                                style: Theme.of(context).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      PositionedDirectional(
                        top: PSpace.sm,
                        start: PSpace.sm,
                        child: AnimatedScale(
                          key: _trashKey,
                          scale: _overTrash ? 1.25 : (_dragging != null ? 1.1 : 1),
                          duration: PMotion.tap,
                          child: Semantics(
                            label: 'سطل: قطعه را اینجا بکش تا برداشته شود',
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: _overTrash ? PColors.danger : Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: PShadow.soft(),
                              ),
                              child: Icon(Icons.delete_rounded, size: 34, color: _overTrash ? Colors.white : PColors.danger),
                            ),
                          ),
                        ),
                      ),
                      const CaptionBubble(alignment: Alignment.bottomCenter),
                      PositionedDirectional(
                        end: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: PopoMascot(
                            pose: meshing.isNotEmpty ? PopoPose.happy : PopoPose.curious,
                            size: u * .26,
                            reducedMotion: reduced,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          _Palette(unit: MediaQuery.sizeOf(context).shortestSide),
        ],
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette({required this.unit});

  final double unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: PShadow.soft()),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(PSpace.xs),
            children: [
              for (final k in pieceKinds)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Draggable<String>(
                    data: k.id,
                    onDragStarted: HapticFeedback.selectionClick,
                    feedback: Material(
                      color: Colors.transparent,
                      child: SizedBox(
                        width: k.w * unit * .7,
                        height: k.h * unit * .7,
                        child: PieceArt(kind: k),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: .4, child: _paletteTile(k)),
                    child: _paletteTile(k),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paletteTile(PieceKind k) => Semantics(
    label: '${k.label}؛ بکش و روی زمین بگذار',
    child: Container(
      width: 84,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: PColors.background, borderRadius: BorderRadius.circular(PRadius.md)),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: k.w / k.h,
                child: PieceArt(kind: k),
              ),
            ),
          ),
          Text(
            k.label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

class PieceArt extends StatelessWidget {
  const PieceArt({super.key, required this.kind});

  final PieceKind kind;

  @override
  Widget build(BuildContext context) {
    if (kind.art != null) return ArtImage(kind.art!, fit: BoxFit.contain);
    return CustomPaint(painter: _BlockPainter(kind.shape!, kind.color!), size: Size.infinite);
  }
}

class _BlockPainter extends CustomPainter {
  _BlockPainter(this.shape, this.color);

  final BlockShape shape;
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    final fill = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.4, -.5),
        radius: 1.2,
        colors: [PColors.tint(color, .12), color, PColors.shade(color, .1)],
      ).createShader(r);
    final edge = Paint()
      ..color = PColors.shade(color, .2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, s.shortestSide * .05)
      ..strokeJoin = StrokeJoin.round;
    final d = r.deflate(edge.strokeWidth);
    final path = switch (shape) {
      BlockShape.square || BlockShape.long => Path()..addRRect(RRect.fromRectAndRadius(d, Radius.circular(d.shortestSide * .18))),
      BlockShape.round => Path()..addOval(d),
      BlockShape.triangle =>
        Path()
          ..moveTo(d.center.dx, d.top)
          ..lineTo(d.right, d.bottom)
          ..lineTo(d.left, d.bottom)
          ..close(),
      BlockShape.arch =>
        Path()
          ..moveTo(d.left, d.bottom)
          ..lineTo(d.left, d.top + d.height * .2)
          ..quadraticBezierTo(d.left, d.top, d.left + d.width * .15, d.top)
          ..lineTo(d.right - d.width * .15, d.top)
          ..quadraticBezierTo(d.right, d.top, d.right, d.top + d.height * .2)
          ..lineTo(d.right, d.bottom)
          ..lineTo(d.right - d.width * .25, d.bottom)
          ..arcToPoint(Offset(d.left + d.width * .25, d.bottom), radius: Radius.circular(d.width * .25), clockwise: false)
          ..close(),
    };
    c.drawPath(path, fill);
    c.drawPath(path, edge);
    c.drawOval(
      Rect.fromLTWH(d.left + d.width * .15, d.top + d.height * .12, d.width * .3, d.height * .18),
      Paint()..color = Colors.white.withValues(alpha: .4),
    );
  }

  @override
  bool shouldRepaint(_BlockPainter old) => old.shape != shape || old.color != color;
}

class _PieceView extends StatelessWidget {
  const _PieceView({
    super.key,
    required this.piece,
    required this.stage,
    required this.unit,
    required this.lifted,
    required this.spin,
    required this.spinReverse,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.onTap,
  });

  final BuildPiece piece;
  final Size stage;
  final double unit;
  final bool lifted;
  final Animation<double>? spin;
  final bool spinReverse;
  final VoidCallback onStart;
  final ValueChanged<Offset> onMove;
  final VoidCallback onEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = kindOf(piece.kind) ?? pieceKinds.first;
    final w = k.w * unit, h = k.h * unit;
    Widget art = SizedBox(
      width: w,
      height: h,
      child: PieceArt(kind: k),
    );
    final s = spin;
    if (s != null) {
      art = RotationTransition(turns: spinReverse ? ReverseAnimation(s) : s, child: art);
    } else {
      art = AnimatedRotation(turns: piece.rotation / 4, duration: PMotion.quick, child: art);
    }
    return Positioned(
      left: piece.x * stage.width - w / 2,
      top: piece.y * stage.height - h / 2,
      child: Semantics(
        button: true,
        label: '${k.label}؛ لمس برای چرخاندن، کشیدن برای جابه‌جایی',
        child: GestureDetector(
          onTap: onTap,
          onPanStart: (_) => onStart(),
          onPanUpdate: (d) => onMove(d.delta),
          onPanEnd: (_) => onEnd(),
          onPanCancel: onEnd,
          child: AnimatedScale(scale: lifted ? 1.1 : 1, duration: PMotion.tap, child: art),
        ),
      ),
    );
  }
}
