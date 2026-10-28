import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/audio/popo_audio.dart';
import '../../../core/narrator.dart';
import '../../../game/game_data.dart';
import '../../../ui/fx.dart';

export 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerState, WidgetRef;

/// یک صحنه‌ی «امتحان و کشف»: کودک با شیء ساخته‌شده کار می‌کند و کارش را در انیمیشن می‌بیند.
abstract class ShowcaseScene extends ConsumerStatefulWidget {
  const ShowcaseScene({super.key, required this.item, this.friend, this.onTry, this.auto = false, this.play = false});

  final ItemDef item;

  /// دوست فصل (در بازی آزاد غذا را می‌گیرد، سوار می‌شود، …).
  final String? friend;

  /// هر بار که کودک یک کار کامل با شیء انجام دهد (یک گاز، یک میخ، یک دور رانندگی).
  final ValueChanged<int>? onTry;

  /// خودکار اجرا شود (فیلم پایان فصل).
  final bool auto;

  /// بازی آزاد بعد از سؤال (چیزهای بیشتر برای بازی).
  final bool play;
}

mixin SceneBase<T extends ShowcaseScene> on ConsumerState<T> {
  int tries = 0;
  Timer? _autoTimer;

  /// در حالت خودکار [act] هر [every] یک بار صدا زده می‌شود.
  void autoPlay(void Function() act, {Duration every = const Duration(milliseconds: 1300)}) {
    if (!widget.auto) return;
    _autoTimer = Timer.periodic(every, (_) {
      if (mounted) act();
    });
  }

  void tried() {
    tries++;
    widget.onTry?.call(tries);
  }

  void sfx(String? path, {double volume = 1}) {
    if (path != null && path.isNotEmpty) ref.read(audioProvider).play(path, volume: volume);
  }

  void ui(UiSound s) => ref.read(audioProvider).ui(s);

  void say(String id) => ref.say(id);

  FxLayerState? get fx => FxScope.of(context);

  /// ذره‌ها روی ابزارک [key].
  void burstAt(GlobalKey key, Fx kind, {int? count, Color? color, Offset offset = Offset.zero, double spread = 1}) {
    final c = key.currentContext;
    if (c == null) return;
    fx?.burst(c.globalCenter + offset, kind, count: count, color: color, spread: spread);
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    super.dispose();
  }
}
