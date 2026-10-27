import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/billing/billing.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../mascot/popo_mascot.dart';

/// دروازه‌ی والدین در حالت «فقط تأیید»: true اگر بزرگ‌تر پاسخ درست داد. اگر دروازه همین چند دقیقه پیش
/// باز شده باشد، دوباره پرسیده نمی‌شود.
Future<bool> verifyParent(BuildContext context, WidgetRef ref) async {
  if (ref.read(parentGateProvider.notifier).isOpen) return true;
  final ok = await context.push<bool>('/parent-gate?mode=pop');
  return ok == true;
}

/// برگه‌ی «نسخه‌ی کامل»: چه چیزی باز می‌شود، قیمت، خرید (پشت دروازه‌ی والدین) و بازیابی خرید.
/// [parentVerified]: از بخش والدین باز شده و دروازه از قبل گذرانده شده است.
Future<void> showPaywall(BuildContext context, {bool parentVerified = false}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => PaywallSheet(parentVerified: parentVerified),
  );
}

class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({super.key, this.parentVerified = false});

  final bool parentVerified;

  Future<void> _buy(BuildContext context, WidgetRef ref) async {
    final access = ref.read(accessProvider);
    final nav = Navigator.of(context);
    // پیام روی صفحه‌ی زیرین می‌نشیند، نه روی همین برگه که شاید بسته شود.
    final messenger = ScaffoldMessenger.of(context);
    if (!parentVerified && !await verifyParent(context, ref)) return;
    final r = await access.buy();
    final text = switch (r) {
      PurchaseResult.purchased => 'ممنون! همه‌ی جهان‌ها و بازی‌ها باز شد.',
      PurchaseResult.cancelled => 'خرید انجام نشد.',
      PurchaseResult.failed => 'خرید ناموفق بود. دوباره امتحان کنید.',
      PurchaseResult.unavailable => 'برای خرید، کافه‌بازار باید روی گوشی نصب و وارد حساب شده باشد.',
    };
    if (r == PurchaseResult.purchased && nav.canPop()) nav.pop();
    _say(messenger, text, r == PurchaseResult.purchased ? PColors.success : PColors.ink);
  }

  /// همان شکل toast در core/widgets/common.dart، با messenger گرفته‌شده پیش از انتظار.
  static void _say(ScaffoldMessengerState messenger, String text, [Color color = PColors.ink]) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(text, style: PText.bodyStrong.copyWith(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final found = await ref.read(accessProvider).restore();
    final text = switch (found) {
      true => 'خرید قبلی پیدا شد؛ همه‌چیز باز است.',
      false => 'خریدی با این حساب کافه‌بازار پیدا نشد.',
      null => 'به کافه‌بازار وصل نشد. اینترنت و ورود به حساب بازار را بررسی کنید.',
    };
    if (found == true && nav.canPop()) nav.pop();
    _say(messenger, text);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final access = ref.watch(accessProvider);
    final reduced = ref.watch(settingsProvider).reducedMotion;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(PSpace.md),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: PCard(
              padding: const EdgeInsets.all(PSpace.lg),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopoMascot(pose: PopoPose.happy, size: 96, reducedMotion: reduced),
                    Text('همه‌ی دنیای پوپو را باز کن', style: PText.title.copyWith(color: PColors.purple), textAlign: TextAlign.center),
                    const SizedBox(height: PSpace.xs),
                    const Text(
                      'اولین صحنه‌ی هر جهان و اولین بازی هر دسته رایگان است. با نسخه‌ی کامل همه‌ی صحنه‌ها، '
                      'نقش‌آفرینی‌ها و پازل‌ها باز می‌شوند؛ یک بار خرید، برای همیشه.',
                      style: PText.body,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: PSpace.md),
                    Text(access.price, style: PText.title.copyWith(color: PColors.orange)),
                    const SizedBox(height: PSpace.md),
                    PButton(
                      label: access.busy ? 'در حال خرید…' : 'خرید نسخه‌ی کامل',
                      icon: Icons.lock_open_rounded,
                      color: PColors.success,
                      expand: true,
                      big: true,
                      onPressed: access.busy ? null : () => _buy(context, ref),
                    ),
                    const SizedBox(height: PSpace.xs),
                    const Text('خرید فقط با اجازه‌ی بزرگ‌ترها انجام می‌شود.', style: PText.caption, textAlign: TextAlign.center),
                    const SizedBox(height: PSpace.xs),
                    TextButton(
                      onPressed: access.busy ? null : () => _restore(context, ref),
                      child: Text('قبلاً خریده‌ام', style: PText.bodyStrong.copyWith(color: PColors.purple)),
                    ),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('بعداً', style: PText.body)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
