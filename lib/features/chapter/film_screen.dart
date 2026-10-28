import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../game/engines/engine.dart';
import '../../game/game_data.dart';
import '../../game/game_state.dart';
import '../../ui/clay.dart';
import '../../ui/fx.dart';
import '../mascot/popo_mascot.dart';
import '../play/discover.dart';

/// فیلم پایان فصل: هر چیزی که در فصل ساخته شد کار می‌کند (با صدا و مزه)، بعد مشکل فصل حل می‌شود،
/// یک تکه‌ی نقشه‌ی جشن روشن می‌شود و دوست فصل بعد پیدا می‌شود.
class FilmScreen extends ConsumerStatefulWidget {
  const FilmScreen({super.key, required this.chapterId});

  final String chapterId;

  @override
  ConsumerState<FilmScreen> createState() => _FilmScreenState();
}

class _FilmScreenState extends ConsumerState<FilmScreen> {
  late final GameData data = ref.read(gameDataProvider);
  late final ChapterDef chapter = data.chapter(widget.chapterId);
  late final _audio = ref.read(audioProvider);

  /// صحنه‌ها: یکی برای هر بخش، بعد نقشه، بعد پیش‌نمایش فصل بعد.
  int scene = 0;
  Timer? _timer;
  bool paused = false;

  int get total => chapter.sections.length + (chapter.next.isEmpty ? 1 : 2);

  @override
  void initState() {
    super.initState();
    _audio;
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audio.stopAll();
    super.dispose();
  }

  Future<void> _play() async {
    if (!mounted) return;
    final n = chapter.sections.length;
    if (scene < n) {
      unawaited(ref.say('${chapter.id}.film.${scene + 1}'));
    } else if (scene == n) {
      _audio.ui(UiSound.success);
      unawaited(ref.read(gameProvider.notifier).sawFilm(chapter.id));
      unawaited(ref.say('film.end'));
    } else {
      unawaited(ref.say('${chapter.id}.next'));
    }
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 4200), _advance);
  }

  void _advance() {
    if (!mounted) return;
    if (scene + 1 >= total) {
      _timer?.cancel();
      return;
    }
    setState(() => scene++);
    _play();
  }

  @override
  Widget build(BuildContext context) {
    final n = chapter.sections.length;
    final last = scene >= total - 1;
    return Scaffold(
      body: FxLayer(
        child: SkyScene(
          image: chapter.background,
          night: chapter.night,
          dim: .2,
          child: SafeArea(
            child: Column(
              children: [
                GameTopBar(
                  title: 'فیلم: ${chapter.title}',
                  light: true,
                  onBack: () => context.go('/chapter/${chapter.id}'),
                  trailing: const SizedBox.shrink(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: StepDots(done: scene + 1, total: total),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: _advance,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: KeyedSubtree(key: ValueKey(scene), child: _scene(n)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: last
                      ? ClayButton(
                          label: chapter.next.isEmpty ? 'تمام! برگردیم خانه' : 'برویم سراغ فصل بعد',
                          icon: Icons.arrow_back_rounded,
                          color: G.green,
                          big: true,
                          onTap: () {
                            final i = chapter.index + 1;
                            context.go(i < data.chapters.length ? '/chapter/${data.chapters[i].id}' : '/home');
                          },
                        )
                      : ClayButton(label: 'بعدی', icon: Icons.skip_previous_rounded, color: G.purple, onTap: _advance),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene(int n) {
    if (scene < n) {
      final s = chapter.sections[scene];
      final item = data.item(s.makes);
      return Container(
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(32), boxShadow: G.soft()),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SectionPill(item.title, color: G.hex(chapter.color)),
            const SizedBox(height: 8),
            Text(
              chapter.film.length > scene ? chapter.film[scene] : item.use,
              style: PText.title.copyWith(color: G.purple),
              textAlign: TextAlign.center,
            ),
            Expanded(child: ItemShowcase(item: item, auto: true, friend: null)),
          ],
        ),
      );
    }
    if (scene == n) {
      return ClayCard(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${data.friend(chapter.friend).name} خوشحال است!', style: PText.title.copyWith(color: G.purple)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GameArt(chapter.friend, size: 140),
                const PopoMascot(pose: PopoPose.happy, size: 140),
              ],
            ),
            const SizedBox(height: 12),
            const Text('یک تکه‌ی تازه از نقشه‌ی جشن روشن شد!', style: PText.heading, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final c in data.chapters)
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: c.index <= chapter.index ? 1 : 0),
                      duration: Duration(milliseconds: 600 + c.index * 120),
                      builder: (context, v, _) => Container(
                        height: 46,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Color.lerp(G.line, G.hex(c.color), v), borderRadius: BorderRadius.circular(10)),
                        alignment: Alignment.center,
                        child: c.index <= chapter.index ? Text(data.friend(c.friend).emoji, style: const TextStyle(fontSize: 20)) : null,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }
    final next = data.chapters[chapter.index + 1];
    return ClayCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('فصل بعد', style: PText.caption),
          Text(next.title, style: PText.title.copyWith(color: G.hex(next.color))),
          const SizedBox(height: 12),
          GameArt(next.friend, size: 180),
          const SizedBox(height: 12),
          Text(chapter.next, style: PText.heading, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
