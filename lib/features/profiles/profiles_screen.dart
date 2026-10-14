import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';

/// نمادهایی که کودک می‌تواند برای نمایه‌اش داشته باشد (از تصویرهای خود برنامه).
const profileAvatars = ['rabbit', 'cat', 'dog', 'chick', 'frog', 'fish', 'butterfly', 'bee', 'sheep', 'duck'];
const avatarColors = [PColors.pink, PColors.yellow, PColors.turquoise, PColors.green, PColors.purple, PColors.orange];

Color avatarColor(String avatar) => avatarColors[profileAvatars.indexOf(avatar).clamp(0, 99) % avatarColors.length];

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.profile, this.size = 96, this.selected = false});

  final ChildProfile profile;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .12),
    decoration: BoxDecoration(
      color: PColors.tint(avatarColor(profile.avatar), .22),
      shape: BoxShape.circle,
      border: Border.all(color: selected ? PColors.orange : Colors.white, width: selected ? 5 : 4),
      boxShadow: PShadow.soft(),
    ),
    child: ArtImage(profile.avatar),
  );
}

/// «کی بازی می‌کند؟» — انتخاب نمایه‌ی کودک. ساختن و ویرایش نمایه فقط از بخش والدین است.
class ProfilesScreen extends ConsumerStatefulWidget {
  const ProfilesScreen({super.key});

  @override
  ConsumerState<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends ConsumerState<ProfilesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.say('app.profiles.pick'));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profilesProvider);
    return PScaffold(
      title: 'کی بازی می‌کند؟',
      onBack: () => context.go('/'),
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, box) {
              final cols = (box.maxWidth / 190).floor().clamp(2, 5);
              return GridView.count(
                padding: const EdgeInsets.all(PSpace.lg),
                crossAxisCount: cols,
                mainAxisSpacing: PSpace.md,
                crossAxisSpacing: PSpace.md,
                childAspectRatio: .85,
                children: [
                  for (final p in state.profiles)
                    PTile(
                      label: p.name,
                      selected: p.id == state.active?.id,
                      onTap: () async {
                        await ref.read(profilesProvider.notifier).select(p.id);
                        if (context.mounted) context.go('/map');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(PSpace.xs),
                        child: ProfileAvatar(profile: p, size: 110),
                      ),
                    ),
                  PTile(
                    label: 'افزودن',
                    semanticHint: 'برای بزرگ‌ترها',
                    onTap: () => context.push('/parent/profile/new'),
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: const BoxDecoration(color: PColors.background, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, size: 52, color: PColors.blue),
                    ),
                  ),
                ],
              );
            },
          ),
          const CaptionBubble(alignment: Alignment.bottomCenter),
        ],
      ),
    );
  }
}

/// کارت نمایه برای فهرست والدین.
class ChildProfileCard extends StatelessWidget {
  const ChildProfileCard({super.key, required this.profile, required this.onTap, this.active = false, this.trailing});

  final ChildProfile profile;
  final VoidCallback onTap;
  final bool active;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => PCard(
    padding: const EdgeInsets.all(PSpace.sm),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PRadius.md),
      child: Row(
        children: [
          ProfileAvatar(profile: profile, size: 64, selected: active),
          const SizedBox(width: PSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: PText.heading),
                Text(profile.ageBand.label + (active ? ' · فعال' : ''), style: PText.caption),
              ],
            ),
          ),
          trailing ?? const Icon(Icons.edit_rounded, color: PColors.inkSoft),
        ],
      ),
    ),
  );
}
