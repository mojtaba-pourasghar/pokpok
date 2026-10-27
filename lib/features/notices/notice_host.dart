import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/theme.dart';
import '../../core/narrator.dart';
import '../../core/notices/notices_store.dart';
import '../../core/platform/native_bridge.dart';
import '../paywall/paywall.dart';
import 'notice_card.dart';

/// خبرها وقتی برنامه باز است — همان NoticeHost گوش‌یار، برای GoRouter.
///
/// هیچ سرویس پوشی نیست، پس برنامه خودش نگاه می‌کند: یک بار همین که باز شد و بعد هر [every]. وقتی
/// برنامه بسته است، NoticeWork.kt و NoticeAlarm.kt همین کار را حدود هر ربع ساعت می‌کنند.
///
/// هر چه برسد، یکی به نوار اعلان می‌رود و یکی به شکل کارت روی صفحه می‌آید، و بعدی نه زودتر از
/// [NoticesStore.gap]. خبر معمولی منتظر نقشه می‌ماند — وسط بازی مزاحم کودک نمی‌شود. خبری که «هر جای
/// برنامه» (ANYWHERE) علامت خورده هر جا باشد می‌آید، جز آغاز، معرفی، نمایه‌ها و بخش والدین.
class NoticeHost extends ConsumerStatefulWidget {
  const NoticeHost({super.key, required this.child});

  final Widget child;

  static const every = Duration(minutes: 1);

  @override
  ConsumerState<NoticeHost> createState() => _NoticeHostState();
}

class _NoticeHostState extends ConsumerState<NoticeHost> with WidgetsBindingObserver {
  static bool _never(String loc) =>
      loc == '/' || loc == '/intro' || loc == '/profiles' || loc.startsWith('/parent') || loc.startsWith('/settings');

  Timer? _beat;
  Timer? _soon;
  Timer? _next;
  bool _showing = false;
  bool _askedPermission = false;
  bool _listening = false;
  String? _requested;
  String _requestedScreen = '';
  String _version = '';
  late final NoticesStore store = ref.read(noticesProvider);
  late final GoRouter _router = ref.read(routerProvider);
  late final PopupWatcher _popups = ref.read(popupWatcherProvider);

  NativeBridge get bridge => store.bridge;

  @override
  void initState() {
    super.initState();
    if (!store.ready) return;
    _listening = true;
    WidgetsBinding.instance.addObserver(this);
    _router.routerDelegate.addListener(_onRoute);
    NativeBridge.listen(onNoticeTapped: _tapped, onPermission: (_) => _soonCheck());
    bridge.appVersion().then((v) => _version = v);
    bridge.takeLaunchNotice().then((tap) {
      if (tap != null) _tapped(tap);
    });
    _start();
  }

  @override
  void dispose() {
    if (_listening) {
      WidgetsBinding.instance.removeObserver(this);
      _router.routerDelegate.removeListener(_onRoute);
    }
    _beat?.cancel();
    _soon?.cancel();
    _next?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.paused) {
      // بسته شدن را NoticeWork.once در MainActivity.onPause پوشش می‌دهد؛ این‌جا فقط ساعت‌ها می‌ایستند.
      _beat?.cancel();
      _beat = null;
      _next?.cancel();
      _next = null;
    }
  }

  void _start() {
    _beat?.cancel();
    _beat = Timer.periodic(NoticeHost.every, (_) => _look());
    // آنچه NoticeCenter.kt وقتی برنامه پشت صحنه بود گرفته، در حافظه‌ی Dart هنوز نیست.
    _look(reload: true);
  }

  Future<void> _look({bool reload = false}) async {
    if (!store.enabled) return;
    if (reload) await store.reloadFromDisk();
    await store.refresh();
    if (!mounted) return;
    unawaited(bridge.postNotices());
    unawaited(_showIfDue());
    if (!_showing) unawaited(_askIfUseful());
    _planNext();
  }

  /// خبری که «از ساعت فلان» گذاشته شده سر همان دقیقه می‌آید، نه در نگاه بعدی به سرور.
  void _planNext() {
    _next?.cancel();
    _next = null;
    final wait = store.nextStartIn();
    if (wait == null) return;
    _next = Timer(wait + const Duration(milliseconds: 500), () {
      if (!mounted) return;
      unawaited(bridge.postNotices());
      unawaited(_showIfDue());
      _planNext();
    });
  }

  /// اجازه‌ی اعلان فقط وقتی پرسیده می‌شود که چیزی برای گفتن باشد — اولین اجرای کودک یک بازی است، نه
  /// پنجره‌ی اجازه. صفحه‌ی تنظیمات این‌جا خودبه‌خود باز نمی‌شود — آن فقط از بخش والدین است.
  Future<void> _askIfUseful() async {
    if (_askedPermission || store.current.isEmpty) return;
    _askedPermission = true;
    if (await bridge.notificationsAllowed()) {
      unawaited(bridge.askBackgroundOnce());
      return;
    }
    await bridge.requestNotifications(openSettings: false);
  }

  void _onRoute() => _soonCheck(const Duration(milliseconds: 450));

  void _soonCheck([Duration after = const Duration(milliseconds: 300)]) {
    _soon?.cancel();
    _soon = Timer(after, () {
      if (mounted) unawaited(_showIfDue());
    });
  }

  /// لمس یک اعلان در نوار: کودک همین خبر را خواسته، پس از همه‌ی نوبت‌ها جلو می‌افتد.
  Future<void> _tapped(NoticeTap tap) async {
    await store.reloadFromDisk();
    if (store.find(tap.id) == null) await store.refresh();
    _requested = tap.id;
    _requestedScreen = tap.screen;
    _soonCheck();
  }

  String get _location => _router.routerDelegate.currentConfiguration.uri.path;

  BuildContext? get _navContext => _router.routerDelegate.navigatorKey.currentContext;

  Future<void> _showIfDue() async {
    if (!mounted || _showing || !store.ready || !store.enabled) return;
    final ctx = _navContext;
    final loc = _location;
    if (ctx == null || _never(loc) || _popups.open > 0) return;

    final asked = _requested;
    if (asked != null) {
      final screen = _requestedScreen;
      _requested = null;
      _requestedScreen = '';
      final n = store.find(asked);
      if (n != null) await store.markSeen(n.id);
      if (!ctx.mounted) return;
      if (screen.isNotEmpty && await openNoticeScreen(ctx, screen)) return;
      if (n != null) return _put(n);
    }

    final onHome = loc == '/map';
    if (onHome && store.updateDue(_version)) return _putUpdate(store.updateWaiting(_version)!);

    final due = store.dueNow(onHome: onHome);
    if (due != null) await _put(due);
  }

  /// یک خبر به شکل کارت. هر طور بسته شود «دیده شد» و فاصله تا بعدی از همین حالا شمرده می‌شود.
  Future<void> _put(Notice n) async {
    final ctx = _navContext;
    if (ctx == null) return;
    _showing = true;
    await store.shown();
    try {
      if (!ctx.mounted) return;
      unawaited(ref.say('notice.new'));
      final action = await showNoticeCard(ctx, store, n);
      await store.markSeen(n.id);
      await store.shown();
      final now = _navContext;
      if (action == NoticeAction.go && now != null && now.mounted) await followNotice(now, ref, store, n);
    } finally {
      _showing = false;
    }
    // حالا که کودک خبر را دید، وقت پرسیدن اجازه برای خبرهای بعدی در نوار اعلان است.
    unawaited(_askIfUseful());
    _soonCheck(NoticesStore.gap + const Duration(milliseconds: 500));
    _planNext();
  }

  /// «نسخه‌ی تازه آمده»، حداکثر روزی یک بار؛ دانلود فقط پشت دروازه‌ی والدین.
  Future<void> _putUpdate(AppUpdate u) async {
    final ctx = _navContext;
    if (ctx == null) return;
    _showing = true;
    await store.askedAboutUpdate();
    try {
      if (!ctx.mounted) return;
      final get = await showDialog<bool>(
        context: ctx,
        builder: (context) => AlertDialog(
          title: const Text('نسخه‌ی تازه‌ی پوپو', style: PText.heading),
          content: Text(u.note.isEmpty ? 'نسخه‌ی ${u.version} آمده است.' : u.note, style: PText.body),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('بعداً')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('دریافت')),
          ],
        ),
      );
      final now = _navContext;
      if (get == true && now != null && now.mounted && await verifyParent(now, ref)) await bridge.openUrl(u.url);
    } finally {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
