import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

import 'asset_config.dart';

enum AssetSource { downloaded, bundled }

class ResolvedAsset {
  const ResolvedAsset.bundled(this.key) : source = AssetSource.bundled;
  const ResolvedAsset.file(this.key) : source = AssetSource.downloaded;

  final AssetSource source;

  /// کلید asset در حالت bundled، یا مسیر کامل فایل در حالت downloaded.
  final String key;
}

/// لایه‌ی مرکزی دسترسی به دارایی‌ها (صداها) با مسیر منطقی (مثل audio/sfx/pop.mp3).
///
/// ترتیب جست‌وجو:
///   ۱. فایل دانلودشده از CDN (نسخه‌ی تازه‌تر یا بسته‌ی اضافه)
///   ۲. فایل داخل خود برنامه (همیشه بدون اینترنت در دسترس)
class AssetResolver extends ChangeNotifier {
  AssetResolver({this.config = const AssetConfig()});

  final AssetConfig config;

  Set<String> _bundled = const {};
  final Set<String> _downloaded = {};
  Directory? _cacheDir;

  Directory? get cacheDir => _cacheDir;

  Future<void> init(AssetBundle bundle) async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(bundle);
      _bundled = manifest.listAssets().toSet();
    } catch (e) {
      debugPrint('فهرست دارایی‌های داخلی خوانده نشد: $e');
    }
    if (!kIsWeb) {
      try {
        final support = await getApplicationSupportDirectory();
        _cacheDir = Directory('${support.path}/popo_assets/${config.version}');
        await rescan();
      } catch (e) {
        debugPrint('پوشه‌ی دارایی‌های دانلودشده در دسترس نیست: $e');
      }
    }
  }

  @visibleForTesting
  void setBundled(Set<String> keys) => _bundled = keys;

  @visibleForTesting
  Future<void> useCacheDir(Directory dir) async {
    _cacheDir = dir;
    await rescan();
  }

  Future<void> rescan() async {
    _downloaded.clear();
    final dir = _cacheDir;
    if (dir != null && await dir.exists()) {
      await for (final e in dir.list(recursive: true, followLinks: false)) {
        if (e is File && !e.path.endsWith('.part')) {
          _downloaded.add(e.path.substring(dir.path.length + 1).replaceAll('\\', '/'));
        }
      }
    }
    notifyListeners();
  }

  File? localFileFor(String logicalPath) => _cacheDir == null ? null : File('${_cacheDir!.path}/$logicalPath');

  bool isDownloaded(String logicalPath) => _downloaded.contains(logicalPath);
  bool isBundled(String logicalPath) => _bundled.contains('assets/$logicalPath');
  bool exists(String logicalPath) => isDownloaded(logicalPath) || isBundled(logicalPath);

  ResolvedAsset? resolve(String logicalPath) {
    if (isDownloaded(logicalPath)) return ResolvedAsset.file('${_cacheDir!.path}/$logicalPath');
    if (isBundled(logicalPath)) return ResolvedAsset.bundled('assets/$logicalPath');
    return null;
  }
}
