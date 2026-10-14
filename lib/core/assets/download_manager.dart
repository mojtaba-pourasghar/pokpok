import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'asset_config.dart';
import 'asset_resolver.dart';

class PackFile {
  const PackFile({required this.path, required this.size, required this.sha256});

  final String path;
  final int size;
  final String sha256;

  factory PackFile.fromJson(Map<String, dynamic> j) =>
      PackFile(path: j['path'] as String, size: (j['size'] as num?)?.toInt() ?? 0, sha256: (j['sha256'] ?? '') as String);
}

class AssetPack {
  const AssetPack({
    required this.id,
    required this.title,
    required this.description,
    required this.files,
    this.version = 1,
    this.minApp = 1,
    this.world,
  });

  final String id;
  final String title;
  final String description;
  final List<PackFile> files;
  final int version;

  /// کمترین «سطح محتوای» برنامه که این بسته را می‌فهمد.
  final int minApp;
  final String? world;

  bool get compatible => minApp <= AssetConfig.appContentLevel;
  int get totalBytes => files.fold(0, (a, f) => a + f.size);

  factory AssetPack.fromJson(Map<String, dynamic> j) => AssetPack(
    id: j['id'] as String,
    title: (j['title'] ?? j['id']) as String,
    description: (j['description'] ?? '') as String,
    version: (j['version'] as num?)?.toInt() ?? 1,
    minApp: (j['minApp'] as num?)?.toInt() ?? 1,
    world: j['world'] as String?,
    files: [for (final f in (j['files'] ?? const []) as List) PackFile.fromJson(Map<String, dynamic>.from(f as Map))],
  );
}

enum PackStatus { notDownloaded, partial, downloading, paused, ready }

enum DownloadErrorKind { network, checksum, storage, server }

class DownloadError {
  const DownloadError(this.kind, this.message);

  final DownloadErrorKind kind;
  final String message;
}

/// دانلود بسته‌های دارایی از CDN (Cloudflare R2) به حافظه‌ی برنامه.
///
/// - فهرست بسته‌ها پس از هر دریافت موفق روی دیسک نگه داشته می‌شود تا بدون اینترنت هم
///   وضعیت بسته‌های دانلودشده دیده شود.
/// - هر فایل اول در «.part» نوشته می‌شود؛ مکث و ادامه با سرآیند Range از همان‌جا ادامه می‌دهد.
/// - پس از کامل شدن، sha256 بررسی و فایل جابه‌جا می‌شود؛ فایل نیمه‌کاره هرگز پخش نمی‌شود.
/// - پر شدن حافظه خطای جدا («حافظه کافی نیست») دارد.
class DownloadManager extends ChangeNotifier {
  DownloadManager(this.resolver, {http.Client? client}) : _client = client ?? http.Client();

  final AssetResolver resolver;
  final http.Client _client;

  List<AssetPack> _packs = const [];
  final Map<String, double> _progress = {};
  final Set<String> _pauseRequested = {};
  final Set<String> _paused = {};
  final Map<String, DownloadError> _errors = {};
  DownloadError? _indexError;
  bool _loading = false;
  bool _offlineIndex = false;

  List<AssetPack> get packs => _packs;
  DownloadError? get indexError => _indexError;
  DownloadError? errorFor(String packId) => _errors[packId];
  bool get loading => _loading;

  /// فهرست از نسخه‌ی ذخیره‌شده روی دستگاه آمده، نه از سرور.
  bool get offlineIndex => _offlineIndex;
  bool get configured => resolver.config.remoteEnabled;
  bool get available => configured && !kIsWeb && resolver.cacheDir != null;

  File? get _indexFile =>
      resolver.cacheDir == null ? null : File('${resolver.cacheDir!.parent.path}/packs-${resolver.config.version}.json');

  PackStatus status(AssetPack p) {
    if (_progress.containsKey(p.id)) return PackStatus.downloading;
    if (_paused.contains(p.id)) return PackStatus.paused;
    final have = p.files.where((f) => resolver.isDownloaded(f.path)).length;
    if (have == 0) return PackStatus.notDownloaded;
    return have == p.files.length ? PackStatus.ready : PackStatus.partial;
  }

  double progress(AssetPack p) {
    if (_progress.containsKey(p.id)) return _progress[p.id]!;
    final total = p.totalBytes;
    if (total == 0) return 0;
    final have = p.files.where((f) => resolver.isDownloaded(f.path)).fold(0, (a, f) => a + f.size);
    return have / total;
  }

  int get usedBytes {
    var n = 0;
    for (final p in _packs) {
      for (final f in p.files) {
        if (resolver.isDownloaded(f.path)) n += f.size;
      }
    }
    return n;
  }

  Future<void> refresh() async {
    if (!available) return;
    _loading = true;
    _indexError = null;
    notifyListeners();
    try {
      final res = await _client.get(resolver.config.packIndex).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw HttpException('HTTP ${res.statusCode}');
      final body = utf8.decode(res.bodyBytes);
      _packs = parseIndex(body);
      _offlineIndex = false;
      final f = _indexFile;
      if (f != null) {
        await f.parent.create(recursive: true);
        await f.writeAsString(body);
      }
    } catch (e) {
      _indexError = const DownloadError(
        DownloadErrorKind.network,
        'اتصال به سرور برقرار نشد. بسته‌های ذخیره‌شده همچنان بدون اینترنت کار می‌کنند.',
      );
      debugPrint('packs.json دریافت نشد: $e');
      final f = _indexFile;
      if (f != null && await f.exists()) {
        _packs = parseIndex(await f.readAsString());
        _offlineIndex = true;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @visibleForTesting
  static List<AssetPack> parseIndex(String body) {
    final j = jsonDecode(body) as Map<String, dynamic>;
    return [for (final p in (j['packs'] ?? const []) as List) AssetPack.fromJson(Map<String, dynamic>.from(p as Map))];
  }

  void pause(AssetPack pack) {
    if (_progress.containsKey(pack.id)) {
      _pauseRequested.add(pack.id);
      notifyListeners();
    }
  }

  Future<void> download(AssetPack pack) async {
    if (_progress.containsKey(pack.id) || !pack.compatible) return;
    _paused.remove(pack.id);
    _pauseRequested.remove(pack.id);
    _errors.remove(pack.id);
    _progress[pack.id] = progress(pack);
    notifyListeners();
    final total = pack.totalBytes == 0 ? pack.files.length : pack.totalBytes;
    var done = 0;
    try {
      for (final f in pack.files) {
        if (!resolver.isDownloaded(f.path)) {
          final finished = await _downloadFile(pack, f, (bytes) {
            _progress[pack.id] = (done + (pack.totalBytes == 0 ? 0 : bytes)) / total;
            notifyListeners();
          });
          if (!finished) {
            _paused.add(pack.id);
            break;
          }
        }
        done += pack.totalBytes == 0 ? 1 : f.size;
        _progress[pack.id] = done / total;
        notifyListeners();
      }
    } on FileSystemException catch (e) {
      final full = (e.osError?.errorCode ?? 0) == 28 || e.message.toLowerCase().contains('space');
      _errors[pack.id] = full
          ? const DownloadError(DownloadErrorKind.storage, 'حافظه‌ی دستگاه کافی نیست. کمی جا باز کنید و دوباره امتحان کنید.')
          : DownloadError(DownloadErrorKind.storage, 'ذخیره‌ی فایل ممکن نشد (${e.message}).');
    } on FormatException {
      _errors[pack.id] = const DownloadError(DownloadErrorKind.checksum, 'فایل دریافتی سالم نبود. دوباره امتحان کنید.');
    } on HttpException catch (e) {
      _errors[pack.id] = DownloadError(DownloadErrorKind.server, 'سرور پاسخ درستی نداد (${e.message}).');
    } catch (e) {
      _errors[pack.id] = const DownloadError(DownloadErrorKind.network, 'اتصال قطع شد. هر وقت اینترنت بود «ادامه» را بزنید.');
      debugPrint('دانلود بسته شکست خورد: $e');
    } finally {
      _progress.remove(pack.id);
      _pauseRequested.remove(pack.id);
      await resolver.rescan();
      notifyListeners();
    }
  }

  /// یک فایل را (با ادامه از .part موجود) دانلود می‌کند. اگر مکث خواسته شود false برمی‌گرداند.
  Future<bool> _downloadFile(AssetPack pack, PackFile f, void Function(int bytes) onBytes) async {
    final target = resolver.localFileFor(f.path)!;
    final part = File('${target.path}.part');
    await part.parent.create(recursive: true);
    var have = await part.exists() ? await part.length() : 0;
    if (f.size > 0 && have > f.size) {
      await part.delete();
      have = 0;
    }
    final req = http.Request('GET', resolver.config.file(f.path));
    if (have > 0) req.headers['Range'] = 'bytes=$have-';
    final res = await _client.send(req).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200 && have > 0) {
      // سرور Range را نپذیرفت: از اول.
      await part.delete();
      have = 0;
    } else if (res.statusCode != 200 && res.statusCode != 206) {
      throw HttpException('HTTP ${res.statusCode} برای ${f.path}');
    }
    final sink = part.openWrite(mode: FileMode.append);
    var got = have;
    var paused = false;
    try {
      await for (final chunk in res.stream.timeout(const Duration(seconds: 30))) {
        sink.add(chunk);
        got += chunk.length;
        onBytes(got);
        if (_pauseRequested.contains(pack.id)) {
          paused = true;
          break;
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
    if (paused) return false;
    if (f.sha256.isNotEmpty) {
      final digest = await sha256.bind(part.openRead()).first;
      if (digest.toString() != f.sha256) {
        await part.delete();
        throw const FormatException('sha256 فایل دانلودشده با فهرست نمی‌خواند');
      }
    }
    await part.rename(target.path);
    return true;
  }

  Future<void> remove(AssetPack pack) async {
    _paused.remove(pack.id);
    for (final f in pack.files) {
      final file = resolver.localFileFor(f.path);
      if (file == null) continue;
      if (await file.exists()) await file.delete();
      final part = File('${file.path}.part');
      if (await part.exists()) await part.delete();
    }
    await resolver.rescan();
    notifyListeners();
  }
}
