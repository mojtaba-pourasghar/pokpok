import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/content/content.dart';
import 'package:popo/features/worlds/backgrounds/scene_backgrounds.dart';

/// سلامت محتوا: هر ارجاع در JSONها به چیزی واقعی اشاره می‌کند.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ContentRepository c;
  late Set<String> bundled;

  setUpAll(() async {
    c = await ContentRepository.load(rootBundle);
    bundled = (await AssetManifest.loadFromAssetBundle(rootBundle)).listAssets().toSet();
  });

  bool exists(String logical) => bundled.contains('assets/$logical');

  test('six worlds, each with an entry route and art', () {
    expect(c.worlds.map((w) => w.id), ['home', 'city', 'nature', 'art', 'music', 'build']);
    for (final w in c.worlds) {
      expect(c.art.containsKey(w.art), isTrue, reason: w.id);
      for (final s in w.scenes) {
        expect(c.scenes.containsKey(s), isTrue, reason: '${w.id} → $s');
      }
    }
    expect(c.scenesOf('home').map((s) => s.title), ['پذیرایی', 'آشپزخانه', 'اتاق خواب', 'حمام']);
    expect(c.scenesOf('nature').map((s) => s.title), ['جنگل', 'باغ', 'برکه', 'مزرعه']);
  });

  test('every scene object has art, every sound and voice line exists', () {
    for (final s in c.scenes.values) {
      expect(SceneBackgroundPainter.ids, contains(s.background), reason: s.id);
      expect(c.art.containsKey(s.icon), isTrue, reason: '${s.id} icon');
      for (final id in [s.intro, s.done]) {
        if (id != null) expect(c.voiceLines.containsKey(id), isTrue, reason: '${s.id}: $id');
      }
      if (s.sticker != null) expect(c.stickers.containsKey(s.sticker), isTrue, reason: s.id);
      if (s.ambient != null) expect(exists(s.ambient!), isTrue, reason: s.ambient);
      final ids = s.objects.map((o) => o.id).toSet();
      expect(ids.length, s.objects.length, reason: 'duplicate object id in ${s.id}');
      for (final o in s.objects) {
        expect(c.art.containsKey(o.art), isTrue, reason: '${s.id}/${o.id}: ${o.art}');
        for (final st in o.states) {
          expect(c.art.containsKey(st), isTrue, reason: '${s.id}/${o.id}: $st');
        }
        if (o.tap?.sound != null) expect(exists(o.tap!.sound!), isTrue, reason: '${s.id}/${o.id}: ${o.tap!.sound}');
        for (final r in o.accepts) {
          if (r.sound != null) expect(exists(r.sound!), isTrue, reason: r.sound);
        }
        if (o.drag == DragMode.path) expect(s.paths.containsKey(o.path), isTrue, reason: '${s.id}/${o.id}');
        expect(o.x, inInclusiveRange(0, 1));
        expect(o.y, inInclusiveRange(0, 1));
        expect(o.label, isNotNull, reason: '${s.id}/${o.id} needs a Persian label for screen readers');
      }
      for (final g in s.goals) {
        expect(ids, contains(g.target), reason: '${s.id} goal');
        if (g.tag != null) {
          expect(s.objects.any((o) => o.tags.contains(g.tag)), isTrue, reason: '${s.id}: nothing carries tag ${g.tag}');
        }
      }
      for (final w in s.want) {
        expect(ids, contains(w));
      }
    }
  });

  test('role-play goals can actually be reached', () {
    for (final s in c.scenes.values.where((s) => s.world == 'play')) {
      for (final g in s.goals.where((g) => g.tag != null)) {
        final carriers = s.objects.where((o) => o.tags.contains(g.tag) && o.drag != DragMode.none).length;
        final target = s.objects.firstWhere((o) => o.id == g.target);
        final r = target.accepts.firstWhere((a) => a.tag == g.tag);
        final reusable = r.then != AfterDrop.hide;
        expect(reusable || carriers >= g.count, isTrue, reason: '${s.id}: ${g.count} × ${g.tag} but only $carriers');
      }
    }
  });

  test('activities point at real routes and art; stickers have art', () {
    final routes = RegExp(
      r'^/(world/(home|city|nature)(\?scene=[\w.]+)?|play/play\.\w+|art(/gallery)?|music(\?tab=songs)?|build|puzzle/(shapes|sort|pattern|match))$',
    );
    for (final a in c.activities) {
      expect(routes.hasMatch(a.route), isTrue, reason: a.route);
      expect(c.art.containsKey(a.art), isTrue, reason: a.id);
      expect(c.categories.any((k) => k.id == a.category), isTrue, reason: a.id);
      final scene = Uri.parse(a.route).queryParameters['scene'];
      if (scene != null) expect(c.scenes.containsKey(scene), isTrue);
    }
    for (final s in c.stickers.values) {
      expect(c.art.containsKey(s.art), isTrue, reason: s.id);
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
    expect(c.pick('try'), isNotNull);
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
}
