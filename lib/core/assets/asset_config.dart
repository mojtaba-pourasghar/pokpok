/// نشانی دارایی‌های راه دور (Cloudflare R2 پشت CDN) در یک جا.
///
/// هیچ کلید یا توکنی اینجا نیست و نباید باشد: برنامه فقط فایل‌های عمومی و نسخه‌دار را با
/// GET می‌خواند. مقدارها هنگام ساخت داده می‌شوند:
///
///     flutter build apk --dart-define=POPO_CDN_BASE=https://assets.example.com \
///                       --dart-define=POPO_ASSET_VERSION=v1
///
/// اگر POPO_CDN_BASE خالی باشد، برنامه فقط با دارایی‌های داخل بسته‌ی نصبی کار می‌کند.
class AssetConfig {
  const AssetConfig({this.cdnBase = _cdnBase, this.version = _version, this.noticesBase = _noticesBase});

  static const _cdnBase = String.fromEnvironment('POPO_CDN_BASE');
  static const _version = String.fromEnvironment('POPO_ASSET_VERSION', defaultValue: 'v1');

  /// خبرها، مثل گوش‌یار، از هاست خود سازنده می‌آیند (استودیو با FTP در public_html/popo می‌گذارد)، نه از
  /// CDN؛ پس بی هیچ --dart-define هم کار می‌کنند. با POPO_NOTICES_BASE عوض می‌شود؛ خالی یعنی «بی خبر».
  static const _noticesBase = String.fromEnvironment('POPO_NOTICES_BASE', defaultValue: 'https://mp-apdl.ir');

  /// نسخه‌ی برنامه برای سنجش سازگاری بسته‌ها (فیلد minApp در packs.json).
  static const appContentLevel = 1;

  final String cdnBase;
  final String version;
  final String noticesBase;

  bool get remoteEnabled => cdnBase.trim().isNotEmpty;

  /// خبرها فقط روی https؛ خالی یعنی «این ساخت خبر نمی‌گیرد».
  bool get noticesEnabled => noticesBase.trim().startsWith('https://');

  static String _trim(String s) => s.trim().endsWith('/') ? s.trim().substring(0, s.trim().length - 1) : s.trim();

  /// خبرهای امضاشده: `noticesBase/popo/notices.json`
  Uri get notices => Uri.parse('${_trim(noticesBase)}/popo/notices.json');

  /// تصویر یک خبر با مسیر نسبی به popo/، مثل notices/3f2a….webp
  Uri noticeFile(String relativePath) => Uri.parse('${_trim(noticesBase)}/popo/$relativePath');

  String get _root {
    final base = cdnBase.endsWith('/') ? cdnBase.substring(0, cdnBase.length - 1) : cdnBase;
    return '$base/popo/$version';
  }

  /// فهرست نسخه‌دار بسته‌ها.
  Uri get packIndex => Uri.parse('$_root/packs.json');

  /// نشانی یک فایل با مسیر منطقی، مثل audio/voice/app_splash_welcome.mp3
  Uri file(String logicalPath) => Uri.parse('$_root/$logicalPath');
}
