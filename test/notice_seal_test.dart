import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/notices/notice_seal.dart';

import 'notice_fixtures.dart';

void main() {
  final seal = NoticeSeal.fromPem(fixturePublicKey)!;

  test('کلید عمومی PEM خوانده می‌شود؛ خالی، خراب و کوتاه‌تر از ۲۰۴۸ بیت نه', () {
    expect(NoticeSeal.fromPem(fixturePublicKey), isNotNull);
    expect(NoticeSeal.fromPem(''), isNull);
    expect(NoticeSeal.fromPem('-----BEGIN PUBLIC KEY-----\nAAAA\n-----END PUBLIC KEY-----'), isNull);
    expect(NoticeSeal.fromPem('not base64 at all!'), isNull);
    expect(NoticeSeal.fromPem(fixtureSmallKey), isNull);
  });

  test('امضای Node (crypto.sign sha256) پذیرفته می‌شود', () {
    final bytes = seal.unseal(fixtureOne);
    expect(bytes, isNotNull);
    final json = jsonDecode(utf8.decode(bytes!)) as Map<String, dynamic>;
    expect((json['notices'] as List).single['id'], 'n1');
  });

  test('امضا با کلید دیگر رد می‌شود', () {
    expect(seal.unseal(fixtureForged), isNull);
    expect(NoticeSeal.fromPem(fixtureOtherKey)!.unseal(fixtureForged), isNotNull);
  });

  test('دست بردن در متن یا امضا رد می‌شود', () {
    final env = jsonDecode(fixtureOne) as Map<String, dynamic>;
    final body = base64.decode(env['body'] as String);
    final changed = [...body]..[body.length - 3] ^= 1;
    expect(seal.verify(changed, env['sig'] as String), isFalse);
    expect(seal.verify(body, env['sig'] as String), isTrue);

    final sig = base64.decode(env['sig'] as String);
    final badSig = [...sig]..[10] ^= 1;
    expect(seal.verify(body, base64.encode(badSig)), isFalse);
    expect(seal.verify(body, base64.encode(sig.sublist(1))), isFalse);
    expect(seal.verify(body, '%%%'), isFalse);
    expect(seal.verify(const [], env['sig'] as String), isFalse);
  });

  test('پاکت نادرست null است، نه استثنا', () {
    final env = jsonDecode(fixtureOne) as Map<String, dynamic>;
    expect(seal.unseal('not json'), isNull);
    expect(seal.unseal('[]'), isNull);
    expect(seal.unseal(jsonEncode({...env, 'alg': 'none'})), isNull);
    expect(seal.unseal(jsonEncode({...env, 'sig': 1})), isNull);
    expect(seal.unseal(jsonEncode({...env, 'body': '***'})), isNull);
  });
}
