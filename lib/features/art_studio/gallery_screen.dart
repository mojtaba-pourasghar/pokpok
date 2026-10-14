import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import 'drawing.dart';

/// نقاشی‌های ذخیره‌شده. باز کردن دوباره برای ادامه، حذف با پرسش، و خروجی گرفتن فقط
/// پس از دروازه‌ی والدین. هیچ نقاشی‌ای خودکار جایی فرستاده نمی‌شود.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  late List<Artwork> _items = _load();

  List<Artwork> _load() => ref.read(artworkRepoProvider).all(ref.read(activeIdProvider)).where((a) => a.id != '_draft').toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.say('art.gallery'));
  }

  Future<void> _delete(Artwork a) async {
    final ok = await confirm(context, title: 'این نقاشی پاک شود؟', yes: 'پاک کن', no: 'نه');
    if (!ok) return;
    await ref.read(artworkRepoProvider).delete(ref.read(activeIdProvider), a.id);
    setState(() => _items = _load());
  }

  Future<void> _export(Artwork a) async {
    if (!ref.read(parentGateProvider.notifier).isOpen) {
      await context.push('/parent-gate?mode=pop');
      if (!mounted || !ref.read(parentGateProvider.notifier).isOpen) return;
    }
    try {
      final f = await exportArtworkPng(a);
      if (mounted) toast(context, 'تصویر در پوشه‌ی برنامه ذخیره شد: ${f.path}', color: PColors.success);
    } catch (e) {
      if (mounted) toast(context, 'ذخیره‌ی تصویر ممکن نشد.', color: PColors.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PScaffold(
      title: 'نقاشی‌های من',
      color: PColors.tint(PColors.pink, .3),
      body: _items.isEmpty
          ? StateView(
              state: ViewState.empty,
              message: 'هنوز نقاشی‌ای ذخیره نشده.',
              actionLabel: 'بیا بکشیم',
              onAction: () => context.pushReplacement('/art'),
            )
          : LayoutBuilder(
              builder: (context, box) => GridView.builder(
                padding: const EdgeInsets.all(PSpace.md),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: (box.maxWidth / 220).floor().clamp(2, 6),
                  mainAxisSpacing: PSpace.md,
                  crossAxisSpacing: PSpace.md,
                  childAspectRatio: .9,
                ),
                itemCount: _items.length,
                itemBuilder: (context, i) {
                  final a = _items[i];
                  return PCard(
                    padding: const EdgeInsets.all(PSpace.xs),
                    child: Column(
                      children: [
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: 'نقاشی ${i + 1}؛ برای ادامه لمس کن',
                            child: GestureDetector(
                              onTap: () => context.push('/art?open=${a.id}'),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(PRadius.sm),
                                child: CustomPaint(painter: StrokesPainter(a.strokes, Color(a.background)), size: Size.infinite),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              tooltip: 'پاک کردن',
                              onPressed: () => _delete(a),
                              icon: const Icon(Icons.delete_outline_rounded, color: PColors.danger),
                            ),
                            IconButton(
                              tooltip: 'خروجی تصویر (والدین)',
                              onPressed: () => _export(a),
                              icon: const Icon(Icons.ios_share_rounded, color: PColors.inkSoft),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
      bottom: _items.isEmpty
          ? null
          : Padding(
              padding: EdgeInsets.fromLTRB(PSpace.md, PSpace.xs, PSpace.md, PSpace.md + MediaQuery.paddingOf(context).bottom),
              child: PButton(
                label: 'نقاشی تازه',
                icon: Icons.brush_rounded,
                color: PColors.pink,
                onPressed: () => context.pushReplacement('/art'),
              ),
            ),
    );
  }
}
