import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// مُهر خبرها: نشان می‌دهد یک خبر را خود سازنده‌ی پوپو نوشته، نه کسی که به CDN یا مسیر دسترسی پیدا کرده.
///
/// کلید امضا در برنامه نیست؛ استودیو (tools/voice-studio، تب «خبرها») آن را یک بار می‌سازد و روی
/// همان رایانه نگه می‌دارد. فقط نیمه‌ی عمومی در assets/notices/notice-key.pub همراه برنامه است و
/// نیمه‌ی عمومی فقط می‌تواند امضا را بیازماید، نه امضا کند.
///
/// شکل فایلی که از CDN می‌آید (یک فایل، تا cache هیچ‌وقت متن و امضای ناهمخوان نشان ندهد):
///
///     {"alg": "RSA-SHA256", "body": "<base64 بایت‌های خبرها>", "sig": "<base64 امضا>"}
///
/// امضا روی همان بایت‌هایی آزموده می‌شود که رسیده‌اند، نه روی JSON دوباره ساخته‌شده.
/// هر چیز نادرست (کلید نیست، امضا نیست، امضا نمی‌خواند) یعنی «خبری نیست».
///
/// RSA PKCS#1 v1.5 با SHA-256 (همان `crypto.sign("sha256", …)` در Node و `SHA256withRSA` در جاوا)،
/// با BigInt خود Dart؛ بسته‌ی crypto فقط درهم‌سازی دارد.
class NoticeSeal {
  NoticeSeal._(this._n, this._e, this._k);

  final BigInt _n;
  final BigInt _e;

  /// طول کلید به بایت (۲۵۶ برای ۲۰۴۸ بیت).
  final int _k;

  /// OID rsaEncryption (1.2.840.113549.1.1.1) با برچسب و طولش.
  static const _rsaOid = [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01];

  /// DigestInfo برای SHA-256، پیش از خودِ درهم‌سازی (RFC 8017، بخش ۹.۲).
  static const _sha256Prefix = [
    0x30, 0x31, 0x30, 0x0d, 0x06, 0x09, 0x60, 0x86, 0x48, 0x01, 0x65, 0x03, 0x04, 0x02, 0x01, 0x05, 0x00, 0x04, 0x20,
  ];

  /// کلید عمومی PEM (SubjectPublicKeyInfo)؛ خالی، خراب یا کوتاه‌تر از ۲۰۴۸ بیت → null.
  static NoticeSeal? fromPem(String pem) {
    final text = pem.replaceAll(RegExp(r'-----[A-Z ]+-----'), '').replaceAll(RegExp(r'\s'), '');
    if (text.isEmpty) return null;
    try {
      final spki = _Der(base64.decode(text)).read(0x30);
      final outer = _Der(spki);
      final algorithm = outer.read(0x30);
      if (algorithm.length < _rsaOid.length) return null;
      for (var i = 0; i < _rsaOid.length; i++) {
        if (algorithm[i] != _rsaOid[i]) return null;
      }
      final bits = outer.read(0x03);
      if (bits.isEmpty || bits[0] != 0) return null;
      final rsa = _Der(_Der(Uint8List.sublistView(bits, 1)).read(0x30));
      final n = _toBig(rsa.read(0x02));
      final e = _toBig(rsa.read(0x02));
      if (n.bitLength < 2048 || e < BigInt.from(3)) return null;
      return NoticeSeal._(n, e, (n.bitLength + 7) >> 3);
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  /// آیا [signature] (base64) امضای درست روی [body] است؟
  bool verify(List<int> body, String signature) {
    if (body.isEmpty) return false;
    final Uint8List sig;
    try {
      sig = base64.decode(signature.trim());
    } on FormatException {
      return false;
    }
    if (sig.length != _k) return false;
    final s = _toBig(sig);
    if (s >= _n) return false;
    final em = _toBytes(s.modPow(_e, _n), _k);
    if (em == null) return false;

    final t = [..._sha256Prefix, ...sha256.convert(body).bytes];
    if (_k < t.length + 11) return false;
    final expected = Uint8List(_k);
    expected[1] = 0x01;
    for (var i = 2; i < _k - t.length - 1; i++) {
      expected[i] = 0xff;
    }
    expected.setRange(_k - t.length, _k, t);

    var diff = 0;
    for (var i = 0; i < _k; i++) {
      diff |= em[i] ^ expected[i];
    }
    return diff == 0;
  }

  /// پاکت رسیده از CDN را باز می‌کند: بایت‌های خبرها اگر امضا درست باشد، وگرنه null.
  Uint8List? unseal(String envelope) {
    try {
      final root = jsonDecode(envelope);
      if (root is! Map || root['alg'] != 'RSA-SHA256') return null;
      final body = root['body'];
      final sig = root['sig'];
      if (body is! String || sig is! String) return null;
      final bytes = base64.decode(body);
      return verify(bytes, sig) ? bytes : null;
    } on FormatException {
      return null;
    }
  }

  static BigInt _toBig(List<int> bytes) {
    var r = BigInt.zero;
    for (final b in bytes) {
      r = (r << 8) | BigInt.from(b);
    }
    return r;
  }

  static Uint8List? _toBytes(BigInt value, int length) {
    final out = Uint8List(length);
    var v = value;
    final mask = BigInt.from(0xff);
    for (var i = length - 1; i >= 0; i--) {
      out[i] = (v & mask).toInt();
      v >>= 8;
    }
    return v == BigInt.zero ? out : null;
  }
}

/// خواننده‌ی کوچک DER: فقط همان چند برچسبی که یک کلید عمومی RSA دارد.
class _Der {
  _Der(this._b);

  final Uint8List _b;
  int _i = 0;

  Uint8List read(int tag) {
    if (_i + 2 > _b.length || _b[_i] != tag) throw const FormatException('DER');
    var len = _b[_i + 1];
    _i += 2;
    if (len & 0x80 != 0) {
      final count = len & 0x7f;
      if (count == 0 || count > 4 || _i + count > _b.length) throw const FormatException('DER');
      len = 0;
      for (var j = 0; j < count; j++) {
        len = (len << 8) | _b[_i++];
      }
    }
    if (_i + len > _b.length) throw const FormatException('DER');
    final out = Uint8List.sublistView(_b, _i, _i + len);
    _i += len;
    return out;
  }
}
