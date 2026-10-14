import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/fa.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/assets/download_manager.dart';
import '../../core/assets/storage_info.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';

/// بسته‌های محتوای قابل دانلود (Cloudflare R2): اندازه، پیشرفت، مکث/ادامه، تلاش دوباره، حذف.
class DownloadsScreen extends ConsumerStatefulWidget {
  const DownloadsScreen({super.key});

  @override
  ConsumerState<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends ConsumerState<DownloadsScreen> {
  int? _free;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.read(downloadsProvider).refresh());
    StorageInfo.freeBytes().then((v) {
      if (mounted) setState(() => _free = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final dm = ref.watch(downloadsProvider);
    Widget body;
    if (!dm.configured) {
      body = const StateView(
        state: ViewState.empty,
        message: 'سرور محتوا در این نسخه تنظیم نشده است.\nهمه‌ی جهان‌ها و صداهای اصلی داخل برنامه‌اند و بدون اینترنت کار می‌کنند.',
      );
    } else if (!dm.available) {
      body = const StateView(state: ViewState.empty, message: 'دانلود روی این سکو پشتیبانی نمی‌شود.');
    } else if (dm.loading && dm.packs.isEmpty) {
      body = const StateView(state: ViewState.loading, message: 'در حال دریافت فهرست بسته‌ها…');
    } else if (dm.packs.isEmpty && dm.indexError != null) {
      body = StateView(state: ViewState.offline, message: dm.indexError!.message, actionLabel: 'دوباره', onAction: dm.refresh);
    } else if (dm.packs.isEmpty) {
      body = const StateView(state: ViewState.empty, message: 'فعلاً بسته‌ی تازه‌ای نیست.');
    } else {
      body = RefreshIndicator(
        onRefresh: dm.refresh,
        child: ListView(
          padding: const EdgeInsets.all(PSpace.md),
          children: [
            if (dm.offlineIndex)
              Padding(
                padding: const EdgeInsets.only(bottom: PSpace.sm),
                child: PCard(
                  color: PColors.tint(PColors.yellow, .3),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off_rounded, color: PColors.inkSoft),
                      SizedBox(width: PSpace.sm),
                      Expanded(child: Text('بدون اینترنت؛ فهرست ذخیره‌شده نشان داده می‌شود.', style: PText.bodyStrong)),
                    ],
                  ),
                ),
              ),
            for (final p in dm.packs)
              Padding(
                padding: const EdgeInsets.only(bottom: PSpace.sm),
                child: DownloadCard(pack: p, dm: dm, freeBytes: _free),
              ),
          ],
        ),
      );
    }
    return PScaffold(
      title: 'دانلود محتوا',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PSpace.md),
            child: Row(
              children: [
                const Icon(Icons.sd_storage_rounded, color: PColors.inkSoft, size: 20),
                const SizedBox(width: 6),
                Text(
                  'دانلودشده: ${faBytes(dm.usedBytes)} · فضای آزاد: ${_free == null ? 'نامشخص' : faBytes(_free!)}',
                  style: PText.caption,
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class DownloadCard extends StatelessWidget {
  const DownloadCard({super.key, required this.pack, required this.dm, this.freeBytes});

  final AssetPack pack;
  final DownloadManager dm;
  final int? freeBytes;

  @override
  Widget build(BuildContext context) {
    final st = dm.status(pack);
    final err = dm.errorFor(pack.id);
    final tooBig = freeBytes != null && pack.totalBytes > freeBytes!;
    final progress = dm.progress(pack);
    final (label, icon, color, VoidCallback? action) = switch (st) {
      PackStatus.downloading => ('مکث', Icons.pause_rounded, PColors.orange, () => dm.pause(pack)),
      PackStatus.paused || PackStatus.partial => ('ادامه', Icons.play_arrow_rounded, PColors.blue, tooBig ? null : () => dm.download(pack)),
      PackStatus.notDownloaded => (
        err != null ? 'دوباره' : 'دانلود',
        err != null ? Icons.refresh_rounded : Icons.download_rounded,
        PColors.success,
        tooBig || !pack.compatible ? null : () => dm.download(pack),
      ),
      PackStatus.ready => (
        'حذف',
        Icons.delete_outline_rounded,
        PColors.danger,
        () async {
          if (await confirm(context, title: '«${pack.title}» حذف شود؟', message: 'می‌توانید بعداً دوباره دانلودش کنید.', yes: 'حذف')) {
            await dm.remove(pack);
          }
        },
      ),
    };
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pack.title, style: PText.heading),
                    Text(
                      '${faBytes(pack.totalBytes)} · ${faDigits(pack.files.length)} فایل · نسخه‌ی ${faDigits(pack.version)}',
                      style: PText.caption,
                    ),
                    if (pack.description.isNotEmpty) Text(pack.description, style: PText.body),
                  ],
                ),
              ),
              if (st == PackStatus.ready) const Icon(Icons.check_circle_rounded, color: PColors.success, size: 30),
            ],
          ),
          if (st != PackStatus.notDownloaded && st != PackStatus.ready) ...[
            const SizedBox(height: PSpace.sm),
            PProgressBar(value: progress, label: 'پیشرفت دانلود'),
            const SizedBox(height: 4),
            Text(
              st == PackStatus.paused ? 'متوقف شد · ${faDigits((progress * 100).round())}٪' : '${faDigits((progress * 100).round())}٪',
              style: PText.caption,
            ),
          ],
          if (err != null)
            Padding(
              padding: const EdgeInsets.only(top: PSpace.xs),
              child: Text(err.message, style: PText.bodyStrong.copyWith(color: PColors.danger)),
            ),
          if (!pack.compatible) const Text('این بسته به نسخه‌ی تازه‌تر برنامه نیاز دارد.', style: PText.caption),
          if (tooBig && st != PackStatus.ready)
            Text('فضای خالی دستگاه برای این بسته کافی نیست.', style: PText.caption.copyWith(color: PColors.danger)),
          const SizedBox(height: PSpace.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: PButton(label: label, icon: icon, color: color, onPressed: action),
          ),
        ],
      ),
    );
  }
}
