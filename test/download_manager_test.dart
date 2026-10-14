import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/assets/asset_config.dart';
import 'package:popo/core/assets/asset_resolver.dart';
import 'package:popo/core/assets/download_manager.dart';

/// یک «CDN» محلی که مثل Worker رفتار می‌کند: GET، Range ← 206، و پخش تکه‌تکه با مکث.
class FakeCdn {
  final Map<String, List<int>> files = {};
  final List<String> rangeRequests = [];
  late HttpServer server;
  Duration chunkDelay = Duration.zero;

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final path = req.uri.path.replaceFirst('/popo/v1/', '');
      final body = files[path];
      if (body == null) {
        req.response.statusCode = 404;
        await req.response.close();
        return;
      }
      var start = 0;
      final range = req.headers.value('range');
      if (range != null) {
        rangeRequests.add(range);
        start = int.parse(RegExp(r'bytes=(\d+)-').firstMatch(range)!.group(1)!);
        req.response.statusCode = 206;
      }
      final part = body.sublist(start);
      req.response.contentLength = part.length;
      try {
        for (var i = 0; i < part.length; i += 1000) {
          req.response.add(part.sublist(i, i + 1000 > part.length ? part.length : i + 1000));
          await req.response.flush();
          if (chunkDelay > Duration.zero) await Future<void>.delayed(chunkDelay);
        }
        await req.response.close();
      } catch (_) {}
    });
  }

  String get base => 'http://127.0.0.1:${server.port}';

  void addPack(String id, Map<String, List<int>> content, {int minApp = 1, bool badSha = false}) {
    files.addAll(content);
    final index = files['packs.json'] == null ? {'version': 'v1', 'packs': []} : jsonDecode(utf8.decode(files['packs.json']!)) as Map;
    (index['packs'] as List).add({
      'id': id,
      'title': id,
      'minApp': minApp,
      'files': [
        for (final e in content.entries)
          {'path': e.key, 'size': e.value.length, 'sha256': badSha ? '0' * 64 : sha256.convert(e.value).toString()},
      ],
    });
    files['packs.json'] = utf8.encode(jsonEncode(index));
  }
}

void main() {
  late FakeCdn cdn;
  late Directory dir;
  late AssetResolver resolver;
  late DownloadManager dm;

  setUp(() async {
    cdn = FakeCdn();
    await cdn.start();
    dir = await Directory.systemTemp.createTemp('popo_dl');
    resolver = AssetResolver(
      config: AssetConfig(cdnBase: cdn.base, version: 'v1'),
    );
    await resolver.useCacheDir(Directory('${dir.path}/popo_assets/v1'));
    dm = DownloadManager(resolver);
  });

  tearDown(() async {
    await cdn.server.close(force: true);
    await dir.delete(recursive: true);
  });

  List<int> bytes(int n, int seed) => List<int>.generate(n, (i) => (i * 31 + seed) % 256);

  test('downloads a pack, verifies sha256 and the files override bundled ones', () async {
    cdn.addPack('voice-fa', {'audio/voice/a.mp3': bytes(5000, 1), 'audio/voice/b.mp3': bytes(3000, 2)});
    await dm.refresh();
    expect(dm.packs.single.totalBytes, 8000);
    final p = dm.packs.single;
    expect(dm.status(p), PackStatus.notDownloaded);
    await dm.download(p);
    expect(dm.errorFor(p.id), isNull);
    expect(dm.status(p), PackStatus.ready);
    expect(resolver.isDownloaded('audio/voice/a.mp3'), isTrue);
    expect(resolver.resolve('audio/voice/a.mp3')!.source, AssetSource.downloaded);
    expect(await File('${resolver.cacheDir!.path}/audio/voice/b.mp3').readAsBytes(), bytes(3000, 2));
    expect(dm.usedBytes, 8000);

    await dm.remove(p);
    expect(dm.status(p), PackStatus.notDownloaded);
    expect(resolver.isDownloaded('audio/voice/a.mp3'), isFalse);
  });

  test('a checksum mismatch leaves no file behind and reports it', () async {
    cdn.addPack('bad', {'audio/sfx/x.mp3': bytes(2000, 3)}, badSha: true);
    await dm.refresh();
    await dm.download(dm.packs.single);
    expect(dm.errorFor('bad')!.kind, DownloadErrorKind.checksum);
    expect(resolver.isDownloaded('audio/sfx/x.mp3'), isFalse);
    expect(File('${resolver.cacheDir!.path}/audio/sfx/x.mp3.part').existsSync(), isFalse);
  });

  test('an interrupted download resumes with a Range request from the partial file', () async {
    final data = bytes(10000, 4);
    cdn.addPack('art', {'art/animals/cow.webp': data});
    await dm.refresh();
    final part = File('${resolver.cacheDir!.path}/art/animals/cow.webp.part');
    await part.parent.create(recursive: true);
    await part.writeAsBytes(data.sublist(0, 4000));
    await dm.download(dm.packs.single);
    expect(cdn.rangeRequests, ['bytes=4000-']);
    expect(dm.status(dm.packs.single), PackStatus.ready);
    expect(await File('${resolver.cacheDir!.path}/art/animals/cow.webp').readAsBytes(), data);
    // تصویر رستری دانلودشده جای طرح برداری هم‌نام را می‌گیرد.
    expect(resolver.rasterOverride('art/animals/cow.svg'), 'art/animals/cow.webp');
    expect(resolver.rasterOverride('art/animals/sheep.svg'), isNull);
  });

  test('pause stops mid-file; resume finishes it', () async {
    final data = bytes(20000, 5);
    cdn
      ..chunkDelay = const Duration(milliseconds: 20)
      ..addPack('music', {'audio/music/x.mp3': data});
    await dm.refresh();
    final p = dm.packs.single;
    final running = dm.download(p);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(dm.status(p), PackStatus.downloading);
    dm.pause(p);
    await running;
    expect(dm.status(p), PackStatus.paused);
    expect(resolver.isDownloaded('audio/music/x.mp3'), isFalse);
    cdn.chunkDelay = Duration.zero;
    await dm.download(p);
    expect(dm.status(p), PackStatus.ready);
    expect(cdn.rangeRequests, hasLength(1));
    expect(await File('${resolver.cacheDir!.path}/audio/music/x.mp3').readAsBytes(), data);
  });

  test('offline: the cached index is used and downloaded packs stay usable', () async {
    cdn.addPack('voice-fa', {'audio/voice/a.mp3': bytes(1000, 6)});
    await dm.refresh();
    await dm.download(dm.packs.single);
    await cdn.server.close(force: true);

    final again = DownloadManager(resolver);
    await again.refresh();
    expect(again.offlineIndex, isTrue);
    expect(again.indexError!.kind, DownloadErrorKind.network);
    expect(again.status(again.packs.single), PackStatus.ready);
    expect(resolver.resolve('audio/voice/a.mp3')!.source, AssetSource.downloaded);
  });

  test('a pack for a newer app is listed but not downloaded', () async {
    cdn.addPack('future', {'art/home/x.webp': bytes(100, 7)}, minApp: AssetConfig.appContentLevel + 1);
    await dm.refresh();
    final p = dm.packs.single;
    expect(p.compatible, isFalse);
    await dm.download(p);
    expect(dm.status(p), PackStatus.notDownloaded);
  });

  test('a new asset version is a separate cache (version change invalidates old files)', () async {
    cdn.addPack('voice-fa', {'audio/voice/a.mp3': bytes(1000, 8)});
    await dm.refresh();
    await dm.download(dm.packs.single);
    final v2 = AssetResolver(
      config: AssetConfig(cdnBase: cdn.base, version: 'v2'),
    );
    await v2.useCacheDir(Directory('${dir.path}/popo_assets/v2'));
    expect(v2.isDownloaded('audio/voice/a.mp3'), isFalse);
    expect(AssetConfig(cdnBase: cdn.base, version: 'v2').file('x').path, '/popo/v2/x');
  });

  test('without a CDN the manager is simply unavailable', () async {
    final local = DownloadManager(AssetResolver(config: const AssetConfig(cdnBase: '')));
    expect(local.configured, isFalse);
    await local.refresh();
    expect(local.packs, isEmpty);
  });
}
