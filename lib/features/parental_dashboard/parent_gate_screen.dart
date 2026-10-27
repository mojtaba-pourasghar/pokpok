import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/fa.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../core/audio/popo_audio.dart';
import '../../core/narrator.dart';
import '../../core/widgets/buttons.dart';
import '../../core/widgets/common.dart';

/// سه عدد تصادفی که به حروف نوشته می‌شوند؛ کودکِ هنوز خواننده نمی‌تواند از آن رد شود.
@visibleForTesting
List<int> gateChallenge(math.Random r) => [for (var i = 0; i < 3; i++) 1 + r.nextInt(9)];

/// دروازه‌ی والدین: «این عددها را به ترتیب لمس کنید: پنج، دو، هشت». پس از سه اشتباه
/// عددهای تازه می‌آید. پس از پاسخ درست، بخش والدین چند دقیقه باز می‌ماند.
class ParentGateScreen extends ConsumerStatefulWidget {
  const ParentGateScreen({super.key, required this.next, this.popOnSuccess = false, this.random});

  final String next;
  final bool popOnSuccess;
  final math.Random? random;

  @override
  ConsumerState<ParentGateScreen> createState() => _ParentGateScreenState();
}

class _ParentGateScreenState extends ConsumerState<ParentGateScreen> {
  late final math.Random _rand = widget.random ?? math.Random();
  late List<int> _target = gateChallenge(_rand);
  late List<int> _pad = _shuffledPad();
  final List<int> _entered = [];
  int _misses = 0;
  bool _wrong = false;

  List<int> _shuffledPad() => [for (var i = 1; i <= 9; i++) i]..shuffle(_rand);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => ref.say('parent.ask'));
  }

  void _press(int d) {
    setState(() {
      _wrong = false;
      _entered.add(d);
    });
    if (_entered.length < _target.length) return;
    if (_entered.join() == _target.join()) {
      ref.read(parentGateProvider.notifier).unlock();
      ref.read(audioProvider).ui(UiSound.success);
      if (widget.popOnSuccess && context.canPop()) {
        context.pop(true);
      } else if (context.canPop()) {
        context.pushReplacement(widget.next);
      } else {
        context.go(widget.next);
      }
      return;
    }
    ref.read(audioProvider).ui(UiSound.softNo);
    setState(() {
      _misses++;
      _entered.clear();
      _wrong = true;
      if (_misses >= 3) {
        _misses = 0;
        _target = gateChallenge(_rand);
        _pad = _shuffledPad();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final words = _target.map((d) => faNumberWords[d]).join('، ');
    return PScaffold(
      title: 'فقط برای بزرگ‌ترها',
      onBack: () => context.canPop() ? context.pop(false) : context.go('/home'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(PSpace.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Icon(Icons.lock_rounded, size: 48, color: PColors.blue),
                const SizedBox(height: PSpace.sm),
                const Text('برای ادامه، این عددها را به ترتیب لمس کنید:', style: PText.body, textAlign: TextAlign.center),
                const SizedBox(height: PSpace.xs),
                Text(
                  words,
                  style: PText.title.copyWith(color: PColors.blue),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: PSpace.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _target.length; i++)
                      Container(
                        margin: const EdgeInsets.all(6),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i < _entered.length ? PColors.blue : PColors.line),
                      ),
                  ],
                ),
                if (_wrong) Text('درست نبود؛ دوباره امتحان کنید.', style: PText.caption.copyWith(color: PColors.danger)),
                const SizedBox(height: PSpace.md),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: PSpace.sm,
                  crossAxisSpacing: PSpace.sm,
                  childAspectRatio: 1.4,
                  children: [
                    for (final d in _pad)
                      Semantics(
                        button: true,
                        label: faNumberWords[d],
                        excludeSemantics: true,
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(PRadius.md),
                          child: InkWell(
                            key: ValueKey('gate-$d'),
                            borderRadius: BorderRadius.circular(PRadius.md),
                            onTap: () => _press(d),
                            child: Center(child: Text(faDigits(d), style: PText.title)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: PSpace.lg),
                PButton(
                  label: 'انصراف',
                  color: PColors.turquoise,
                  onPressed: () => context.canPop() ? context.pop(false) : context.go('/home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
