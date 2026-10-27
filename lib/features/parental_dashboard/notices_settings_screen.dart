import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/fa.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/notices/notices_store.dart';
import '../../core/platform/native_bridge.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';

/// اعلان‌ها و خبرهای امضاشده (بخش والدین): اجازه‌ی اعلان در اندروید ۱۳ به بعد، روشن/خاموش خبرها،
/// بیرون ماندن از صرفه‌جویی باتری و «اجرای خودکار» سازنده، و آخرین بررسی. همان کارت گوش‌یار.
class NoticesSettingsScreen extends ConsumerStatefulWidget {
  const NoticesSettingsScreen({super.key});

  @override
  ConsumerState<NoticesSettingsScreen> createState() => _NoticesSettingsScreenState();
}

class _NoticesSettingsScreenState extends ConsumerState<NoticesSettingsScreen> with WidgetsBindingObserver {
  static const _bridge = NativeBridge();
  bool? _allowed;
  bool _background = true;
  bool _autostart = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // پنجره‌ی اجازه‌ی اندروید برنامه را pause می‌کند؛ بعد از برگشتن وضعیت تازه خوانده می‌شود.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final allowed = await _bridge.notificationsAllowed();
    final background = await _bridge.runsInBackground();
    final autostart = await _bridge.hasAutostart();
    if (mounted) {
      setState(() {
        _allowed = allowed;
        _background = background;
        _autostart = autostart;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allowed = _allowed ?? false;
    final notices = ref.watch(noticesProvider);
    return PScaffold(
      title: 'اعلان‌ها و خبرها',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.md),
        children: [
          PCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allowed
                      ? 'اعلان‌ها روشن است؛ خبر جهان‌ها و بازی‌های تازه می‌رسد.'
                      : 'برای دریافت خبر جهان‌ها و بازی‌های تازه، اجازه‌ی اعلان بدهید.',
                  style: PText.body,
                ),
                if (!allowed) ...[
                  const SizedBox(height: PSpace.sm),
                  PButton(
                    label: 'اجازه‌ی اعلان',
                    icon: Icons.notifications_active_rounded,
                    onPressed: () => _bridge.requestNotifications(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PSpace.md),
          if (!notices.ready)
            const StateView(
              state: ViewState.empty,
              compact: true,
              message: 'این نسخه کلید خبرها را ندارد؛ هیچ خبری خوانده یا نشان داده نمی‌شود.',
            )
          else
            PCard(child: _noticesCard(notices, allowed)),
        ],
      ),
    );
  }

  Widget _noticesCard(NoticesStore notices, bool allowed) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: notices.enabled,
          onChanged: notices.setEnabled,
          title: const Text('خبرهای پوپو', style: PText.bodyStrong),
          subtitle: const Text(
            'زنگوله‌ی نقشه و اعلان جهان‌ها و بازی‌های تازه. فقط یک فایل امضاشده خوانده می‌شود؛ '
            'هیچ چیزی از این دستگاه فرستاده نمی‌شود.',
            style: PText.caption,
          ),
        ),
        // اجازه‌ی اعلان به‌تنهایی کافی نیست: برنامه‌ی بسته باید گاه‌به‌گاه بیدار شود و فایل خبرها را
        // بخواند. صرفه‌جویی باتری و «اجرای خودکار» سازنده‌ها جلویش را می‌گیرند.
        if (notices.enabled && allowed && (!_background || _autostart)) ...[
          const SizedBox(height: PSpace.xs),
          const Text('دریافت خبر وقتی برنامه بسته است', style: PText.bodyStrong),
          Text(
            _background
                ? 'روی این گوشی «اجرای خودکار» پوپو را هم روشن کنید؛ وگرنه با بستن برنامه از فهرست '
                      'برنامه‌های اخیر، خبرها تا باز شدن دوباره‌ی برنامه نمی‌رسند.'
                : 'صرفه‌جویی باتری بررسی خبرها را وقتی برنامه بسته است متوقف می‌کند. پوپو را «بدون '
                      'محدودیت» کنید${_autostart ? ' و «اجرای خودکار» آن را هم روشن کنید' : ''}.',
            style: PText.caption,
          ),
          const SizedBox(height: PSpace.xs),
          Wrap(
            spacing: PSpace.xs,
            runSpacing: PSpace.xs,
            children: [
              if (!_background)
                PButton(
                  label: 'بدون محدودیت باتری',
                  icon: Icons.battery_charging_full_rounded,
                  color: PColors.success,
                  onPressed: () => _bridge.askBackground(),
                ),
              if (_autostart)
                PButton(label: 'اجرای خودکار', icon: Icons.play_circle_outline_rounded, onPressed: () => _bridge.openAutostart()),
            ],
          ),
        ],
        // «آخرین بررسی خبرها» — تنها جایی که می‌گوید چه شد.
        if (notices.enabled) ...[
          const SizedBox(height: PSpace.sm),
          const Text('آخرین بررسی خبرها', style: PText.bodyStrong),
          Text(notices.lastCheck.isEmpty ? 'هنوز بررسی نشده' : notices.lastCheck, style: PText.caption),
          Text('${faDigits(notices.countHere)} خبر روی دستگاه', style: PText.caption),
          const SizedBox(height: PSpace.xs),
          PButton(
            label: 'بررسی کن',
            icon: Icons.refresh_rounded,
            // فایل روی گوشی کنار گذاشته می‌شود تا هرچه روی سرور است دوباره خوانده شود.
            onPressed: () => notices.refresh(forget: true),
          ),
        ],
      ],
    );
  }
}
