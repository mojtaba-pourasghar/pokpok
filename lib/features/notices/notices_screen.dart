import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/notices/notices_store.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import 'notice_card.dart';

/// همه‌ی خبرهای فعلی، از زنگوله‌ی نقشه. با باز شدن این صفحه همه «دیده شد» می‌شوند.
class NoticesScreen extends ConsumerStatefulWidget {
  const NoticesScreen({super.key});

  @override
  ConsumerState<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends ConsumerState<NoticesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(noticesProvider).markAllSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(noticesProvider);
    final list = store.notices;
    return PScaffold(
      title: 'خبرها',
      body: list.isEmpty
          ? const StateView(state: ViewState.empty, message: 'فعلاً خبری نیست.')
          : ListView.separated(
              padding: const EdgeInsets.all(PSpace.md),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: PSpace.sm),
              itemBuilder: (context, i) => _Item(store: store, notice: list[i]),
            ),
    );
  }
}

class _Item extends ConsumerWidget {
  const _Item({required this.store, required this.notice});

  final NoticesStore store;
  final Notice notice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final go = noticeGoLabel(notice);
    void follow() => followNotice(context, ref, store, notice);
    return PCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('📣 ${notice.title}', style: PText.heading.copyWith(color: PColors.furDark)),
          if (notice.hasImage) NoticePicture(store: store, notice: notice, onTap: go.isEmpty ? null : follow),
          if (notice.body.isNotEmpty) ...[
            const SizedBox(height: PSpace.xs),
            Text(notice.body, style: PText.body),
          ],
          if (go.isNotEmpty) ...[
            const SizedBox(height: PSpace.sm),
            PButton(label: go, color: PColors.success, onPressed: follow),
          ],
        ],
      ),
    );
  }
}
