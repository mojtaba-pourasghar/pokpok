import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';

/// تنظیمات نمایه‌ی فعال: هر کانال صدا جدا، زبان، حرکت و دسترس‌پذیری.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final profile = ref.watch(activeProfileProvider);
    Widget channel(
      IconData icon,
      String title,
      bool on,
      double v,
      Color color,
      ProfileSettings Function(ProfileSettings, bool) setOn,
      ProfileSettings Function(ProfileSettings, double) setV,
    ) {
      return Column(
        children: [
          SettingRow(
            icon: icon,
            title: title,
            color: color,
            trailing: Switch(value: on, onChanged: (x) => n.update((s) => setOn(s, x))),
          ),
          if (on)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 56),
              child: Semantics(
                label: 'بلندی $title',
                child: Slider(
                  value: v,
                  activeColor: color,
                  onChanged: (x) => n.update((s) => setV(s, x)),
                  onChangeEnd: (_) => ref.read(audioProvider).ui(UiSound.tap),
                ),
              ),
            ),
        ],
      );
    }

    return PScaffold(
      title: 'تنظیمات',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          if (profile != null)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpace.sm),
              child: Text('برای «${profile.name}»؛ هر نمایه تنظیمات خودش را دارد.', style: PText.caption),
            ),
          _Section(
            title: 'صدا',
            children: [
              channel(
                Icons.music_note_rounded,
                'موسیقی پس‌زمینه',
                s.musicOn,
                s.music,
                PColors.purple,
                (s, x) => s.copyWith(musicOn: x),
                (s, x) => s.copyWith(music: x),
              ),
              channel(
                Icons.touch_app_rounded,
                'جلوه‌های صوتی',
                s.effectsOn,
                s.effects,
                PColors.orange,
                (s, x) => s.copyWith(effectsOn: x),
                (s, x) => s.copyWith(effects: x),
              ),
              channel(
                Icons.forest_rounded,
                'صدای محیط',
                s.ambientOn,
                s.ambient,
                PColors.success,
                (s, x) => s.copyWith(ambientOn: x),
                (s, x) => s.copyWith(ambient: x),
              ),
              channel(
                Icons.record_voice_over_rounded,
                'صدای پوپو',
                s.voiceOn,
                s.voice,
                PColors.blue,
                (s, x) => s.copyWith(voiceOn: x),
                (s, x) => s.copyWith(voice: x),
              ),
            ],
          ),
          const _Section(
            title: 'زبان',
            children: [
              SettingRow(
                icon: Icons.translate_rounded,
                title: 'فارسی',
                subtitle: 'زبان‌های دیگر در نسخه‌های بعد',
                color: PColors.turquoise,
                trailing: Icon(Icons.check_circle_rounded, color: PColors.success),
              ),
            ],
          ),
          _Section(
            title: 'حرکت و دسترس‌پذیری',
            children: [
              SettingRow(
                icon: Icons.animation_rounded,
                title: 'حرکت کمتر',
                subtitle: 'پوپو و اشیا آرام‌تر و کم‌حرکت‌تر می‌شوند',
                color: PColors.pink,
                trailing: Switch(
                  value: s.reducedMotion,
                  onChanged: (x) => n.update((s) => s.copyWith(reducedMotion: x)),
                ),
              ),
              SettingRow(
                icon: Icons.format_size_rounded,
                title: 'متن درشت',
                color: PColors.blue,
                trailing: Switch(
                  value: s.largeText,
                  onChanged: (x) => n.update((s) => s.copyWith(largeText: x)),
                ),
              ),
              SettingRow(
                icon: Icons.closed_caption_rounded,
                title: 'زیرنویس حرف‌های پوپو',
                subtitle: 'برای وقتی که صدا خاموش است',
                color: PColors.orange,
                trailing: Switch(
                  value: s.captions,
                  onChanged: (x) => n.update((s) => s.copyWith(captions: x)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: PSpace.md),
    child: PCard(
      padding: const EdgeInsets.all(PSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(PSpace.xs),
            child: Text(title, style: PText.heading),
          ),
          ...children,
        ],
      ),
    ),
  );
}
