import 'package:flutter/foundation.dart';

import '../../data/models/models.dart';
import '../content/content.dart';

/// رابط پخش صدا. صفحه‌ها فقط با همین رابط کار می‌کنند تا پیاده‌سازی واقعی (just_audio)
/// در تست‌ها با نسخه‌ی بی‌صدا جایگزین شود.
///
/// کانال‌ها جدا هستند و هر کدام بلندی و کلید خاموش/روشن خودش را دارد:
///   موسیقی پس‌زمینه، جلوه‌های صوتی (اشیا، رابط، سازها)، صدای محیط، گوینده.
abstract class PopoAudio {
  /// جمله‌ای که پوپو همین حالا می‌گوید؛ برای حباب زیرنویس.
  ValueListenable<VoiceLine?> get caption;

  ProfileSettings get settings;
  set settings(ProfileSettings s);

  /// پخش جمله‌ی گوینده. اگر فایلش هنوز ضبط نشده باشد، فقط زیرنویس نشان داده می‌شود.
  Future<void> say(VoiceLine? line);

  /// یک جلوه‌ی صوتی (چندصدایی: صداهای پشت سر هم روی هم پخش می‌شوند).
  void play(String logicalPath, {double volume = 1});

  void ui(UiSound sound);

  /// صداهایی که به‌زودی لازم می‌شوند از پیش بارگذاری می‌شوند تا اولین پخش هم بی‌تأخیر باشد.
  void preload(Iterable<String> logicalPaths);

  void startMusic(String logicalPath);
  void stopMusic();

  void startAmbient(String logicalPath);
  void stopAmbient();

  /// گوینده را نرم قطع می‌کند. جلوه‌ها تا آخر پخش می‌شوند؛ موسیقی و صدای محیط می‌مانند.
  void stopAll();

  void dispose();
}

enum UiSound {
  tap('audio/ui/tap.mp3'),
  pop('audio/ui/pop.mp3'),
  success('audio/ui/success.mp3'),
  sparkle('audio/ui/sparkle.mp3'),
  whoosh('audio/ui/whoosh.mp3'),
  toggle('audio/ui/toggle.mp3'),
  softNo('audio/ui/soft_no.mp3'),
  chime('audio/ui/chime.mp3'),
  page('audio/ui/page.mp3'),
  camera('audio/ui/camera.mp3');

  const UiSound(this.path);
  final String path;
}

/// پیاده‌سازی بی‌صدا برای تست‌ها: صدایی پخش نمی‌کند ولی همه‌چیز را ثبت می‌کند.
/// زیرنویس فقط با [captions] نشان داده می‌شود، تا حباب همیشه‌حاضر چیدمان صفحه را پنهان نکند.
class SilentAudio implements PopoAudio {
  SilentAudio({this.captions = false});

  final bool captions;

  final _caption = ValueNotifier<VoiceLine?>(null);
  final List<String> log = [];

  @override
  ProfileSettings settings = const ProfileSettings();

  @override
  ValueListenable<VoiceLine?> get caption => _caption;

  @override
  Future<void> say(VoiceLine? line) async {
    if (line == null) return;
    log.add('say:${line.id}');
    if (captions) _caption.value = line;
  }

  @override
  void play(String logicalPath, {double volume = 1}) {
    if (settings.volume(AudioChannel.effects) > 0) log.add('play:$logicalPath');
  }

  @override
  void ui(UiSound sound) => log.add('ui:${sound.name}');
  @override
  void preload(Iterable<String> logicalPaths) {}
  @override
  void startMusic(String logicalPath) => log.add('music:$logicalPath');
  @override
  void stopMusic() => log.add('music:stop');
  @override
  void startAmbient(String logicalPath) => log.add('ambient:$logicalPath');
  @override
  void stopAmbient() => log.add('ambient:stop');
  @override
  void stopAll() {
    log.add('stopAll');
    _caption.value = null;
  }

  @override
  void dispose() => _caption.dispose();
}
