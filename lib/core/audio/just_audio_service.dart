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
/// - جلوه‌ها از یک «استخر» کوچک پخش‌کننده می‌آیند تا نت‌های پشت سر هم (پیانو، طبل) روی هم
///   شنیده شوند و هیچ صدایی صدای قبلی را نبُرد.
/// - هنگام حرف زدن پوپو، موسیقی آرام‌تر می‌شود.
/// - با رفتن برنامه به پس‌زمینه همه‌چیز متوقف و با بازگشت، موسیقی و صدای محیط ادامه می‌یابد.
class JustAudioService with WidgetsBindingObserver implements PopoAudio {
  JustAudioService(this._assets, {int poolSize = 6}) {
    for (var i = 0; i < poolSize; i++) {
      _pool.add(AudioPlayer());
    }
    WidgetsBinding.instance.addObserver(this);
  }

  final AssetResolver _assets;
  final List<AudioPlayer> _pool = [];
  int _next = 0;
  final _voice = AudioPlayer();
  final _music = AudioPlayer();
  final _ambient = AudioPlayer();
  final _caption = ValueNotifier<VoiceLine?>(null);
  int _gen = 0;
  String? _musicTrack;
  String? _ambientTrack;
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

  Future<bool> _load(AudioPlayer p, String logicalPath) async {
    final r = _assets.resolve(logicalPath);
    if (r == null) return false;
    try {
      if (r.source == AssetSource.bundled) {
        await p.setAsset(r.key);
      } else {
        await p.setFilePath(r.key);
      }
      return true;
    } catch (e) {
      debugPrint('بارگذاری صدا شکست خورد ($logicalPath): $e');
      return false;
    }
  }

  @override
  Future<void> say(VoiceLine? line) async {
    if (line == null) return;
    final gen = ++_gen;
    await _voice.stop();
    if (line.delayMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: line.delayMs));
      if (gen != _gen) return;
    }
    _caption.value = line;
    final path = 'audio/${line.file}';
    if (_vol(AudioChannel.voice) > 0 && _assets.exists(path) && await _load(_voice, path) && gen == _gen) {
      _duck(true);
      try {
        await _voice.setVolume(_vol(AudioChannel.voice));
        await _voice.play();
      } catch (e) {
        debugPrint('پخش گوینده شکست خورد: $e');
      }
      _duck(false);
    } else {
      // هنوز صدای ضبط‌شده نیست (یا گوینده خاموش است): زمانی شبیه خواندن جمله صبر می‌کنیم
      // تا کودک زیرنویس را ببیند.
      await Future<void>.delayed(Duration(milliseconds: min(3000, max(1400, line.text.length * 60))));
    }
    if (gen == _gen && identical(_caption.value, line)) _caption.value = null;
  }

  @override
  void play(String logicalPath, {double volume = 1}) {
    final v = _vol(AudioChannel.effects) * volume;
    if (v <= 0) return;
    final p = _pool[_next];
    _next = (_next + 1) % _pool.length;
    () async {
      try {
        await p.stop();
        if (await _load(p, logicalPath)) {
          await p.setVolume(v);
          await p.play();
        }
      } catch (e) {
        debugPrint('پخش جلوه شکست خورد ($logicalPath): $e');
      }
    }();
  }

  @override
  void ui(UiSound sound) => play(sound.path, volume: .8);

  @override
  void startMusic(String logicalPath) {
    if (_musicTrack == logicalPath && _music.playing) return;
    _musicTrack = logicalPath;
    _restartLoop(_music, _musicTrack, _musicVolume);
  }

  @override
  void stopMusic() {
    _musicTrack = null;
    _music.stop();
  }

  @override
  void startAmbient(String logicalPath) {
    if (_ambientTrack == logicalPath && _ambient.playing) return;
    _ambientTrack = logicalPath;
    _restartLoop(_ambient, _ambientTrack, _vol(AudioChannel.ambient) * .7);
  }

  @override
  void stopAmbient() {
    _ambientTrack = null;
    _ambient.stop();
  }

  Future<void> _restartLoop(AudioPlayer p, String? track, double volume) async {
    await p.stop();
    if (track == null || volume <= 0) return;
    if (!await _load(p, track)) return;
    await p.setLoopMode(LoopMode.one);
    await p.setVolume(volume);
    unawaited(p.play());
  }

  double get _musicVolume => _vol(AudioChannel.music) * (_ducked ? .35 : 1);

  void _duck(bool on) {
    _ducked = on;
    if (_music.playing) _music.setVolume(_musicVolume);
  }

  @override
  void stopAll() {
    _gen++;
    _caption.value = null;
    _voice.stop();
    for (final p in _pool) {
      p.stop();
    }
    _duck(false);
  }

  void _apply() {
    if (_vol(AudioChannel.voice) <= 0) _voice.stop();
    if (_vol(AudioChannel.effects) <= 0) {
      for (final p in _pool) {
        p.stop();
      }
    }
    _applyLoop(_music, _musicTrack, _musicVolume);
    _applyLoop(_ambient, _ambientTrack, _vol(AudioChannel.ambient) * .7);
  }

  void _applyLoop(AudioPlayer p, String? track, double volume) {
    if (volume <= 0) {
      p.stop();
    } else if (track != null && !p.playing) {
      _restartLoop(p, track, volume);
    } else {
      p.setVolume(volume);
    }
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
        if (_musicTrack != null && _musicVolume > 0) _music.play();
        if (_ambientTrack != null && _vol(AudioChannel.ambient) > 0) _ambient.play();
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final p in [_voice, _music, _ambient, ..._pool]) {
      p.dispose();
    }
    _caption.dispose();
  }
}
