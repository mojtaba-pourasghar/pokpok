import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme/theme.dart';

class PopoApp extends ConsumerStatefulWidget {
  const PopoApp({super.key});

  @override
  ConsumerState<PopoApp> createState() => _PopoAppState();
}

class _PopoAppState extends ConsumerState<PopoApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // با رفتن به پس‌زمینه همه‌چیز روی دیسک نوشته می‌شود تا اگر سیستم برنامه را بست، چیزی گم نشود.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      ref.read(storeProvider).flush();
    }
    // دروازه‌ی والدین با رفتن به پس‌زمینه بسته می‌شود.
    if (state == AppLifecycleState.paused) ref.read(parentGateProvider.notifier).lock();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      title: 'پوپو',
      debugShowCheckedModeBanner: false,
      theme: buildPopoTheme(),
      locale: const Locale('fa', 'IR'),
      supportedLocales: const [Locale('fa', 'IR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // متن با بزرگ‌نمایی سیستم (و تنظیم «متن درشت») بزرگ می‌شود، ولی نه آن‌قدر که چیدمان بشکند.
        final scaler = settings.largeText
            ? TextScaler.linear((mq.textScaler.scale(1) * 1.2).clamp(1.2, 1.4))
            : mq.textScaler.clamp(maxScaleFactor: 1.4);
        return MediaQuery(
          data: mq.copyWith(textScaler: scaler, disableAnimations: mq.disableAnimations || settings.reducedMotion),
          child: Directionality(textDirection: TextDirection.rtl, child: child!),
        );
      },
    );
  }
}
