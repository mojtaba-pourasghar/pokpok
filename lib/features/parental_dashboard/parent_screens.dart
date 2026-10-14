import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/fa.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/assets/storage_info.dart';
import '../../core/purchases.dart';
import '../../core/storage/local_store.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../profiles/profiles_screen.dart';

final purchaseProvider = ChangeNotifierProvider<PurchaseService>((_) => NoStorePurchaseService());

/// داشبورد والدین (پشت دروازه).
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(activeProfileProvider);
    final progress = ref.watch(progressProvider);
    final today = ref.read(progressProvider.notifier).todaySeconds();
    final tiles = [
      (Icons.face_rounded, 'نمایه‌ی کودکان', '/parent/profiles', PColors.orange),
      (Icons.timer_rounded, 'زمان استفاده', '/parent/usage', PColors.purple),
      (Icons.history_rounded, 'تاریخچه‌ی فعالیت', '/parent/history', PColors.blue),
      (Icons.tune_rounded, 'تنظیمات صدا و حرکت', '/settings', PColors.turquoise),
      (Icons.cloud_download_rounded, 'دانلود محتوا', '/parent/downloads', PColors.success),
      (Icons.sd_storage_rounded, 'فضای ذخیره‌سازی', '/parent/storage', PColors.inkSoft),
      (Icons.privacy_tip_rounded, 'حریم خصوصی', '/parent/privacy', PColors.pink),
      (Icons.shopping_bag_rounded, 'خریدها', '/parent/purchases', PColors.yellow),
    ];
    return PScaffold(
      title: 'پنل والدین',
      onBack: () {
        ref.read(parentGateProvider.notifier).lock();
        context.go('/map');
      },
      actions: [
        PIconButton(
          icon: Icons.lock_rounded,
          label: 'قفل و بازگشت',
          iconColor: PColors.inkSoft,
          onPressed: () {
            ref.read(parentGateProvider.notifier).lock();
            context.go('/map');
          },
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          if (profile != null)
            PCard(
              child: Row(
                children: [
                  ProfileAvatar(profile: profile, size: 64),
                  const SizedBox(width: PSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.name, style: PText.heading),
                        Text('امروز: ${faMinutes(today)} · ${faDigits(progress.stickers.length)} برچسب', style: PText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: PSpace.md),
          LayoutBuilder(
            builder: (context, box) => GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: (box.maxWidth / 170).floor().clamp(2, 4),
              mainAxisSpacing: PSpace.sm,
              crossAxisSpacing: PSpace.sm,
              childAspectRatio: 1.15,
              children: [
                for (final (icon, title, route, color) in tiles)
                  PTile(
                    label: title,
                    onTap: () => context.push(route),
                    color: Colors.white,
                    child: Icon(icon, size: 40, color: color),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ManageProfilesScreen extends ConsumerWidget {
  const ManageProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(profilesProvider);
    return PScaffold(
      title: 'نمایه‌ی کودکان',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          const Text('هر نمایه تنظیمات، برچسب‌ها، نقاشی‌ها و تاریخچه‌ی خودش را دارد.', style: PText.caption),
          const SizedBox(height: PSpace.sm),
          for (final p in s.profiles)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpace.sm),
              child: ChildProfileCard(profile: p, active: p.id == s.active?.id, onTap: () => context.push('/parent/profile/${p.id}')),
            ),
          const SizedBox(height: PSpace.sm),
          PButton(
            label: 'نمایه‌ی تازه',
            icon: Icons.add_rounded,
            color: PColors.success,
            onPressed: () => context.push('/parent/profile/new'),
          ),
        ],
      ),
    );
  }
}

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = ref.watch(progressProvider).history;
    final prefs = ref.watch(appPrefsProvider);
    return PScaffold(
      title: 'تاریخچه‌ی فعالیت',
      actions: [
        if (h.isNotEmpty)
          PIconButton(
            icon: Icons.delete_sweep_rounded,
            label: 'پاک کردن تاریخچه',
            iconColor: PColors.danger,
            onPressed: () async {
              if (await confirm(context, title: 'تاریخچه پاک شود؟', yes: 'پاک کن')) {
                await ref.read(progressProvider.notifier).clearHistory();
              }
            },
          ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(PSpace.md),
            child: PCard(
              padding: const EdgeInsets.all(PSpace.xs),
              child: _PrefSwitch(
                title: 'ثبت تاریخچه روی همین دستگاه',
                subtitle: 'تاریخچه فقط اینجا می‌ماند و به جایی فرستاده نمی‌شود.',
                value: prefs.keepHistory,
                onChanged: (v) => prefs.setKeepHistory(v),
              ),
            ),
          ),
          Expanded(
            child: h.isEmpty
                ? const StateView(state: ViewState.empty, message: 'هنوز فعالیتی ثبت نشده.', compact: true)
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: PSpace.md),
                    itemCount: h.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) => ListTile(
                      leading: const Icon(Icons.play_circle_rounded, color: PColors.blue),
                      title: Text(h[i].title, style: PText.bodyStrong),
                      subtitle: Text(faRelativeDay(h[i].at), style: PText.caption),
                      trailing: Text(faMinutes(h[i].seconds), style: PText.caption),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PrefSwitch extends StatefulWidget {
  const _PrefSwitch({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<_PrefSwitch> createState() => _PrefSwitchState();
}

class _PrefSwitchState extends State<_PrefSwitch> {
  late bool _v = widget.value;

  @override
  Widget build(BuildContext context) => SettingRow(
    icon: Icons.history_toggle_off_rounded,
    title: widget.title,
    subtitle: widget.subtitle,
    trailing: Switch(
      value: _v,
      onChanged: (v) {
        setState(() => _v = v);
        widget.onChanged(v);
      },
    ),
  );
}

class UsageScreen extends ConsumerStatefulWidget {
  const UsageScreen({super.key});

  @override
  ConsumerState<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends ConsumerState<UsageScreen> {
  static const options = [0, 15, 30, 45, 60, 90];
  late int _limit = ref.read(appPrefsProvider).dailyLimitMinutes;

  @override
  Widget build(BuildContext context) {
    final today = ref.read(progressProvider.notifier).todaySeconds();
    return PScaffold(
      title: 'زمان استفاده',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          PCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('امروز', style: PText.heading),
                Text(faMinutes(today), style: PText.title.copyWith(color: PColors.blue)),
                if (_limit > 0) ...[
                  const SizedBox(height: PSpace.xs),
                  PProgressBar(
                    value: today / (_limit * 60),
                    color: today >= _limit * 60 ? PColors.orange : PColors.success,
                    label: 'زمان امروز',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.md),
          const Text('سقف بازی روزانه', style: PText.heading),
          const Text(
            'وقتی زمان تمام شود، پوپو خسته می‌شود و پیشنهاد استراحت می‌دهد. بازی ناگهان قطع نمی‌شود و کودک سرزنش نمی‌شود.',
            style: PText.caption,
          ),
          const SizedBox(height: PSpace.sm),
          Wrap(
            spacing: PSpace.xs,
            runSpacing: PSpace.xs,
            children: [
              for (final m in options)
                ChoiceChip(
                  label: Text(m == 0 ? 'بدون سقف' : '${faDigits(m)} دقیقه'),
                  selected: _limit == m,
                  onSelected: (_) {
                    setState(() => _limit = m);
                    ref.read(appPrefsProvider).setDailyLimit(m);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const points = [
      (
        'همه‌چیز روی همین دستگاه',
        'نمایه‌ها، نقاشی‌ها، آهنگ‌ها، برچسب‌ها و تاریخچه فقط روی این دستگاه ذخیره می‌شوند. حساب کاربری، ثبت‌نام و سرور کاربری در کار نیست.',
      ),
      ('بدون تبلیغ و ردیاب', 'هیچ تبلیغ، کتابخانه‌ی آمار، ردیاب یا شناسه‌ی تبلیغاتی در برنامه نیست.'),
      ('کمترین داده', 'برای نمایه فقط یک نام یا لقب، یک نماد و گروه سنی گرفته می‌شود؛ نه تاریخ تولد، نه عکس، نه مکان.'),
      (
        'اینترنت فقط برای دانلود محتوا',
        'اگر سرور محتوا تنظیم شده باشد، برنامه فقط فایل‌های عمومی بسته‌ها را دانلود می‌کند و هیچ داده‌ای از کودک نمی‌فرستد.',
      ),
      ('بدون گفت‌وگو و نمایه‌ی عمومی', 'هیچ امکان ارتباط با دیگران، گفت‌وگو یا نمایش عمومی در برنامه نیست.'),
      ('کنترل والدین', 'خرید، خروجی گرفتن از نقاشی، پیوندهای بیرونی و تغییر تنظیمات فقط پس از دروازه‌ی والدین ممکن است.'),
    ];
    return PScaffold(
      title: 'حریم خصوصی',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          for (final (t, d) in points)
            Padding(
              padding: const EdgeInsets.only(bottom: PSpace.sm),
              child: PCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t, style: PText.heading),
                    const SizedBox(height: 4),
                    Text(d, style: PText.body),
                  ],
                ),
              ),
            ),
          const Text(
            'این متن رفتار فنی همین نسخه را توضیح می‌دهد و جایگزین بررسی حقوقی نیست. پیش از انتشار، سیاست حریم خصوصی باید با قوانین و قواعد فروشگاه مقصد سنجیده شود.',
            style: PText.caption,
          ),
          const SizedBox(height: PSpace.lg),
          PButton(
            label: 'پاک کردن همه‌ی داده‌ها',
            icon: Icons.delete_forever_rounded,
            color: PColors.danger,
            onPressed: () async {
              final ok = await confirm(
                context,
                title: 'همه‌ی داده‌ها پاک شود؟',
                message: 'همه‌ی نمایه‌ها، نقاشی‌ها، آهنگ‌ها، برچسب‌ها و تاریخچه از روی این دستگاه پاک می‌شود. این کار برگشت ندارد.',
                yes: 'پاک کن',
              );
              if (!ok) return;
              final store = ref.read(storeProvider);
              for (final b in LocalStore.boxNames) {
                if (b == 'meta') continue;
                await store.box(b).clear();
              }
              await store.setMeta('activeProfile', null);
              ref.invalidate(profilesProvider);
              if (context.mounted) {
                toast(context, 'همه‌ی داده‌ها پاک شد.', color: PColors.success);
                context.go('/');
              }
            },
          ),
        ],
      ),
    );
  }
}

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(purchaseProvider);
    return PScaffold(
      title: 'خریدها',
      body: switch (p.status) {
        PurchaseStatus.unavailable => const StateView(
          state: ViewState.empty,
          message: 'در این نسخه خرید درون‌برنامه‌ای وجود ندارد و همه‌ی محتوا رایگان و داخل برنامه است.\nفروشگاهی به برنامه وصل نشده است.',
        ),
        PurchaseStatus.pending => const StateView(state: ViewState.pending, message: 'خرید در انتظار تأیید فروشگاه است…'),
        PurchaseStatus.failed => StateView(state: ViewState.error, message: 'خرید انجام نشد.', actionLabel: 'دوباره', onAction: p.restore),
        PurchaseStatus.done => const StateView(state: ViewState.success, message: 'خرید انجام شد. ممنون!'),
        PurchaseStatus.ready => StateView(
          state: ViewState.empty,
          message: 'خریدی ثبت نشده.',
          actionLabel: 'بازیابی خریدها',
          onAction: p.restore,
        ),
      },
    );
  }
}

class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  int? _free;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    StorageInfo.freeBytes().then((v) {
      if (mounted) {
        setState(() {
          _free = v;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.read(storeProvider);
    var data = 0;
    for (final b in LocalStore.boxNames) {
      for (final v in store.box(b).values) {
        data += v.length * 2;
      }
    }
    final downloads = ref.watch(downloadsProvider).usedBytes;
    return PScaffold(
      title: 'فضای ذخیره‌سازی',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          PCard(
            child: Column(
              children: [
                SettingRow(
                  icon: Icons.brush_rounded,
                  title: 'نقاشی‌ها، آهنگ‌ها و پیشرفت',
                  trailing: Text(faBytes(data), style: PText.bodyStrong),
                  color: PColors.pink,
                ),
                SettingRow(
                  icon: Icons.cloud_done_rounded,
                  title: 'محتوای دانلودشده',
                  trailing: Text(faBytes(downloads), style: PText.bodyStrong),
                  color: PColors.success,
                  onTap: () => context.push('/parent/downloads'),
                ),
                SettingRow(
                  icon: Icons.sd_storage_rounded,
                  title: 'فضای آزاد دستگاه',
                  trailing: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(_free == null ? 'نامشخص' : faBytes(_free!), style: PText.bodyStrong),
                  color: PColors.blue,
                ),
              ],
            ),
          ),
          if (_free != null && _free! < 200 * 1024 * 1024)
            Padding(
              padding: const EdgeInsets.only(top: PSpace.md),
              child: Text(
                'فضای دستگاه کم است؛ ممکن است دانلود بسته‌ها کامل نشود.',
                style: PText.bodyStrong.copyWith(color: PColors.danger),
              ),
            ),
        ],
      ),
    );
  }
}
