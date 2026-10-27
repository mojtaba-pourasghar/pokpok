import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/assets/asset_resolver.dart';
import '../core/assets/download_manager.dart';
import '../core/audio/popo_audio.dart';
import '../core/billing/access_store.dart';
import '../core/billing/billing.dart';
import '../core/content/content.dart';
import '../core/notices/notices_store.dart';
import '../core/storage/local_store.dart';
import '../data/models/models.dart';
import '../data/repositories/repositories.dart';

// ── وابستگی‌های پایه؛ در main.dart (و تست‌ها) با نمونه‌ی واقعی جایگزین می‌شوند ──────────────
final storeProvider = Provider<LocalStore>((_) => throw UnimplementedError('storeProvider'));
final prefsProvider = Provider<SharedPreferences>((_) => throw UnimplementedError('prefsProvider'));
final contentProvider = Provider<ContentRepository>((_) => throw UnimplementedError('contentProvider'));
final audioProvider = Provider<PopoAudio>((_) => throw UnimplementedError('audioProvider'));
final assetsProvider = ChangeNotifierProvider<AssetResolver>((_) => throw UnimplementedError('assetsProvider'));
final downloadsProvider = ChangeNotifierProvider<DownloadManager>((ref) => DownloadManager(ref.watch(assetsProvider)));

/// نسخه‌ی کامل (کافه‌بازار). در main.dart با BazaarBilling جایگزین می‌شود؛ پیش‌فرض (آزمون‌ها، وب) بی پرداخت
/// و با قاعده‌ی همان ساختی که اجرا می‌شود (debug: همه باز).
final accessProvider = ChangeNotifierProvider<AccessStore>((ref) => AccessStore(ref.watch(prefsProvider), const NoBilling()));

/// خبرهای امضاشده. در main.dart با کلید عمومی همراه برنامه جایگزین می‌شود؛ پیش‌فرض بی‌کلید است، پس
/// هیچ خبری خوانده و نشان داده نمی‌شود.
final noticesProvider = ChangeNotifierProvider<NoticesStore>((ref) => NoticesStore(ref.watch(prefsProvider)));

/// پنجره‌هایی (دیالوگ، برگه‌ی پایین) که الان روی Navigator ریشه باز است؛ خبر رویشان نمی‌آید (NoticeHost).
class PopupWatcher extends NavigatorObserver {
  int open = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute) open++;
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute && open > 0) open--;
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PopupRoute && open > 0) open--;
  }
}

final popupWatcherProvider = Provider((_) => PopupWatcher());

final profileRepoProvider = Provider((ref) => ProfileRepository(ref.watch(storeProvider)));
final settingsRepoProvider = Provider((ref) => SettingsRepository(ref.watch(storeProvider)));
final progressRepoProvider = Provider((ref) => ProgressRepository(ref.watch(storeProvider)));
final sceneRepoProvider = Provider((ref) => SceneRepository(ref.watch(storeProvider)));
final artworkRepoProvider = Provider((ref) => ArtworkRepository(ref.watch(storeProvider)));
final songRepoProvider = Provider((ref) => SongRepository(ref.watch(storeProvider)));
final buildRepoProvider = Provider((ref) => BuildRepository(ref.watch(storeProvider)));

/// تنظیمات سبک سراسری (SharedPreferences): دیدن معرفی، سقف زمان روزانه.
class AppPrefs {
  AppPrefs(this.prefs);

  final SharedPreferences prefs;

  bool get introSeen => prefs.getBool('introSeen') ?? false;
  Future<void> setIntroSeen() => prefs.setBool('introSeen', true);

  /// سقف بازی روزانه به دقیقه؛ ۰ یعنی بدون سقف.
  int get dailyLimitMinutes => prefs.getInt('dailyLimit') ?? 0;
  Future<void> setDailyLimit(int m) => prefs.setInt('dailyLimit', m);

  /// ثبت تاریخچه‌ی فعالیت روی دستگاه (والدین می‌توانند خاموشش کنند).
  bool get keepHistory => prefs.getBool('keepHistory') ?? true;
  Future<void> setKeepHistory(bool v) => prefs.setBool('keepHistory', v);
}

final appPrefsProvider = Provider((ref) => AppPrefs(ref.watch(prefsProvider)));

// ── نمایه‌ها ────────────────────────────────────────────────────────────────
class ProfilesState {
  const ProfilesState(this.profiles, this.activeId);

  final List<ChildProfile> profiles;
  final String? activeId;

  ChildProfile? get active {
    for (final p in profiles) {
      if (p.id == activeId) return p;
    }
    return profiles.isEmpty ? null : profiles.first;
  }
}

class ProfilesNotifier extends Notifier<ProfilesState> {
  ProfileRepository get _repo => ref.read(profileRepoProvider);

  @override
  ProfilesState build() => ProfilesState(ref.watch(profileRepoProvider).all(), ref.watch(profileRepoProvider).activeId);

  void _reload() => state = ProfilesState(_repo.all(), _repo.activeId);

  /// اولین اجرا: یک نمایه‌ی پیش‌فرض تا کودک بدون ثبت‌نام بازی کند. والدین بعداً نام را عوض می‌کنند.
  Future<ChildProfile> ensureOne() async {
    final a = state.active;
    if (a != null) return a;
    return create(name: 'کوچولو', avatar: 'rabbit', ageBand: AgeBand.preschool);
  }

  Future<ChildProfile> create({required String name, required String avatar, required AgeBand ageBand}) async {
    final p = ChildProfile(
      id: newId('p'),
      name: name.trim().isEmpty ? 'کوچولو' : name.trim(),
      avatar: avatar,
      ageBand: ageBand,
      createdAt: DateTime.now(),
    );
    await _repo.save(p);
    await _repo.setActive(p.id);
    _reload();
    return p;
  }

  Future<void> update(ChildProfile p) async {
    await _repo.save(p);
    _reload();
  }

  Future<void> select(String id) async {
    await _repo.setActive(id);
    _reload();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    final rest = _repo.all();
    if (_repo.activeId == null && rest.isNotEmpty) await _repo.setActive(rest.first.id);
    _reload();
  }
}

final profilesProvider = NotifierProvider<ProfilesNotifier, ProfilesState>(ProfilesNotifier.new);
final activeProfileProvider = Provider<ChildProfile?>((ref) => ref.watch(profilesProvider).active);

/// شناسه‌ی نمایه‌ی فعال؛ اگر هنوز نمایه‌ای نیست «_guest».
final activeIdProvider = Provider<String>((ref) => ref.watch(activeProfileProvider)?.id ?? '_guest');

// ── تنظیمات هر نمایه ───────────────────────────────────────────────────────
class SettingsNotifier extends Notifier<ProfileSettings> {
  @override
  ProfileSettings build() {
    final s = ref.watch(settingsRepoProvider).load(ref.watch(activeIdProvider));
    ref.read(audioProvider).settings = s;
    return s;
  }

  Future<void> update(ProfileSettings Function(ProfileSettings) change) async {
    final s = change(state);
    state = s;
    ref.read(audioProvider).settings = s;
    await ref.read(settingsRepoProvider).save(ref.read(activeIdProvider), s);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, ProfileSettings>(SettingsNotifier.new);

// ── پیشرفت هر نمایه ───────────────────────────────────────────────────────
class ProgressNotifier extends Notifier<Progress> {
  @override
  Progress build() => ref.watch(progressRepoProvider).load(ref.watch(activeIdProvider));

  Future<void> _save(Progress p) async {
    state = p;
    await ref.read(progressRepoProvider).save(ref.read(activeIdProvider), p);
  }

  /// true اگر برچسب تازه بود.
  Future<bool> addSticker(String id) async {
    if (state.stickers.contains(id)) return false;
    await _save(state.copyWith(stickers: {...state.stickers, id}));
    return true;
  }

  Future<void> complete(String activityId) => _save(state.copyWith(completed: {...state.completed, activityId}));

  Future<void> visitWorld(String worldId) => _save(state.copyWith(lastWorld: worldId));

  Future<void> setLastRoute(String? route) =>
      _save(route == null ? state.copyWith(clearLastRoute: true) : state.copyWith(lastRoute: route));

  Future<void> record(String activityId, String title, int seconds) async {
    if (seconds < 3 || !ref.read(appPrefsProvider).keepHistory) return;
    final h = [ActivityRecord(activityId: activityId, title: title, at: DateTime.now(), seconds: seconds), ...state.history];
    await _save(state.copyWith(history: h.take(Progress.historyLimit).toList()));
  }

  Future<void> clearHistory() => _save(state.copyWith(history: const []));

  /// مجموع ثانیه‌های بازی امروز.
  int todaySeconds([DateTime? now]) {
    final n = now ?? DateTime.now();
    return state.history.where((h) => h.at.year == n.year && h.at.month == n.month && h.at.day == n.day).fold(0, (a, h) => a + h.seconds);
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, Progress>(ProgressNotifier.new);

// ── دروازه‌ی والدین ─────────────────────────────────────────────────────────
/// پس از پاسخ درست، بخش والدین تا چند دقیقه باز می‌ماند.
class ParentGateNotifier extends Notifier<DateTime?> {
  static const window = Duration(minutes: 5);

  @override
  DateTime? build() => null;

  bool get isOpen => state != null && DateTime.now().isBefore(state!);
  void unlock() => state = DateTime.now().add(window);
  void lock() => state = null;
}

final parentGateProvider = NotifierProvider<ParentGateNotifier, DateTime?>(ParentGateNotifier.new);
