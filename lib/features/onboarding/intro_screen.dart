import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../mascot/popo_mascot.dart';
import '../../ui/clay.dart';

/// آشنایی با پوپو در سه گام کوتاه و تعاملی. هر گام یک کار واقعی از کودک می‌خواهد
/// (لمس کردن، کشیدن) و می‌شود کل آن را رد کرد. ثبت‌نامی در کار نیست.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  int _page = 0;
  bool _tapped = false;
  Offset _ball = const Offset(.25, .8);
  bool _ballHome = false;

  static const _lines = ['app.intro.1', 'app.intro.2', 'app.intro.3'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.say(_lines[0]));
  }

  Future<void> _finish() async {
    await ref.read(appPrefsProvider).setIntroSeen();
    if (!mounted) return;
    context.go(ref.read(profilesProvider).profiles.length > 1 ? '/profiles' : '/home');
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    setState(() => _page++);
    ref.say(_lines[_page]);
  }

  bool get _done => _page == 0 || (_page == 1 && _tapped) || (_page == 2 && _ballHome);

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    final pose = switch (_page) {
      0 => PopoPose.welcome,
      1 => _tapped ? PopoPose.happy : PopoPose.pointing,
      _ => _ballHome ? PopoPose.happy : PopoPose.curious,
    };
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: SkyScene(scene: 'meadow')),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final u = box.biggest.shortestSide;
                return Stack(
                  children: [
                    PositionedDirectional(
                      top: PSpace.sm,
                      end: PSpace.md,
                      child: TextButton(
                        onPressed: _finish,
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .9),
                          minimumSize: const Size(96, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'رد کردن',
                          style: TextStyle(fontWeight: FontWeight.w800, color: PColors.ink),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -.15),
                      child: GestureDetector(
                        onTap: () {
                          ref.read(audioProvider).ui(UiSound.sparkle);
                          if (_page == 1) setState(() => _tapped = true);
                        },
                        child: PopoMascot(pose: pose, size: u * .55, reducedMotion: reduced),
                      ),
                    ),
                    if (_page == 2) ..._dragGame(box.biggest, u),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: PSpace.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var i = 0; i < 3; i++)
                                  AnimatedContainer(
                                    duration: PMotion.quick,
                                    margin: const EdgeInsets.all(4),
                                    width: i == _page ? 26 : 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: i == _page ? PColors.orange : Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: PSpace.sm),
                            AnimatedOpacity(
                              opacity: _done ? 1 : .5,
                              duration: PMotion.quick,
                              child: PButton(
                                label: _page == 2 ? 'بزن بریم!' : 'بعدی',
                                icon: Icons.arrow_back_rounded,
                                color: PColors.orange,
                                onPressed: _done ? _next : null,
                              ),
                            ),
                            if (!_done) ...[
                              const SizedBox(height: PSpace.xs),
                              Text(_page == 1 ? 'پوپو را لمس کن' : 'توپ را تا پوپو بکش', style: PText.bodyStrong),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SafeArea(child: CaptionBubble()),
        ],
      ),
    );
  }

  List<Widget> _dragGame(Size size, double u) {
    final s = u * .16;
    return [
      Positioned(
        left: _ball.dx * size.width - s / 2,
        top: _ball.dy * size.height - s / 2,
        child: Semantics(
          button: true,
          label: 'توپ؛ آن را تا پوپو بکش',
          onTap: () => setState(() {
            _ball = const Offset(.5, .45);
            _ballHome = true;
          }),
          child: GestureDetector(
            onPanUpdate: (d) => setState(() {
              _ball = Offset(
                ((_ball.dx * size.width + d.delta.dx) / size.width).clamp(.05, .95),
                ((_ball.dy * size.height + d.delta.dy) / size.height).clamp(.1, .9),
              );
            }),
            onPanEnd: (_) {
              if ((_ball - const Offset(.5, .45)).distance < .2) {
                setState(() => _ballHome = true);
                ref.read(audioProvider).ui(UiSound.success);
              }
            },
            child: ArtImage('ball', size: s),
          ),
        ),
      ),
    ];
  }
}
