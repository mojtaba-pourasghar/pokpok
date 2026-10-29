import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/content/content.dart';
import 'package:popo/game/engines/engines.dart';
import 'package:popo/game/game_data.dart';
import 'package:popo/ui/toons/backdrops.dart';
import 'package:popo/ui/toons/toons.dart';

/// سلامت محتوا: هر ارجاع در JSONها به چیزی واقعی اشاره می‌کند.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository c;
  late GameData game;
  late Set<String> bundled;

  setUpAll(() async {
    c = await ContentRepository.load(rootBundle);
    game = await GameData.load(rootBundle);
    bundled = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
  });

  bool exists(String logical) => bundled.contains('assets/$logical');

  test('eight chapters of four sections; every step uses a known engine and real pictures', () {
    expect(game.chapters, hasLength(8));
    for (final ch in game.chapters) {
      expect(ch.sections, hasLength(4), reason: ch.id);
      expect(game.friends.containsKey(ch.friend), isTrue, reason: ch.id);
      expect(exists(ch.ambient), isTrue, reason: ch.ambient);
      expect(ch.film, hasLength(ch.sections.length), reason: '${ch.id} film');
    }
    final pictures = {...game.emoji.keys, ...game.items.keys, ...game.friends.keys};
    for (final s in game.sections.values) {
      expect(game.items.containsKey(s.makes), isTrue, reason: s.id);
      expect(s.steps, isNotEmpty, reason: s.id);
      for (final st in s.steps) {
        expect(engineNames, contains(st.engine), reason: '${s.id}: ${st.engine}');
        for (final k in ['target', 'result', 'base', 'into', 'source', 'spot', 'need']) {
          final v = st.opt(k);
          if (v != null && st.engine != 'mix') expect(pictures, contains(v), reason: '${s.id}.$k = $v');
        }
        for (final k in ['distract', 'good', 'bad', 'items']) {
          for (final v in st.list(k)) {
            expect(pictures, contains(v), reason: '${s.id}.$k');
          }
        }
        for (final p in [...st.maps('parts'), ...st.maps('pads')]) {
          expect(pictures, contains(p['art']), reason: s.id);
        }
        for (final k in ['sound']) {
          final v = st.opt(k);
          if (v != null) expect(exists(v), isTrue, reason: '${s.id}: $v');
        }
        for (final p in st.maps('pads')) {
          expect(exists(p['sound'] as String), isTrue, reason: '${s.id}: ${p['sound']}');
        }
        if (st.engine == 'use') expect(game.items.containsKey(st.str('need')), isTrue);
        for (final p in st.maps('pairs')) {
          expect(game.items.containsKey(p['item']), isTrue);
          expect(game.friends.containsKey(p['friend']), isTrue);
        }
      }
    }
    for (final i in game.items.values) {
      expect(exists(i.sound), isTrue, reason: '${i.id}: ${i.sound}');
      expect(i.quiz.options, hasLength(3), reason: i.id);
      expect(i.quiz.answer, inInclusiveRange(0, 2));
      for (final o in i.quiz.options) {
        expect(pictures, contains(o.art), reason: i.id);
      }
    }
  });

  test('the backpack only asks for things made earlier in the story', () {
    final made = <String>{};
    for (final ch in game.chapters) {
      for (final s in ch.sections) {
        for (final need in s.needs) {
          expect(made, contains(need), reason: '${s.id} needs $need before it is made');
        }
        made.add(s.makes);
      }
    }
  });

  test('kits open with rising star counts and tools have recipes', () {
    final stars = [for (final k in game.kits) k.stars];
    expect(stars, orderedEquals([...stars]..sort()));
    expect(stars.last, lessThanOrEqualTo(game.totalSections * 3));
    for (final t in game.tools) {
      expect(t.recipes, isNotEmpty, reason: t.id);
      expect(t.price, greaterThan(0));
    }
    for (final s in game.sections.values) {
      if (s.secret != null) expect(game.tools.any((t) => t.id == s.secret), isTrue, reason: s.id);
    }
    for (final c in game.combos) {
      for (final i in c.items) {
        expect(game.items.containsKey(i), isTrue, reason: c.id);
      }
    }
    // هر سفارش دست‌کم با یک ساخته انجام‌شدنی است.
    for (final o in game.orders) {
      expect(game.items.values.any((i) => i.tags.contains(o.tag)), isTrue, reason: o.tag);
    }
  });

  test('every line the game says exists', () {
    void has(String id) => expect(c.voiceLines.containsKey(id), isTrue, reason: id);
    for (final ch in game.chapters) {
      has('${ch.id}.intro');
      for (var i = 1; i <= ch.film.length; i++) {
        has('${ch.id}.film.$i');
      }
      if (ch.next.isNotEmpty) has('${ch.id}.next');
    }
    for (final s in game.sections.values) {
      has('${s.id}.mission');
      for (var i = 1; i <= s.steps.length; i++) {
        has('${s.id}.s$i');
        if (s.steps[i - 1].engine == 'use') {
          has('${s.id}.s$i.done');
          has('${s.id}.s$i.why');
        }
      }
    }
    for (final i in game.items.values) {
      has('item.${i.id}.made');
      has('item.${i.id}.use');
      has('item.${i.id}.quiz');
      if (i.taste != null) has('item.${i.id}.taste');
    }
    for (final t in game.tools) {
      has('tool.${t.id}.safety');
    }
    for (var i = 1; i <= game.orders.length; i++) {
      has('order.$i');
    }
    for (var i = 1; i <= game.combos.length; i++) {
      has('combo.$i');
    }
  });

  test('voice lines: unique ids and file names, Persian text', () {
    final files = <String>{};
    for (final l in c.voiceLines.values) {
      expect(files.add(l.file), isTrue, reason: l.file);
      expect(l.file, startsWith('voice/'));
      expect(RegExp(r'[؀-ۿ]').hasMatch(l.text), isTrue, reason: l.id);
    }
    expect(c.pick('praise'), isNotNull);
    expect(c.pick('idle'), isNotNull);
  });

  test('every voice id the code uses exists', () {
    final used = <String>{};
    final re = RegExp(r'''(?:say|sayOneOf)\('([\w.]+)'\)''');
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>()) {
      for (final m in re.allMatches(f.readAsStringSync())) {
        used.add(m.group(1)!);
      }
    }
    expect(used, isNotEmpty);
    for (final id in used) {
      final isGroup = c.voiceLines.values.any((l) => l.group == id);
      expect(c.voiceLines.containsKey(id) || isGroup, isTrue, reason: id);
    }
  });

  test('asset manifest checksums match the bundled files', () {
    final m = jsonDecode(File('assets/content/asset_manifest.json').readAsStringSync()) as Map;
    for (final a in (m['assets'] as List).cast<Map>()) {
      final f = File('assets/${a['path']}');
      expect(f.existsSync(), isTrue, reason: a['path'] as String);
      expect(f.lengthSync(), a['bytes'], reason: '${a['path']} changed — run tools/build_manifest.py');
    }
  });

  test('every real recording has a source and licence on file', () {
    final s = jsonDecode(File('docs/audio/sfx_sources.json').readAsStringSync()) as Map;
    for (final e in (s['files'] as Map).entries) {
      final v = e.value as Map;
      expect(File('assets/${v['file']}').existsSync(), isTrue, reason: e.key);
      expect((v['license'] as String).isNotEmpty, isTrue, reason: e.key);
      expect((v['source'] as String).startsWith('https://'), isTrue, reason: e.key);
    }
  });

  test('every picture and friend is a living cartoon, every scene a living backdrop', () {
    final game = jsonDecode(File('assets/content/game.json').readAsStringSync()) as Map;
    final ids = {...(game['art'] as Map).keys, ...(game['friends'] as Map).keys};
    expect(ids.where((id) => !toons.containsKey(id)).toList(), isEmpty);
    for (final ch in (game['chapters'] as List).cast<Map>()) {
      expect(backdrops.containsKey(ch['bg']), isTrue, reason: '${ch['id']} ${ch['bg']}');
    }
    for (final id in ['meadow', 'playroom', 'shop', 'star_workshop']) {
      expect(backdrops.containsKey(id), isTrue, reason: id);
    }
  });
}
