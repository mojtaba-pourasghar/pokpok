import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/theme.dart';
import '../../../ui/clay.dart';
import '../../../ui/fx.dart';
import '../../mascot/popo_mascot.dart';
import 'scene_base.dart';

/// ساز: نواختنی واقعی. طبل با ضربه له و کش می‌شود و صدای بم می‌دهد؛ زایلوفون تیغه‌های رنگی بلند به
/// کوتاه با نت‌های زیرتر دارد؛ نی سوراخ‌هایی دارد که نت را عوض می‌کنند. از هر ضربه نت‌ها بالا می‌روند و
/// پوپو با آهنگ تکان می‌خورد. آهنگ و کنسرت: هر دوست را لمس کن تا سازش را بزند.
class MusicScene extends ShowcaseScene {
  const MusicScene({super.key, required super.item, super.friend, super.onTry, super.auto, super.play});

  @override
  ConsumerState<MusicScene> createState() => _MusicSceneState();
}

class _MusicSceneState extends ConsumerState<MusicScene> with SceneBase {
  static const _xylo = ['c4', 'e4', 'g4', 'c5'];
  static const _bars = [Color(0xFFF44336), Color(0xFFFF9800), Color(0xFF4CAF50), Color(0xFF2196F3)];
  final _keys = List.generate(6, (_) => GlobalKey());
  final List<int> hits = List.filled(6, 0);
  int dance = 0;
  int _auto = 0;

  String get id => widget.item.id;
  bool get band => widget.item.kind == 'song';

  /// (تصویر، صدا) برای هر پد.
  List<(String, String)> get pads => switch (id) {
    'drum' => [('drum', 'audio/instruments/drum_tom.mp3')],
    'xylophone' => [for (final n in _xylo) ('bar_red', 'audio/instruments/xylo_$n.mp3')],
    'flute' => [for (var k = 0; k < 4; k++) ('flute', 'audio/instruments/flute.mp3')],
    _ => [
      ('drum', 'audio/instruments/drum_tom.mp3'),
      ('xylophone', 'audio/instruments/xylo_e4.mp3'),
      ('flute', 'audio/instruments/flute.mp3'),
    ],
  };

  @override
  void initState() {
    super.initState();
    autoPlay(() => _play(_auto++ % pads.length), every: const Duration(milliseconds: 520));
  }

  void _play(int i) {
    sfx(pads[i].$2);
    burstAt(_keys[i], Fx.notes, count: 3, offset: const Offset(0, -20));
    setState(() {
      hits[i]++;
      dance++;
    });
    if (dance % 4 == 0) tried();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final s = math.min(box.maxWidth, box.maxHeight);
      final p = pads;
      return Stack(
        children: [
          Positioned(
            left: 0,
            bottom: 0,
            child: Squash(
              trigger: dance,
              amount: .08,
              child: PopoMascot(pose: dance.isOdd ? PopoPose.happy : PopoPose.curious, size: s * .36),
            ),
          ),
          if (widget.play && widget.friend != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: Squash(
                trigger: dance ~/ 2,
                amount: .08,
                child: GameArt(widget.friend!, size: s * .32),
              ),
            ),
          Align(
            alignment: const Alignment(0, -.2),
            child: switch (id) {
              'xylophone' => _xylophone(s),
              'flute' => _flute(s),
              'drum' => _pad(0, 'drum', s * .55),
              _ => Wrap(spacing: 14, children: [for (var i = 0; i < p.length; i++) _pad(i, p[i].$1, s * .3)]),
            },
          ),
          if (tries == 0 && dance == 0 && !widget.auto) const Positioned(top: 8, left: 0, right: 0, child: Center(child: _TapMe())),
        ],
      );
    },
  );

  Widget _pad(int i, String art, double size) => GestureDetector(
    onTap: () => _play(i),
    child: Squash(
      key: _keys[i],
      trigger: hits[i],
      amount: .18,
      alignment: Alignment.center,
      child: GameArt(art, size: size),
    ),
  );

  /// چهار تیغه‌ی رنگی از بلند (بم) به کوتاه (زیر).
  Widget _xylophone(double s) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      for (var i = 0; i < 4; i++)
        GestureDetector(
          onTap: () => _play(i),
          child: Squash(
            key: _keys[i],
            trigger: hits[i],
            amount: .12,
            alignment: Alignment.center,
            child: Container(
              width: s * .14,
              height: s * (.55 - i * .08),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: _bars[i],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: G.soft(),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 8, child: CircleAvatar(radius: 4, backgroundColor: Colors.white70)),
                  Text(const ['بم', '', '', 'زیر'][i], style: PText.label.copyWith(color: Colors.white)),
                  const SizedBox(height: 8, child: CircleAvatar(radius: 4, backgroundColor: Colors.white70)),
                ],
              ),
            ),
          ),
        ),
    ],
  );

  /// نی با چهار سوراخ؛ هر سوراخ یک نت.
  Widget _flute(double s) => Stack(
    alignment: Alignment.center,
    children: [
      GameArt('flute', size: s * .8),
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            GestureDetector(
              onTap: () => _play(i),
              child: AnimatedContainer(
                key: _keys[i],
                duration: const Duration(milliseconds: 120),
                width: 44,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hits[i].isOdd ? G.purple : Colors.white,
                  border: Border.all(color: G.purple, width: 4),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _TapMe extends StatelessWidget {
  const _TapMe();

  @override
  Widget build(BuildContext context) => PopIn(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: G.soft()),
      child: Text('بزن تا صدا بدهد!', style: PText.heading.copyWith(color: G.purple)),
    ),
  );
}
