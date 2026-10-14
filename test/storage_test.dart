import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:popo/core/storage/local_store.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/data/repositories/repositories.dart';

void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('popo_store');
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('data survives closing and reopening the store (app restart)', () async {
    var store = await LocalStore.open(path: dir.path);
    final profiles = ProfileRepository(store);
    final p = ChildProfile(id: 'p1', name: 'آرا', avatar: 'cat', ageBand: AgeBand.toddler, createdAt: DateTime(2026));
    await profiles.save(p);
    await profiles.setActive('p1');
    await SettingsRepository(store).save('p1', const ProfileSettings(music: .2, reducedMotion: true));
    await ProgressRepository(store).save('p1', const Progress(stickers: {'chef'}, lastWorld: 'home'));
    await SceneRepository(store).save('p1', 'home.living', {'ball': const ObjectState(x: .4, y: .3, on: true)});
    await ArtworkRepository(store).save(
      'p1',
      Artwork(
        id: 'a1',
        createdAt: DateTime(2026),
        strokes: const [
          Stroke(color: Color(0xFFFF0000), width: .02, points: [Offset(.1, .2), Offset(.3, .4)]),
        ],
      ),
    );
    await store.close();

    store = await LocalStore.open(path: dir.path);
    expect(ProfileRepository(store).all().single.name, 'آرا');
    expect(ProfileRepository(store).activeId, 'p1');
    expect(SettingsRepository(store).load('p1').music, .2);
    expect(SettingsRepository(store).load('p1').reducedMotion, isTrue);
    expect(ProgressRepository(store).load('p1').stickers, {'chef'});
    expect(SceneRepository(store).load('p1', 'home.living')['ball'], const ObjectState(x: .4, y: .3, on: true));
    final art = ArtworkRepository(store).get('p1', 'a1')!;
    expect(art.strokes.single.points.last, const Offset(.3, .4));
    expect(art.strokes.single.color, const Color(0xFFFF0000));
  });

  test('migration 1 → 2 gives old profiles an age band and records the schema', () async {
    var store = await LocalStore.open(path: dir.path);
    await store.box('profiles').put('old', '{"id":"old","name":"قدیمی","avatar":"dog","createdAt":"2025-01-01T00:00:00.000"}');
    await store.setMeta('schema', '1');
    await store.close();

    store = await LocalStore.open(path: dir.path);
    expect(store.meta('schema'), '${LocalStore.schemaVersion}');
    expect(store.readJson('profiles', 'old')!['ageBand'], 'preschool');
    expect(ProfileRepository(store).all().single.ageBand, AgeBand.preschool);
  });

  test('corrupted JSON is ignored instead of crashing', () async {
    final store = await LocalStore.open(path: dir.path);
    await store.box('settings').put('p1', '{not json');
    expect(SettingsRepository(store).load('p1').music, const ProfileSettings().music);
  });

  test('deleting a profile deletes all of its data, and only its data', () async {
    final store = await LocalStore.open(path: dir.path);
    final repo = ProfileRepository(store);
    for (final id in ['a', 'b']) {
      await repo.save(ChildProfile(id: id, name: id, avatar: 'cat', ageBand: AgeBand.early, createdAt: DateTime(2026)));
      await ProgressRepository(store).save(id, const Progress(stickers: {'x'}));
      await SceneRepository(store).save(id, 's', {'o': const ObjectState(x: 0, y: 0)});
      await SongRepository(store).save(
        id,
        Song(
          id: 's1',
          createdAt: DateTime(2026),
          notes: const [SongNote(sound: 'x', atMs: 0)],
        ),
      );
    }
    await repo.setActive('a');
    await repo.delete('a');
    expect(repo.all().map((p) => p.id), ['b']);
    expect(repo.activeId, isNull);
    expect(ProgressRepository(store).load('a').stickers, isEmpty);
    expect(SceneRepository(store).load('a', 's'), isEmpty);
    expect(SongRepository(store).all('a'), isEmpty);
    expect(ProgressRepository(store).load('b').stickers, {'x'});
    expect(SongRepository(store).all('b'), hasLength(1));
  });

  test('settings volume respects the per-channel switch', () {
    const s = ProfileSettings(music: .5, musicOn: false, effects: .7);
    expect(s.volume(AudioChannel.music), 0);
    expect(s.volume(AudioChannel.effects), .7);
    expect(ProfileSettings.fromJson(s.toJson()).musicOn, isFalse);
  });

  test('history is capped and newest first', () {
    final p = Progress(
      history: [for (var i = 0; i < 5; i++) ActivityRecord(activityId: '$i', title: '$i', at: DateTime(2026, 1, i + 1), seconds: 60)],
    );
    final back = Progress.fromJson(p.toJson());
    expect(back.history.first.activityId, '0');
    expect(back.history, hasLength(5));
  });
}
