import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/fa.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/repositories/repositories.dart';
import '../mascot/popo_mascot.dart';

enum Instrument { piano, xylophone, drums, others }

const _notes = ['c4', 'd4', 'e4', 'f4', 'g4', 'a4', 'b4', 'c5', 'd5', 'e5'];
const _noteNames = ['دو', 'ر', 'می', 'فا', 'سل', 'لا', 'سی', 'دو', 'ر', 'می'];
const _rainbow = [
  Color(0xFFF2574E),
  Color(0xFFFF9D37),
  Color(0xFFFFD34F),
  Color(0xFFA6D943),
  Color(0xFF3DBE6B),
  Color(0xFF16B9D1),
  Color(0xFF3778F6),
  Color(0xFFA77BEF),
  Color(0xFFFF8FB8),
  Color(0xFFF2574E),
];

/// استودیوی موسیقی: سازهای لمسی، ضبط یک آهنگ ساده، پخش و ذخیره.
class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key, this.showSongs = false});

  final bool showSongs;

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen> with ActivitySession {
  late final SongRepository _repo = ref.read(songRepoProvider);
  late final String _profile = ref.read(activeIdProvider);
  Instrument _inst = Instrument.piano;
  late bool _songsTab = widget.showSongs;
  bool _recording = false;
  DateTime? _recStart;
  final List<SongNote> _recNotes = [];
  final List<Timer> _playback = [];
  String? _playingId;
  int _beat = 0;

  @override
  String get activityId => 'music.studio';
  @override
  String get activityTitle => 'استودیوی موسیقی';
  @override
  String? get resumeRoute => '/music';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // موسیقی پس‌زمینه قطع می‌شود تا صدای ساز کودک شنیده شود.
      ref.read(audioProvider)
        ..stopMusic()
        ..stopAmbient();
      ref.say('music.hello');
      award('world.music');
    });
  }

  @override
  void dispose() {
    for (final t in _playback) {
      t.cancel();
    }
    super.dispose();
  }

  void _hit(String sound) {
    HapticFeedback.lightImpact();
    ref.read(audioProvider).play(sound);
    setState(() => _beat++);
    if (_recording) {
      _recStart ??= DateTime.now();
      _recNotes.add(SongNote(sound: sound, atMs: DateTime.now().difference(_recStart!).inMilliseconds));
    }
  }

  void _toggleRecord() {
    if (!_recording) {
      _stopPlayback();
      setState(() {
        _recording = true;
        _recStart = null;
        _recNotes.clear();
      });
      ref.say('music.recording');
      return;
    }
    setState(() => _recording = false);
    if (_recNotes.isEmpty) {
      ref.say('music.record');
      return;
    }
    final song = Song(id: newId('s'), createdAt: DateTime.now(), notes: List.of(_recNotes));
    _repo.save(_profile, song);
    ref.say('music.saved');
    award('music.saved');
    _play(song);
  }

  void _play(Song s) {
    _stopPlayback();
    setState(() => _playingId = s.id);
    for (final n in s.notes) {
      _playback.add(
        Timer(Duration(milliseconds: n.atMs + 200), () {
          if (!mounted) return;
          ref.read(audioProvider).play(n.sound);
          setState(() => _beat++);
        }),
      );
    }
    _playback.add(
      Timer(Duration(milliseconds: s.lengthMs + 1400), () {
        if (mounted) setState(() => _playingId = null);
      }),
    );
  }

  void _stopPlayback() {
    for (final t in _playback) {
      t.cancel();
    }
    _playback.clear();
    if (_playingId != null) setState(() => _playingId = null);
  }

  @override
  Widget build(BuildContext context) {
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    return PScaffold(
      title: 'استودیوی موسیقی',
      color: PColors.tint(PColors.purple, .28),
      actions: [
        PIconButton(
          icon: _songsTab ? Icons.piano_rounded : Icons.library_music_rounded,
          label: _songsTab ? 'سازها' : 'آهنگ‌های من',
          iconColor: PColors.purple,
          onPressed: () => setState(() => _songsTab = !_songsTab),
        ),
      ],
      body: Stack(
        children: [
          Column(
            children: [
              if (!_songsTab) ...[
                _InstrumentTabs(value: _inst, onChanged: (i) => setState(() => _inst = i)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(PSpace.md),
                    child: Directionality(
                      // سازها از چپ (بم) به راست (زیر)، مثل ساز واقعی.
                      textDirection: TextDirection.ltr,
                      child: switch (_inst) {
                        Instrument.piano => _Piano(onKey: (i) => _hit('audio/instruments/piano_${_notes[i]}.mp3')),
                        Instrument.xylophone => _Xylophone(onBar: (i) => _hit('audio/instruments/xylo_${_notes[i]}.mp3')),
                        Instrument.drums => _Drums(onPad: _hit),
                        Instrument.others => _Others(onPad: _hit),
                      },
                    ),
                  ),
                ),
                _RecordBar(recording: _recording, count: _recNotes.length, onRecord: _toggleRecord),
              ] else
                Expanded(
                  child: _SongList(repo: _repo, profile: _profile, playingId: _playingId, onPlay: _play, onStop: _stopPlayback),
                ),
            ],
          ),
          PositionedDirectional(
            bottom: MediaQuery.paddingOf(context).bottom,
            start: 0,
            child: IgnorePointer(
              child: AnimatedSlide(
                offset: Offset(0, _beat.isEven ? 0 : -.03),
                duration: const Duration(milliseconds: 90),
                child: PopoMascot(
                  pose: _recording || _playingId != null ? PopoPose.happy : PopoPose.idle,
                  size: 92,
                  reducedMotion: reduced,
                ),
              ),
            ),
          ),
          const CaptionBubble(),
        ],
      ),
    );
  }
}

class _InstrumentTabs extends StatelessWidget {
  const _InstrumentTabs({required this.value, required this.onChanged});

  final Instrument value;
  final ValueChanged<Instrument> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Instrument.piano, 'پیانو', Icons.piano_rounded),
      (Instrument.xylophone, 'زایلوفون', Icons.view_week_rounded),
      (Instrument.drums, 'درام', Icons.album_rounded),
      (Instrument.others, 'سازهای دیگر', Icons.music_note_rounded),
    ];
    return SizedBox(
      height: 96,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: PSpace.xs),
        children: [
          for (final (i, label, icon) in items)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: PSpace.sm),
              child: SizedBox(
                width: 96,
                child: PTile(
                  label: label,
                  selected: i == value,
                  color: i == value ? PColors.tint(PColors.purple, .3) : Colors.white,
                  onTap: () => onChanged(i),
                  child: Icon(icon, size: 34, color: PColors.purple),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// پیانوی اسباب‌بازی با کلیدهای رنگین‌کمانی.
class _Piano extends StatelessWidget {
  const _Piano({required this.onKey});

  final ValueChanged<int> onKey;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(PSpace.sm),
      decoration: BoxDecoration(color: const Color(0xFFE2558A), borderRadius: BorderRadius.circular(PRadius.lg), boxShadow: PShadow.soft()),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _notes.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _PressPad(
                  label: 'نت ${_noteNames[i]}',
                  onDown: () => onKey(i),
                  builder: (down) => AnimatedContainer(
                    duration: const Duration(milliseconds: 60),
                    margin: EdgeInsets.only(top: down ? 6 : 0),
                    decoration: BoxDecoration(
                      color: down ? PColors.tint(_rainbow[i], .2) : Colors.white,
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14), top: Radius.circular(6)),
                      border: Border(
                        bottom: BorderSide(color: _rainbow[i], width: down ? 6 : 14),
                      ),
                    ),
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: FittedBox(
                      child: Text(_noteNames[i], style: PText.label.copyWith(color: PColors.shade(_rainbow[i], .1))),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Xylophone extends StatelessWidget {
  const _Xylophone({required this.onBar});

  final ValueChanged<int> onBar;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < _notes.length; i++)
          Expanded(
            child: FractionallySizedBox(
              heightFactor: 1 - i * .055,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: _PressPad(
                  label: 'تیغه‌ی ${_noteNames[i]}',
                  onDown: () => onBar(i),
                  builder: (down) => AnimatedScale(
                    scale: down ? .95 : 1,
                    duration: const Duration(milliseconds: 60),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [PColors.tint(_rainbow[i], .08), _rainbow[i], PColors.shade(_rainbow[i], .08)]),
                        borderRadius: BorderRadius.circular(PRadius.sm),
                        boxShadow: PShadow.soft(_rainbow[i]),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: CircleAvatar(radius: 5, backgroundColor: Colors.white70),
                          ),
                          Padding(
                            padding: EdgeInsets.all(8),
                            child: CircleAvatar(radius: 5, backgroundColor: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Drums extends StatelessWidget {
  const _Drums({required this.onPad});

  final ValueChanged<String> onPad;

  static const pads = [
    ('drum_kick', 'طبل بزرگ', PColors.danger),
    ('drum_snare', 'طبل کوچک', PColors.blue),
    ('drum_tom', 'تام', PColors.orange),
    ('drum_hihat', 'سنج کوچک', PColors.yellow),
    ('drum_cymbal', 'سنج', PColors.turquoise),
    ('shaker', 'شیکر', PColors.purple),
  ];

  @override
  Widget build(BuildContext context) => _PadGrid(
    children: [
      for (final (id, label, color) in pads)
        _PressPad(
          label: label,
          onDown: () => onPad('audio/instruments/$id.mp3'),
          builder: (down) => _RoundPad(color: color, label: label, down: down),
        ),
    ],
  );
}

class _Others extends StatelessWidget {
  const _Others({required this.onPad});

  final ValueChanged<String> onPad;

  @override
  Widget build(BuildContext context) => _PadGrid(
    children: [
      _PressPad(
        label: 'گیتار',
        onDown: () => onPad('audio/instruments/guitar.mp3'),
        builder: (d) => _ArtPad(art: 'guitar', label: 'گیتار', down: d),
      ),
      _PressPad(
        label: 'فلوت',
        onDown: () => onPad('audio/instruments/flute.mp3'),
        builder: (d) => _ArtPad(art: 'trumpet', label: 'فلوت', down: d),
      ),
      _PressPad(
        label: 'ویولن',
        onDown: () => onPad('audio/instruments/violin.mp3'),
        builder: (d) => _ArtPad(art: 'note', label: 'ویولن', down: d),
      ),
      for (var i = 0; i < 3; i++)
        _PressPad(
          label: 'زنگوله ${_noteNames[i * 2]}',
          onDown: () => onPad('audio/instruments/bell_${_notes[i * 2]}.mp3'),
          builder: (d) => _RoundPad(color: _rainbow[i * 3], label: 'زنگوله', down: d),
        ),
    ],
  );
}

class _PadGrid extends StatelessWidget {
  const _PadGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final cols = box.maxWidth > box.maxHeight ? 3 : 2;
      final rows = (children.length / cols).ceil();
      final cell = (box.maxWidth / cols).clamp(0.0, box.maxHeight / rows);
      return Center(
        child: Wrap(
          children: [
            for (final c in children)
              SizedBox(
                width: cell,
                height: cell,
                child: Padding(padding: const EdgeInsets.all(PSpace.xs), child: c),
              ),
          ],
        ),
      );
    },
  );
}

class _RoundPad extends StatelessWidget {
  const _RoundPad({required this.color, required this.label, required this.down});

  final Color color;
  final String label;
  final bool down;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: down ? .9 : 1,
    duration: const Duration(milliseconds: 60),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Colors.white, PColors.tint(color, .25), color], stops: const [0, .55, 1]),
        border: Border.all(color: PColors.shade(color, .12), width: 8),
        boxShadow: down ? PShadow.glow(color) : PShadow.soft(color),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(PSpace.sm),
        child: FittedBox(child: Text(label, style: PText.label)),
      ),
    ),
  );
}

class _ArtPad extends StatelessWidget {
  const _ArtPad({required this.art, required this.label, required this.down});

  final String art;
  final String label;
  final bool down;

  @override
  Widget build(BuildContext context) => AnimatedScale(
    scale: down ? .92 : 1,
    duration: const Duration(milliseconds: 60),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(PRadius.lg),
        boxShadow: down ? PShadow.glow(PColors.purple) : PShadow.soft(),
      ),
      padding: const EdgeInsets.all(PSpace.sm),
      child: Column(
        children: [
          Expanded(child: ArtImage(art)),
          Text(label, style: PText.label),
        ],
      ),
    ),
  );
}

/// کلیدی که با لمس (نه رها کردن) صدا می‌دهد تا پاسخ ساز فوری باشد؛ چند انگشت هم‌زمان کار می‌کند.
class _PressPad extends StatefulWidget {
  const _PressPad({required this.label, required this.onDown, required this.builder});

  final String label;
  final VoidCallback onDown;
  final Widget Function(bool down) builder;

  @override
  State<_PressPad> createState() => _PressPadState();
}

class _PressPadState extends State<_PressPad> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: widget.label,
    onTap: widget.onDown,
    child: Listener(
      onPointerDown: (_) {
        setState(() => _down = true);
        widget.onDown();
      },
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: widget.builder(_down),
    ),
  );
}

class _RecordBar extends StatelessWidget {
  const _RecordBar({required this.recording, required this.count, required this.onRecord});

  final bool recording;
  final int count;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(PSpace.md, 0, PSpace.md, PSpace.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PButton(
            label: recording ? 'تمام و ذخیره' : 'ضبط آهنگ',
            icon: recording ? Icons.stop_rounded : Icons.fiber_manual_record_rounded,
            color: recording ? PColors.success : PColors.danger,
            onPressed: onRecord,
          ),
          if (recording) ...[const SizedBox(width: PSpace.md), Text('${faDigits(count)} نت', style: PText.heading)],
        ],
      ),
    ),
  );
}

class _SongList extends StatefulWidget {
  const _SongList({required this.repo, required this.profile, required this.playingId, required this.onPlay, required this.onStop});

  final SongRepository repo;
  final String profile;
  final String? playingId;
  final ValueChanged<Song> onPlay;
  final VoidCallback onStop;

  @override
  State<_SongList> createState() => _SongListState();
}

class _SongListState extends State<_SongList> {
  late List<Song> _songs = widget.repo.all(widget.profile);

  @override
  Widget build(BuildContext context) {
    if (_songs.isEmpty) return const StateView(state: ViewState.empty, message: 'هنوز آهنگی ضبط نکرده‌ای. دکمه‌ی قرمز «ضبط آهنگ» را بزن!');
    return ListView.separated(
      padding: const EdgeInsets.all(PSpace.md),
      itemCount: _songs.length,
      separatorBuilder: (_, _) => const SizedBox(height: PSpace.sm),
      itemBuilder: (context, i) {
        final s = _songs[i];
        final playing = widget.playingId == s.id;
        return PCard(
          padding: const EdgeInsets.all(PSpace.sm),
          child: Row(
            children: [
              PIconButton(
                icon: playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                label: playing ? 'توقف' : 'پخش',
                iconColor: Colors.white,
                color: playing ? PColors.orange : PColors.success,
                onPressed: () => playing ? widget.onStop() : widget.onPlay(s),
              ),
              const SizedBox(width: PSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('آهنگ ${faDigits(_songs.length - i)}', style: PText.heading),
                    Text('${faDigits(s.notes.length)} نت · ${faRelativeDay(s.createdAt)}', style: PText.caption),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'پاک کردن',
                icon: const Icon(Icons.delete_outline_rounded, color: PColors.danger),
                onPressed: () async {
                  final ok = await confirm(context, title: 'این آهنگ پاک شود؟', yes: 'پاک کن', no: 'نه');
                  if (!ok) return;
                  await widget.repo.delete(widget.profile, s.id);
                  setState(() => _songs = widget.repo.all(widget.profile));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
