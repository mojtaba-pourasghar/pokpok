import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/assets/asset_config.dart';
import 'package:popo/core/platform/native_bridge.dart';
import 'package:popo/core/notices/notice_seal.dart';
import 'package:popo/core/notices/notices_store.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notice_fixtures.dart';

class _Bridge extends NativeBridge {
  final scheduled = <String?>[];

  @override
  Future<void> scheduleNotices(String? url) async => scheduled.add(url);
}

void main() {
  const config = AssetConfig(cdnBase: 'https://cdn.test/', version: 'v1', noticesBase: 'https://cdn.test/');
  final seal = NoticeSeal.fromPem(fixturePublicKey);
  late List<Uri> requests;
  late _Bridge bridge;
  var now = 1761000000000;

  Future<NoticesStore> make(
    http.Response Function(http.Request) respond, {
    Map<String, Object> prefs = const {},
    bool noSeal = false,
    AssetConfig cfg = config,
  }) async {
    SharedPreferences.setMockInitialValues(prefs);
    final p = await SharedPreferences.getInstance();
    return NoticesStore(
      p,
      seal: noSeal ? null : seal,
      config: cfg,
      bridge: bridge,
      clock: () => now,
      client: MockClient((r) async {
        requests.add(r.url);
        return respond(r);
      }),
    );
  }

  http.Response ok(String body) => http.Response.bytes(body.codeUnits, 200);

  setUp(() {
    requests = [];
    bridge = _Bridge();
    now = 1761000000000;
  });

  test('نشانی خبرها بیرون از پوشه‌ی نسخه است', () {
    expect(config.notices.toString(), 'https://cdn.test/popo/notices.json');
    expect(config.noticeFile('notices/a.webp').toString(), 'https://cdn.test/popo/notices/a.webp');
  });

  test('پیش‌فرض، مثل هوهو ریاضی، هاست خود سازنده است و بی CDN هم کار می‌کند', () {
    const plain = AssetConfig(cdnBase: '');
    expect(plain.remoteEnabled, isFalse);
    expect(plain.noticesEnabled, isTrue);
    expect(plain.notices.toString(), 'https://mp-apdl.ir/popo/notices.json');
  });

  test('خبرهای امضاشده خوانده می‌شوند؛ گذشته و آینده کنار می‌روند', () async {
    final store = await make((_) => ok(fixtureMany));
    expect(store.ready, isTrue);
    expect(store.visible, isFalse);
    await store.refresh();
    // پرسش یکتا در هر نگاه، تا هیچ میانجی نسخه‌ی کهنه را تحویل ندهد.
    expect(requests.single.toString().split('?').first, 'https://cdn.test/popo/notices.json');
    expect(requests.single.queryParameters['t'], '$now');
    expect(store.notices.map((n) => n.id), ['n2', 'n1']);
    expect(store.notices.last.title, 'سلام');
    expect(store.unread, 2);
    expect(store.visible, isTrue);
    expect(store.notices.first.hasLink, isTrue);
    expect(store.notices.first.hasImage, isTrue);
  });

  test('امضای جعلی یا فایل بی‌امضا چیزی را عوض نمی‌کند', () async {
    var body = fixtureOne;
    final store = await make((_) => ok(body));
    await store.refresh();
    expect(store.notices.map((n) => n.id), ['n1']);

    body = fixtureForged;
    await store.refresh();
    expect(store.notices.map((n) => n.id), ['n1']);

    body = '{"notices":[{"id":"x","title":"y"}]}';
    await store.refresh();
    expect(store.notices.map((n) => n.id), ['n1']);
  });

  test('خطای شبکه و ۵۰۰ بی‌صداست؛ ۴۰۴ یعنی خبری نیست', () async {
    var status = 200;
    final store = await make((_) {
      if (status == 0) throw http.ClientException('offline');
      return http.Response.bytes(fixtureOne.codeUnits, status);
    });
    await store.refresh();
    expect(store.notices, hasLength(1));

    status = 0;
    await store.refresh();
    expect(store.notices, hasLength(1));

    status = 500;
    await store.refresh();
    expect(store.notices, hasLength(1));

    status = 404;
    await store.refresh();
    expect(store.notices, isEmpty);
  });

  test('هر نگاه یک درخواست است (مثل هوهو ریاضی)؛ همان فایل یعنی «چیز تازه‌ای نبود»', () async {
    final store = await make((_) => ok(fixtureOne));
    expect(await store.refresh(), isTrue);
    expect(await store.refresh(), isFalse);
    expect(requests, hasLength(2));
    expect(store.lastCheck, contains('چیز تازه‌ای نبود'));
    expect(await store.refresh(forget: true), isTrue);
    expect(requests, hasLength(3));
  });
  test('بی‌کلید یا بی‌CDN هیچ درخواستی فرستاده نمی‌شود', () async {
    final a = await make((_) => ok(fixtureOne), noSeal: true);
    await a.refresh();
    expect(a.ready, isFalse);
    final b = await make((_) => ok(fixtureOne), cfg: const AssetConfig(cdnBase: '', noticesBase: ''));
    await b.refresh();
    expect(b.ready, isFalse);
    expect(requests, isEmpty);
    await b.schedule();
    expect(bridge.scheduled, [null]);
  });

  test('دیده شد: شمارش، پاک شدن شناسه‌های کهنه، کلید مشترک با اندروید', () async {
    final store = await make((_) => ok(fixtureMany), prefs: {NoticesStore.seenKey: 'gone\nn1'});
    await store.refresh();
    expect(store.unread, 1);
    expect(store.isSeen(store.notices.last), isTrue);
    await store.markAllSeen();
    expect(store.unread, 0);
    final p = await SharedPreferences.getInstance();
    expect(p.getString(NoticesStore.seenKey)!.split('\n').toSet(), {'n1', 'n2'});
  });

  test('خاموش کردن: خبری نشان داده نمی‌شود و کار پس‌زمینه خاموش می‌شود', () async {
    final store = await make((_) => ok(fixtureOne));
    await store.refresh();
    await store.setEnabled(false);
    expect(store.notices, isEmpty);
    expect(store.visible, isFalse);
    expect(bridge.scheduled.last, isNull);

    await store.setEnabled(true);
    expect(bridge.scheduled.last, 'https://cdn.test/popo/notices.json');
    expect(store.notices, hasLength(1));
  });

  test('تصویر فقط اگر درهم‌سازی‌اش بخواند پذیرفته می‌شود', () async {
    final store = await make((r) {
      if (r.url.path.endsWith('.webp')) return http.Response.bytes(fixtureImage, 200);
      return ok(fixtureMany);
    });
    await store.refresh();
    final n = store.notices.first;
    expect(await store.image(n), fixtureImage);
    expect(requests.last.toString(), 'https://cdn.test/popo/notices/$fixtureImageSha.webp');

    // بار دوم از حافظه، بی‌درخواست تازه.
    final count = requests.length;
    expect(await store.image(n), fixtureImage);
    expect(requests, hasLength(count));

    final wrong = Notice(id: 'z', title: 't', image: 'notices/z.webp', imageSha256: '0' * 64);
    expect(await store.image(wrong), isNull);
    expect(await store.image(store.notices.last), isNull);
  });

  test('خبر «از ساعت فلان»: برنامه‌ی باز می‌داند چقدر مانده، و سر همان ساعت نوبتش می‌رسد', () async {
    final cache = '{"notices":['
        '{"id":"later","title":"بعداً","screen":"ANYWHERE","from":${now + 90000}},'
        '{"id":"soon","title":"زود","screen":"ANYWHERE","from":${now + 30000}},'
        '{"id":"seen","title":"دیده","from":${now + 10000}},'
        '{"id":"broken","title":"x","from":${now + 5000},"until":${now + 1000}},'
        '{"id":"now","title":"الان","from":${now - 1000}}]}';
    final store = await make((_) => ok(fixtureOne), prefs: {NoticesStore.cacheKey: cache, NoticesStore.seenKey: 'seen\nnow'});
    expect(store.nextStartIn(), const Duration(seconds: 30));
    expect(store.dueNow(onHome: false), isNull);

    now += 30000;
    expect(store.dueNow(onHome: false)?.id, 'soon');
    expect(store.nextStartIn(), const Duration(seconds: 60));

    await store.markSeen('later');
    await store.markSeen('soon');
    expect(store.nextStartIn(), isNull);
  });

  test('پیوند فقط https؛ خبر بی‌شناسه یا بی‌عنوان کنار می‌رود', () {
    final all = Notice.parseAll(
      '{"notices":[{"id":"a","title":"t","link":"http://x"},{"id":"b","title":"t","link":"javascript:x"},'
      '{"id":"c","title":"t","link":"https://x"},{"id":"","title":"t"},{"id":"d"}]}',
    );
    expect(all.map((n) => n.id), ['a', 'b', 'c']);
    expect(all.map((n) => n.hasLink), [false, false, true]);
    expect(Notice.parseAll('garbage'), isEmpty);
  });
}
