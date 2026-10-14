import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../data/models/models.dart';

/// پل بین شناسه‌ی جمله‌ها (voice_lines.json) و پخش‌کننده.
extension Narration on WidgetRef {
  Future<void> say(String? id) => read(audioProvider).say(read(contentProvider).voice(id));

  /// یک جمله‌ی تصادفی از گروه (مثل «praise»)، بدون تکرار پشت سر هم.
  Future<void> sayOneOf(String group) => read(audioProvider).say(read(contentProvider).pick(group));

  void sound(String? path) {
    if (path != null) read(audioProvider).play(path);
  }
}

/// زمان‌سنج فعالیت: از ورود تا خروج صفحه را در تاریخچه‌ی محلی ثبت و آخرین مسیر را
/// برای «ادامه» نگه می‌دارد.
mixin ActivitySession<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  String get activityId;
  String get activityTitle;
  String? get resumeRoute => null;

  late final DateTime _started = DateTime.now();
  ProgressNotifier? _progress;

  @override
  void initState() {
    super.initState();
    _progress = ref.read(progressProvider.notifier);
    _started;
    final r = resumeRoute;
    if (r != null) WidgetsBinding.instance.addPostFrameCallback((_) => _progress?.setLastRoute(r));
  }

  @override
  void dispose() {
    final seconds = DateTime.now().difference(_started).inSeconds;
    _progress?.record(activityId, activityTitle, seconds);
    super.dispose();
  }

  /// برچسب تازه؛ اگر تازه بود پوپو خبر می‌دهد.
  Future<bool> award(String stickerId) async {
    final isNew = await ref.read(progressProvider.notifier).addSticker(stickerId);
    if (isNew && mounted) await ref.say('sticker.new');
    return isNew;
  }
}

ProfileSettings settingsOf(WidgetRef ref) => ref.read(settingsProvider);
