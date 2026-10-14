import 'dart:math';

import '../../core/storage/local_store.dart';
import '../models/models.dart';

String newId([String prefix = '']) {
  final r = Random();
  final t = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  return '$prefix$t${r.nextInt(1 << 20).toRadixString(36)}';
}

class ProfileRepository {
  ProfileRepository(this.store);

  final LocalStore store;

  List<ChildProfile> all() {
    final list = <ChildProfile>[];
    for (final key in store.box('profiles').keys.cast<String>()) {
      final j = store.readJson('profiles', key);
      if (j != null) list.add(ChildProfile.fromJson(j));
    }
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Future<void> save(ChildProfile p) => store.writeJson('profiles', p.id, p.toJson());

  String? get activeId => store.meta('activeProfile');
  Future<void> setActive(String? id) => store.setMeta('activeProfile', id);

  /// حذف نمایه همراه با همه‌ی داده‌های آن (تنظیمات، پیشرفت، صحنه‌ها، نقاشی‌ها، آهنگ‌ها).
  Future<void> delete(String id) async {
    await store.delete('profiles', id);
    await store.delete('settings', id);
    await store.delete('progress', id);
    await store.delete('builds', id);
    for (final box in ['scenes', 'artworks', 'songs']) {
      for (final k in store.keysWithPrefix(box, '$id/').toList()) {
        await store.delete(box, k);
      }
    }
    if (activeId == id) await setActive(null);
  }
}

class SettingsRepository {
  SettingsRepository(this.store);

  final LocalStore store;

  ProfileSettings load(String profileId) {
    final j = store.readJson('settings', profileId);
    return j == null ? const ProfileSettings() : ProfileSettings.fromJson(j);
  }

  Future<void> save(String profileId, ProfileSettings s) => store.writeJson('settings', profileId, s.toJson());
}

class ProgressRepository {
  ProgressRepository(this.store);

  final LocalStore store;

  Progress load(String profileId) {
    final j = store.readJson('progress', profileId);
    return j == null ? const Progress() : Progress.fromJson(j);
  }

  Future<void> save(String profileId, Progress p) => store.writeJson('progress', profileId, p.toJson());

  Future<void> clearHistory(String profileId) => save(profileId, load(profileId).copyWith(history: const []));
}

class SceneRepository {
  SceneRepository(this.store);

  final LocalStore store;

  Map<String, ObjectState> load(String profileId, String sceneId) {
    final j = store.readJson('scenes', '$profileId/$sceneId');
    if (j == null) return {};
    return {for (final e in j.entries) e.key: ObjectState.fromJson(Map<String, dynamic>.from(e.value as Map))};
  }

  Future<void> save(String profileId, String sceneId, Map<String, ObjectState> states) =>
      store.writeJson('scenes', '$profileId/$sceneId', {for (final e in states.entries) e.key: e.value.toJson()});

  Future<void> reset(String profileId, String sceneId) => store.delete('scenes', '$profileId/$sceneId');
}

class ArtworkRepository {
  ArtworkRepository(this.store);

  final LocalStore store;

  List<Artwork> all(String profileId) {
    final list = <Artwork>[];
    for (final k in store.keysWithPrefix('artworks', '$profileId/')) {
      final j = store.readJson('artworks', k);
      if (j != null) list.add(Artwork.fromJson(j));
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Artwork? get(String profileId, String id) {
    final j = store.readJson('artworks', '$profileId/$id');
    return j == null ? null : Artwork.fromJson(j);
  }

  Future<void> save(String profileId, Artwork a) => store.writeJson('artworks', '$profileId/${a.id}', a.toJson());
  Future<void> delete(String profileId, String id) => store.delete('artworks', '$profileId/$id');

  /// نقاشی در حال کشیدن (پیش‌نویس) تا اگر برنامه بسته شد از دست نرود.
  Artwork? draft(String profileId) => get(profileId, '_draft');
  Future<void> saveDraft(String profileId, Artwork a) => store.writeJson(
    'artworks',
    '$profileId/_draft',
    Artwork(id: '_draft', createdAt: a.createdAt, strokes: a.strokes, background: a.background).toJson(),
  );
  Future<void> clearDraft(String profileId) => delete(profileId, '_draft');
}

class SongRepository {
  SongRepository(this.store);

  final LocalStore store;

  List<Song> all(String profileId) {
    final list = <Song>[];
    for (final k in store.keysWithPrefix('songs', '$profileId/')) {
      final j = store.readJson('songs', k);
      if (j != null) list.add(Song.fromJson(j));
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> save(String profileId, Song s) => store.writeJson('songs', '$profileId/${s.id}', s.toJson());
  Future<void> delete(String profileId, String id) => store.delete('songs', '$profileId/$id');
}

class BuildRepository {
  BuildRepository(this.store);

  final LocalStore store;

  List<BuildPiece> load(String profileId) {
    final j = store.readJson('builds', profileId);
    if (j == null) return [];
    return [for (final p in (j['pieces'] ?? const []) as List) BuildPiece.fromJson(Map<String, dynamic>.from(p as Map))];
  }

  Future<void> save(String profileId, List<BuildPiece> pieces) => store.writeJson('builds', profileId, {
    'pieces': [for (final p in pieces) p.toJson()],
  });
}
