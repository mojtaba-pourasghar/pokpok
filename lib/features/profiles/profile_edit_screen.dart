import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import 'profiles_screen.dart';

/// ساخت یا ویرایش نمایه‌ی کودک (فقط پشت دروازه‌ی والدین). فقط یک نام کوچک یا لقب، نماد
/// و گروه سنی ذخیره می‌شود؛ نه تاریخ تولد، نه عکس، نه هیچ داده‌ی شخصی دیگر.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.profileId});

  /// «new» برای نمایه‌ی تازه.
  final String profileId;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final ChildProfile? _existing = ref.read(profilesProvider).profiles.where((p) => p.id == widget.profileId).firstOrNull;
  late final _name = TextEditingController(text: _existing?.name ?? '');
  late String _avatar = _existing?.avatar ?? profileAvatars[ref.read(profilesProvider).profiles.length % profileAvatars.length];
  late AgeBand _age = _existing?.ageBand ?? AgeBand.preschool;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = ref.read(profilesProvider.notifier);
    if (_existing == null) {
      await n.create(name: _name.text, avatar: _avatar, ageBand: _age);
    } else {
      await n.update(
        _existing.copyWith(name: _name.text.trim().isEmpty ? _existing.name : _name.text.trim(), avatar: _avatar, ageBand: _age),
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final p = _existing;
    if (p == null) return;
    final ok = await confirm(
      context,
      title: 'نمایه‌ی «${p.name}» حذف شود؟',
      message: 'همه‌ی نقاشی‌ها، آهنگ‌ها، برچسب‌ها و تاریخچه‌ی این نمایه هم از روی دستگاه پاک می‌شود.',
      yes: 'حذف',
    );
    if (!ok) return;
    await ref.read(profilesProvider.notifier).delete(p.id);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final preview = ChildProfile(id: '_', name: _name.text, avatar: _avatar, ageBand: _age, createdAt: DateTime.now());
    return PScaffold(
      title: _existing == null ? 'نمایه‌ی تازه' : 'ویرایش نمایه',
      body: ListView(
        padding: const EdgeInsets.all(PSpace.lg),
        children: [
          Center(child: ProfileAvatar(profile: preview, size: 120)),
          const SizedBox(height: PSpace.lg),
          const Text('نام یا لقب', style: PText.heading),
          const SizedBox(height: PSpace.xs),
          TextField(
            controller: _name,
            maxLength: 20,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'مثلاً آرا',
              filled: true,
              fillColor: Colors.white,
              helperText: 'نام کامل لازم نیست؛ این نام فقط روی همین دستگاه می‌ماند.',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(PRadius.md), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: PSpace.md),
          const Text('نماد', style: PText.heading),
          const SizedBox(height: PSpace.xs),
          Wrap(
            spacing: PSpace.sm,
            runSpacing: PSpace.sm,
            children: [
              for (final a in profileAvatars)
                SizedBox(
                  width: 76,
                  height: 76,
                  child: PTile(
                    label: a,
                    showLabel: false,
                    selected: a == _avatar,
                    onTap: () => setState(() => _avatar = a),
                    child: ArtImage(a),
                  ),
                ),
            ],
          ),
          const SizedBox(height: PSpace.lg),
          const Text('گروه سنی', style: PText.heading),
          const Text('دشواری پازل‌ها و تعداد قطعه‌ها با این تنظیم می‌شود.', style: PText.caption),
          const SizedBox(height: PSpace.xs),
          SegmentedButton<AgeBand>(
            segments: [for (final b in AgeBand.values) ButtonSegment(value: b, label: Text(b.label))],
            selected: {_age},
            onSelectionChanged: (s) => setState(() => _age = s.first),
            showSelectedIcon: false,
          ),
          const SizedBox(height: PSpace.xl),
          PButton(label: 'ذخیره', icon: Icons.check_rounded, color: PColors.success, expand: true, onPressed: _save),
          if (_existing != null) ...[
            const SizedBox(height: PSpace.md),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: PColors.danger),
              label: const Text(
                'حذف نمایه',
                style: TextStyle(color: PColors.danger, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
