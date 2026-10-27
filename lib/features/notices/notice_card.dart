import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/notices/notices_store.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../paywall/paywall.dart';

/// چه کاری با خبر شد؛ هر کدام یعنی «دیده شد».
enum NoticeAction { go, close }

/// صفحه‌هایی که استودیو می‌شناسد (مقدار `screen` خبر) و مسیرشان در برنامه.
const noticeScreens = <String, String>{
  'HOME': '/map',
  'LIBRARY': '/library',
  'ART': '/art',
  'MUSIC': '/music',
  'BUILD': '/build',
  'REWARDS': '/rewards',
  'WORLD_HOME': '/world/home',
  'WORLD_CITY': '/world/city',
  'WORLD_NATURE': '/world/nature',
  'DOWNLOADS': '/parent/downloads',
};

/// متن دکمه‌ی اصلی، یا خالی وقتی خبر فقط چند کلمه است.
String noticeGoLabel(Notice n) {
  if (n.destination.isNotEmpty) return 'بریم ببینیم';
  if (n.hasLink) return 'باز کردن پیوند';
  return '';
}

/// یکی از صفحه‌هایی که استودیو می‌شناسد. false یعنی این نسخه آن را نمی‌شناسد.
Future<bool> openNoticeScreen(BuildContext context, String screen) async {
  if (screen == 'PAYWALL') {
    await showPaywall(context);
    return true;
  }
  final route = noticeScreens[screen];
  if (route == null) return false;
  // بخش دانلودها پشت دروازه‌ی والدین است؛ مسیریاب خودش دروازه را نشان می‌دهد.
  unawaited(context.push(route));
  return true;
}

/// خبر را دنبال می‌کند: صفحه‌ای در برنامه بر پیوند بیرونی مقدم است، چون کودک را جای غیرمنتظره‌ای
/// نمی‌برد. پیوند فقط بعد از دروازه‌ی والدین باز می‌شود.
Future<void> followNotice(BuildContext context, WidgetRef ref, NoticesStore store, Notice n) async {
  if (await openNoticeScreen(context, n.destination)) return;
  if (!n.hasLink || !context.mounted) return;
  if (await verifyParent(context, ref)) await store.bridge.openUrl(n.link);
}

/// کارت خبر وسط صفحه: عنوان، عکس اگر هست، متن، و حداکثر دو کار. لمس بیرون یا «بازگشت» یعنی «باشه».
Future<NoticeAction> showNoticeCard(BuildContext context, NoticesStore store, Notice n) async {
  final picked = await showDialog<NoticeAction>(
    context: context,
    builder: (_) => NoticeCard(notice: n, store: store),
  );
  return picked ?? NoticeAction.close;
}

class NoticeCard extends StatelessWidget {
  const NoticeCard({super.key, required this.notice, required this.store});

  final Notice notice;
  final NoticesStore store;

  @override
  Widget build(BuildContext context) {
    final go = noticeGoLabel(notice);
    void pick(NoticeAction a) => Navigator.of(context).pop(a);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: PSpace.lg, vertical: PSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: PCard(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('📣 ${notice.title}', textAlign: TextAlign.center, style: PText.heading.copyWith(color: PColors.furDark)),
                if (notice.hasImage)
                  NoticePicture(store: store, notice: notice, onTap: go.isEmpty ? null : () => pick(NoticeAction.go)),
                if (notice.body.isNotEmpty) ...[
                  const SizedBox(height: PSpace.sm),
                  Text(notice.body, textAlign: TextAlign.center, style: PText.body),
                ],
                const SizedBox(height: PSpace.md),
                if (go.isNotEmpty) ...[
                  PButton(label: go, color: PColors.success, expand: true, onPressed: () => pick(NoticeAction.go)),
                  const SizedBox(height: PSpace.xs),
                ],
                TextButton(
                  onPressed: () => pick(NoticeAction.close),
                  child: Text(go.isEmpty ? 'باشه' : 'بعداً', style: PText.bodyStrong.copyWith(color: PColors.purple)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عکس خبر، فقط اگر همان باشد که امضا شده. تا برسد جایش خالی است.
class NoticePicture extends StatelessWidget {
  const NoticePicture({super.key, required this.store, required this.notice, this.onTap});

  final NoticesStore store;
  final Notice notice;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: store.image(notice),
      builder: (context, snap) {
        final bytes = snap.data;
        if (bytes == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: PSpace.sm),
          child: GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PRadius.sm),
              child: ConstrainedBox(
                // پوستر بلند نباید دکمه‌ها را از صفحه بیرون کند.
                constraints: const BoxConstraints(maxHeight: 280),
                child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
              ),
            ),
          ),
        );
      },
    );
  }
}
