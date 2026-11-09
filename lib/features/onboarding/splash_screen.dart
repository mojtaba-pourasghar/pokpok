import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../mascot/popo_loader.dart';
import '../mascot/popo_mascot.dart';
import '../../ui/clay.dart';

/// صفحه‌ی شروع: اول خودِ پوپو «بارگذاری» است (ادامه‌ی همان اسپلشِ اندروید)، بعد پوپوی
/// دست‌تکان‌دهنده، دکمه‌ی بزرگ شروع و دکمه‌ی جدای والدین.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// کمترین زمانِ نمایشِ بارگذاری، تا پرشِ پوپو دیده شود و صفحه چشمک نزند.
  static const minLoading = Duration(milliseconds: 900);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // صداهای صفحه‌ی بعد همین حالا آماده می‌شوند تا اولین لمس بی‌تأخیر باشد.
    ref.read(audioProvider).preload(const ['audio/ui/tap.mp3', 'audio/ui/pop.mp3']);
    await Future<void>.delayed(SplashScreen.minLoading);
    if (!mounted) return;
    setState(() => _ready = true);
    ref.read(audioProvider).startMusic('audio/music/menu_loop.ogg');
    unawaited(ref.say('app.splash.welcome'));
  }

  Future<void> _start() async {
    await ref.read(profilesProvider.notifier).ensureOne();
    if (!mounted) return;
    if (!ref.read(appPrefsProvider).introSeen) {
      context.go('/intro');
    } else if (ref.read(profilesProvider).profiles.length > 1) {
      context.go('/profiles');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    return Scaffold(
      body: AnimatedSwitcher(
        duration: PMotion.slow,
        switchInCurve: PMotion.enter,
        child: _ready ? _welcome(reduced) : PopoLoader(key: const ValueKey('loading'), reducedMotion: reduced),
      ),
    );
  }

  Widget _welcome(bool reduced) {
    return Stack(
      key: const ValueKey('welcome'),
      children: [
        const Positioned.fill(child: SkyScene(scene: 'meadow')),
        SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final h = box.maxHeight;
              final wide = box.maxWidth > box.maxHeight * 1.1;
              final mascot = PopoMascot(pose: PopoPose.welcome, size: (wide ? h * .7 : h * .46).clamp(160, 420), reducedMotion: reduced);
              final start = PButton(label: 'شروع بازی', icon: Icons.play_arrow_rounded, big: true, color: PColors.blue, onPressed: _start);
              final parent = Padding(
                padding: const EdgeInsets.only(top: PSpace.sm),
                child: TextButton.icon(
                  onPressed: () => context.go('/parent'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: .9),
                    minimumSize: const Size(PTouch.min * 2, PTouch.min - 8),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.lock_rounded, color: PColors.inkSoft),
                  label: const Text(
                    'ورود والدین',
                    style: TextStyle(color: PColors.ink, fontWeight: FontWeight.w700),
                  ),
                ),
              );
              if (wide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [start, parent]),
                    mascot,
                  ],
                );
              }
              return Column(
                children: [
                  const Spacer(),
                  mascot,
                  const Spacer(),
                  start,
                  parent,
                  SizedBox(height: h * .04),
                ],
              );
            },
          ),
        ),
        const SafeArea(child: CaptionBubble(alignment: Alignment.topCenter)),
      ],
    );
  }
}
