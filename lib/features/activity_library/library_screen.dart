import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';

/// کتابخانه‌ی فعالیت‌ها: دسته‌ها با تصویر و رنگ، و کاشی‌های بزرگ با کمترین متن.
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _cat = 'explore';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.say('library.hello'));
  }

  @override
  Widget build(BuildContext context) {
    final content = ref.watch(contentProvider);
    final age = ref.watch(activeProfileProvider)?.ageBand.minAge ?? 4;
    final done = ref.watch(progressProvider.select((p) => p.completed));
    final items = content.activities.where((a) => a.category == _cat).toList()
      // مناسب سن جلوتر؛ چیزی پنهان نمی‌شود.
      ..sort((a, b) => (a.minAge > age ? 1 : 0).compareTo(b.minAge > age ? 1 : 0));
    final cat = content.categories.firstWhere((c) => c.id == _cat);
    return PScaffold(
      title: 'همه‌ی بازی‌ها',
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: 112,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: PSpace.md, vertical: PSpace.xs),
                  children: [
                    for (final c in content.categories)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: PSpace.sm),
                        child: SizedBox(
                          width: 96,
                          child: PTile(
                            label: c.title,
                            selected: c.id == _cat,
                            color: PColors.tint(c.color, c.id == _cat ? .2 : .32),
                            onTap: () => setState(() => _cat = c.id),
                            child: ArtImage(c.art),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) => GridView.builder(
                    padding: const EdgeInsets.all(PSpace.md),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (box.maxWidth / 170).floor().clamp(2, 6),
                      mainAxisSpacing: PSpace.md,
                      crossAxisSpacing: PSpace.md,
                      childAspectRatio: .9,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final a = items[i];
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: PTile(
                              label: a.title,
                              color: PColors.tint(cat.color, .34),
                              onTap: () => context.push(a.route),
                              child: Padding(padding: const EdgeInsets.all(PSpace.sm), child: ArtImage(a.art)),
                            ),
                          ),
                          if (done.contains(a.id))
                            const PositionedDirectional(top: 6, end: 6, child: Icon(Icons.star_rounded, color: PColors.orange, size: 26)),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const CaptionBubble(alignment: Alignment.bottomCenter),
        ],
      ),
    );
  }
}
