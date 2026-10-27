import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/logo.dart';
import '../mascot/popo_mascot.dart';
import '../../ui/clay.dart';

/// صفحه‌ی شروع: نشان پوپو، پوپوی دست‌تکان‌دهنده، دکمه‌ی بزرگ شروع و دکمه‌ی جدای والدین.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioProvider).startMusic('audio/music/menu_loop.mp3');
      ref.say('app.splash.welcome');
    });
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
      body: Stack(
        children: [
          const Positioned.fill(child: SkyScene(image: 'art/backgrounds/meadow.webp')),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, box) {
                final h = box.maxHeight;
                final wide = box.maxWidth > box.maxHeight * 1.1;
                final mascot = PopoMascot(pose: PopoPose.welcome, size: (wide ? h * .62 : h * .36).clamp(140, 380), reducedMotion: reduced);
                final logo = PopoLogo(size: (wide ? h * .16 : box.maxWidth * .2).clamp(48, 96));
                final start = PButton(
                  label: 'شروع بازی',
                  icon: Icons.play_arrow_rounded,
                  big: true,
                  color: PColors.blue,
                  onPressed: _start,
                );
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          logo,
                          const SizedBox(height: PSpace.lg),
                          start,
                          parent,
                        ],
                      ),
                      mascot,
                    ],
                  );
                }
                return Column(
                  children: [
                    SizedBox(height: h * .05),
                    logo,
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
      ),
    );
  }
}
