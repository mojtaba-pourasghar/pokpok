import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

import '../../data/models/models.dart';
import '../assets/asset_resolver.dart';
import '../content/content.dart';
import 'popo_audio.dart';

/// پخش واقعی صدا با just_audio.
///
/// - **جلوه‌ها هیچ‌وقت هم را قطع نمی‌کنند:** هر صدا پخش‌کننده‌های خودش را دارد که یک بار بارگذاری
///   می‌شوند و بعد فقط از اول پخش می‌شوند (بی‌تأخیر). اگر همان صدا پشت سر هم زده شود (ضربه‌های چکش)،
///   تا [_voicesPerSound] نسخه روی هم شنیده می‌شوند. با رفتن از صفحه هم جلوه‌ها تا آخر پخش می‌شوند.
/// - **موسیقی و صدای محیط** آرام بالا و پایین می‌روند (fade)، نه ناگهانی؛ رفتن از صفحه‌ای به صفحه‌ی
///   دیگر با همان صدای محیط آن را از نو شروع نمی‌کند.
/// - حلقه‌ها OGG بی‌درزند (tools/sfx/make_loops.py)، پس سر هر دور مکث یا تق نیست.
/// - هنگام حرف زدن پوپو، موسیقی و صدای محیط نرم پایین می‌آیند.
class JustAudioService with WidgetsBindingObserver implements PopoAudio {
  JustAudioService(this._assets) {
    WidgetsBinding.instance.addObserver(this);
  }

  static const _voicesPerSound = 3;
  static const _maxSounds = 24;

  final AssetResolver _assets;

  /// صدا ← پخش‌کننده‌های آماده‌اش (به ترتیب آخرین استفاده؛ قدیمی‌ترها آزاد می‌شوند).
  final Map<String, _SoundSlot> _sounds = {};
  final _voice = AudioPlayer();
  final _music = _Loop();
  final _ambient = _Loop();
  final _caption = ValueNotifier<VoiceLine?>(null);
  int _gen = 0;
  bool _ducked = false;
  ProfileSettings _settings = const ProfileSettings();

  @override
  ValueListenable<VoiceLine?> get caption => _caption;

  @override
  ProfileSettings get settings => _settings;

  @override
  set settings(ProfileSettings s) {
    _settings = s;
    _apply();
  }

  double _vol(AudioChannel c) => _settings.volume(c);

  AudioSource? _source(String logicalPath) {
    final r = _assets.resolve(logicalPath);
    if (r == null) return null;
    return r.source == AssetSource.bundled ? AudioSource.asset(r.key) : AudioSource.file(r.key);
  }

  // ── گوینده ─────────────────────────────────────────────────────────────
  @override
  Future<void> say(VoiceLine? line) async {
    if (line == null) return;
    final gen = ++_gen;
    if (_voice.playing) await _fade(_voice, to: 0, ms: 120);
    await _voice.stop();
    if (line.delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: line.delayMs));
      if (gen != _gen) return;
    }
    _caption.value = line;
    final path = 'audio/${line.file}';
    final src = _vol(AudioChannel.voice) > 0 && _assets.exists(path) ? _source(path) : null;
    var played = false;
    if (src != null) {
      try {
        await _voice.setAudioSource(src);
        if (gen == _gen) {
          _duck(true);
          await _voice.setVolume(_vol(AudioChannel.voice));
          await _voice.play();
          played = true;
        }
      } catch (e) {
        debugPrint('پخش گوینده شکست خورد: $e');
      }
      if (gen == _gen) _duck(false);
    }
    if (!played) {
      // هنوز صدای ضبط‌شده نیست (یا گوینده خاموش است): زمانی شبیه خواندن جمله صبر می‌کنیم
      // تا کودک زیرنویس را ببیند.
      await Future<void>.delayed(Duration(milliseconds: min(3200, max(1600, line.text.length * 65))));
    }
    if (gen == _gen && identical(_caption.value, line)) _caption.value = null;
  }

  // ── جلوه‌ها ───────────────────────────────────────────────────────────
  @override
  void play(String logicalPath, {double volume = 1}) {
    final v = _vol(AudioChannel.effects) * volume;
    if (v <= 0) return;
    final slot = _sounds.remove(logicalPath) ?? _SoundSlot();
    _sounds[logicalPath] = slot; // تازه‌ترین در انتها
    _evict();
    unawaited(slot.play(() => _source(logicalPath), v));
  }

  /// صداهای کم‌استفاده آزاد می‌شوند تا حافظه‌ی گوشی‌های ضعیف پر نشود.
  void _evict() {
    while (_sounds.length > _maxSounds) {
      final oldest = _sounds.keys.first;
      _sounds.remove(oldest)!.dispose();
    }
  }

  @override
  void preload(Iterable<String> paths) {
    for (final p in paths) {
      if (_sounds.containsKey(p)) continue;
      final slot = _SoundSlot();
      _sounds[p] = slot;
      unawaited(slot.prepare(() => _source(p)));
    }
    _evict();
  }

  @override
  void ui(UiSound sound) => play(sound.path, volume: .7);

  // ── موسیقی و صدای محیط ─────────────────────────────────────────────────
  double get _musicVolume => _vol(AudioChannel.music) * (_ducked ? .3 : 1);
  double get _ambientVolume => _vol(AudioChannel.ambient) * .7 * (_ducked ? .55 : 1);

  @override
  void startMusic(String logicalPath) => _music.start(logicalPath, _source, _musicVolume);

  @override
  void stopMusic() => _music.stop();

  @override
  void startAmbient(String logicalPath) => _ambient.start(logicalPath, _source, _ambientVolume);

  @override
  void stopAmbient() => _ambient.stop();

  void _duck(bool on) {
    if (_ducked == on) return;
    _ducked = on;
    _music.setVolume(_musicVolume);
    _ambient.setVolume(_ambientVolume);
  }

  /// فقط گوینده قطع می‌شود (نرم). جلوه‌ها، موسیقی و صدای محیط ادامه می‌دهند.
  @override
  void stopAll() {
    _gen++;
    _caption.value = null;
    if (_voice.playing) {
      unawaited(_fade(_voice, to: 0, ms: 150).then((_) => _voice.stop()));
    }
    _duck(false);
  }

  void _apply() {
    if (_vol(AudioChannel.voice) <= 0) _voice.stop();
    if (_vol(AudioChannel.effects) <= 0) {
      for (final s in _sounds.values) {
        s.stop();
      }
    }
    _music.setVolume(_musicVolume);
    _ambient.setVolume(_ambientVolume);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        stopAll();
        _music.pause();
        _ambient.pause();
      case AppLifecycleState.resumed:
        _music.resume();
        _ambient.resume();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voice.dispose();
    _music.dispose();
    _ambient.dispose();
    for (final s in _sounds.values) {
      s.dispose();
    }
    _caption.dispose();
  }
}

/// پخش‌کننده‌های یک صدا. اولین بار بارگذاری می‌شوند؛ بعد فقط seek(0) و play.
class _SoundSlot {
  final List<AudioPlayer> _players = [];
  int _next = 0;
  Future<void>? _ready;

  Future<void> prepare(AudioSource? Function() source) => _ready ??= () async {
    final src = source();
    if (src == null) return;
    final p = AudioPlayer();
    try {
      await p.setAudioSource(src);
      _players.add(p);
    } catch (e) {
      debugPrint('بارگذاری صدا شکست خورد: $e');
      await p.dispose();
    }
  }();

  Future<void> play(AudioSource? Function() source, double volume) async {
    await prepare(source);
    if (_players.isEmpty) return;
    // اگر همه‌ی نسخه‌ها در حال پخش‌اند و جا هست، یک نسخه‌ی تازه (صدای روی هم، بی‌قطع).
    var p = _players.firstWhere((x) => !x.playing, orElse: () => _players[_next % _players.length]);
    if (p.playing && _players.length < JustAudioService._voicesPerSound) {
      final src = source();
      if (src != null) {
        final extra = AudioPlayer();
        try {
          await extra.setAudioSource(src);
          _players.add(extra);
          p = extra;
        } catch (_) {
          await extra.dispose();
        }
      }
    }
    _next++;
    try {
      await p.setVolume(volume);
      await p.seek(Duration.zero);
      unawaited(p.play());
    } catch (e) {
      debugPrint('پخش جلوه شکست خورد: $e');
    }
  }

  void stop() {
    for (final p in _players) {
      p.stop();
    }
  }

  void dispose() {
    for (final p in _players) {
      p.dispose();
    }
  }
}

/// یک صدای تکراری (موسیقی یا محیط) با بالا و پایین رفتن نرم.
class _Loop {
  final _player = AudioPlayer();
  String? _track;

  /// آنچه در پخش‌کننده بارگذاری شده (حتی وقتی در حال خاموش شدن است).
  String? _loaded;
  double _target = 1;
  int _gen = 0;

  Future<void> start(String path, AudioSource? Function(String) source, double volume) async {
    _target = volume;
    if (_loaded == path && _player.playing) {
      // همان صدا (مثلاً برگشت از بخش به نقشه‌ی همان فصل): بی‌وقفه ادامه می‌دهد.
      ++_gen;
      _track = path;
      await _fade(_player, to: volume, ms: 400);
      return;
    }
    final gen = ++_gen;
    if (_player.playing) await _fade(_player, to: 0, ms: 450);
    if (gen != _gen) return;
    _track = path;
    final src = source(path);
    if (src == null || volume <= 0) {
      await _player.stop();
      return;
    }
    try {
      await _player.setAudioSource(src);
      _loaded = path;
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(0);
      unawaited(_player.play());
      await _fade(_player, to: volume, ms: 800);
    } catch (e) {
      debugPrint('پخش حلقه شکست خورد ($path): $e');
    }
  }

  Future<void> stop() async {
    final gen = ++_gen;
    _track = null;
    // کمی صبر: اگر صفحه‌ی بعد همین صدا را بخواهد، قطع نمی‌شود.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (gen != _gen) return;
    if (_player.playing) await _fade(_player, to: 0, ms: 600);
    if (gen == _gen) await _player.stop();
  }

  Future<void> setVolume(double v) async {
    _target = v;
    if (v <= 0) {
      await _player.pause();
    } else if (_track != null) {
      if (!_player.playing) unawaited(_player.play());
      await _fade(_player, to: v, ms: 300);
    }
  }

  void pause() => _player.pause();

  void resume() {
    if (_track != null && _target > 0) _player.play();
  }

  void dispose() => _player.dispose();
}

/// بلندی را در چند گام کوچک عوض می‌کند تا تغییر شنیده نشود.
Future<void> _fade(AudioPlayer p, {required double to, required int ms}) async {
  const steps = 10;
  final from = p.volume;
  for (var i = 1; i <= steps; i++) {
    await Future<void>.delayed(Duration(milliseconds: ms ~/ steps));
    try {
      await p.setVolume(from + (to - from) * i / steps);
    } catch (_) {
      return;
    }
  }
}
