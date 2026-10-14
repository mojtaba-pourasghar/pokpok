import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../../core/content/content.dart';
import '../../../data/models/models.dart';

/// آنچه یک تعامل باید در رابط کاربری پدید آورد. منطق صحنه هیچ صدایی پخش نمی‌کند و هیچ
/// ویجتی نمی‌سازد؛ فقط این نتیجه را برمی‌گرداند تا جدا آزمون شود.
class InteractionResult {
  const InteractionResult({
    this.sound,
    this.say,
    this.animate = const {},
    this.burstAt,
    this.goalCompleted = false,
    this.matched = false,
    this.reaction,
  });

  final String? sound;
  final String? say;

  /// شناسه‌ی شیء ← نام حرکت.
  final Map<String, String> animate;

  /// جای جشن ستاره‌ها (نسبی).
  final Offset? burstAt;
  final bool goalCompleted;

  /// رها کردن روی یک مقصد معتبر انجام شد.
  final bool matched;
  final DropReaction? reaction;

  static const none = InteractionResult();
}

/// وضعیت زنده‌ی یک شیء. هر شیء شنونده‌ی جدای خودش را دارد تا لمس یک شیء کل صحنه را
/// دوباره نسازد.
class SceneObjectRuntime {
  SceneObjectRuntime(this.def, ObjectState initial) : state = ValueNotifier(initial), home = Offset(initial.x, initial.y);

  final SceneObjectDef def;
  final ValueNotifier<ObjectState> state;

  /// هر بار که حرکتی باید پخش شود یک واحد بالا می‌رود.
  final ValueNotifier<int> animTick = ValueNotifier(0);
  String anim = 'bounce';

  /// رو به چپ (برای ماشین‌هایی که روی جاده به عقب کشیده می‌شوند).
  final ValueNotifier<bool> facingLeft = ValueNotifier(false);

  /// جای پیش از شروع کشیدن، برای بازگشت.
  Offset home;

  Offset get position => Offset(state.value.x, state.value.y);

  void play(String name) {
    anim = name;
    animTick.value++;
  }

  void dispose() {
    state.dispose();
    animTick.dispose();
    facingLeft.dispose();
  }
}

/// منطق یک صحنه‌ی تعاملی: لمس، کشیدن (آزاد یا روی مسیر)، رها کردن روی مقصد، ترکیب‌ها،
/// اهداف فعالیت و ذخیره‌ی وضعیت.
class SceneController extends ChangeNotifier {
  SceneController({required this.scene, Map<String, ObjectState> saved = const {}, this.onPersist}) {
    for (final d in scene.objects) {
      final s = d.persist ? saved[d.id] : null;
      objects[d.id] = SceneObjectRuntime(d, s ?? ObjectState(x: d.x, y: d.y));
    }
  }

  final SceneDef scene;

  /// در مرزهای تعامل (پایان کشیدن، روشن/خاموش، رشد) صدا زده می‌شود.
  final void Function(Map<String, ObjectState> states)? onPersist;

  final Map<String, SceneObjectRuntime> objects = {};
  final Map<String, int> _dropCounts = {};
  String? dragging;
  bool _goalsDone = false;

  bool get goalsDone => _goalsDone;

  /// پیشرفت اهداف (۰ تا ۱)، برای نوار پیشرفت فعالیت‌های نقش‌آفرینی.
  double get goalProgress {
    if (scene.goals.isEmpty) return 0;
    var have = 0.0;
    var need = 0.0;
    for (final g in scene.goals) {
      if (g.stage != null) {
        need += g.stage!;
        have += math.min(g.stage!, objects[g.target]?.state.value.stage ?? 0);
      } else if (g.on != null) {
        need += 1;
        if (objects[g.target]?.state.value.on == g.on) have += 1;
      } else {
        need += g.count;
        have += math.min(g.count, _dropCounts['${g.target}|${g.tag}'] ?? 0);
      }
    }
    return need == 0 ? 0 : have / need;
  }

  int dropCount(String target, String tag) => _dropCounts['$target|$tag'] ?? 0;

  void _persist() {
    final cb = onPersist;
    if (cb == null) return;
    cb({
      for (final o in objects.values)
        if (o.def.persist) o.def.id: o.state.value,
    });
  }

  // ── لمس ────────────────────────────────────────────────────────────────
  InteractionResult tap(String id) {
    final o = objects[id];
    if (o == null || o.state.value.hidden) return InteractionResult.none;
    final t = o.def.tap;
    if (t == null) {
      o.play('bounce');
      return InteractionResult(animate: {id: 'bounce'});
    }
    var changed = false;
    var s = o.state.value;
    if (t.toggle) {
      s = s.copyWith(on: !s.on);
      changed = true;
    }
    if (t.advance && o.def.states.isNotEmpty) {
      s = s.copyWith(stage: (s.stage + 1) % o.def.states.length);
      changed = true;
    }
    o.state.value = s;
    final anim = t.anim ?? 'bounce';
    o.play(anim);
    if (changed) _persist();
    final done = changed && _checkGoals();
    return InteractionResult(sound: t.sound, say: t.say, animate: {id: anim}, burstAt: t.burst ? o.position : null, goalCompleted: done);
  }

  // ── کشیدن ──────────────────────────────────────────────────────────────
  bool canDrag(String id) {
    final o = objects[id];
    return o != null && !o.state.value.hidden && o.def.drag != DragMode.none;
  }

  void startDrag(String id) {
    final o = objects[id];
    if (o == null || !canDrag(id)) return;
    dragging = id;
    o.home = o.position;
    notifyListeners();
  }

  /// جابه‌جایی به [to] (نسبی). شیء مسیری روی نزدیک‌ترین نقطه‌ی مسیر می‌ماند؛ شیء آزاد داخل صحنه.
  void moveTo(String id, Offset to) {
    final o = objects[id];
    if (o == null || !canDrag(id)) return;
    var p = Offset(to.dx.clamp(.02, .98), to.dy.clamp(.05, .97));
    if (o.def.drag == DragMode.path) {
      final path = scene.paths[o.def.path];
      if (path != null && path.length >= 2) p = projectOnPath(path, to);
    }
    final dx = p.dx - o.state.value.x;
    if (dx.abs() > .002) o.facingLeft.value = dx < 0;
    o.state.value = o.state.value.copyWith(x: p.dx, y: p.dy);
  }

  /// نزدیک‌ترین نقطه روی خط شکسته‌ی [path] به [p].
  static Offset projectOnPath(List<Offset> path, Offset p) {
    var best = path.first;
    var bestD = double.infinity;
    for (var i = 0; i + 1 < path.length; i++) {
      final a = path[i], b = path[i + 1];
      final ab = b - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0 ? 0.0 : (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      final q = a + ab * t;
      final d = (q - p).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = q;
      }
    }
    return Offset(best.dx.clamp(.02, .98), best.dy);
  }

  /// جعبه‌ی شیء به مختصات نسبی در صحنه‌ای به اندازه‌ی [stage].
  Rect boxOf(String id, Size stage) {
    final o = objects[id]!;
    final u = math.min(stage.width, stage.height);
    final hw = o.def.size * u / 2 / stage.width;
    final hh = o.def.size * u / 2 / stage.height;
    return Rect.fromLTRB(o.state.value.x - hw, o.state.value.y - hh, o.state.value.x + hw, o.state.value.y + hh);
  }

  /// مقصدی که [id] اگر همین‌جا رها شود رویش می‌افتد (و واکنشش)، یا null.
  (SceneObjectRuntime, DropReaction)? targetFor(String id, Size stage) {
    final o = objects[id];
    if (o == null || o.def.tags.isEmpty) return null;
    final at = o.position;
    (SceneObjectRuntime, DropReaction)? best;
    var bestD = double.infinity;
    for (final t in objects.values) {
      if (t.def.id == id || t.state.value.hidden || t.def.accepts.isEmpty) continue;
      final box = boxOf(t.def.id, stage).inflate(.02);
      if (!box.contains(at)) continue;
      for (final r in t.def.accepts) {
        if (!o.def.tags.contains(r.tag)) continue;
        final d = (t.position - at).distanceSquared;
        if (d < bestD) {
          bestD = d;
          best = (t, r);
        }
      }
    }
    return best;
  }

  /// پایان کشیدن: اگر روی مقصد معتبر باشد واکنش و ترکیب اجرا می‌شود.
  InteractionResult endDrag(String id, Size stage) {
    final o = objects[id];
    dragging = null;
    notifyListeners();
    if (o == null) return InteractionResult.none;
    final hit = targetFor(id, stage);
    if (hit == null) {
      _persist();
      return InteractionResult(sound: 'audio/ui/pop.mp3', animate: {id: 'squash'});
    }
    final (target, r) = hit;
    var ts = target.state.value;
    if (r.advance && target.def.states.isNotEmpty) {
      ts = ts.copyWith(stage: math.min(ts.stage + 1, target.def.states.length - 1));
    }
    if (r.turnOn) ts = ts.copyWith(on: true);
    target.state.value = ts;
    target.play(r.anim);
    switch (r.then) {
      case AfterDrop.hide:
        o.state.value = o.state.value.copyWith(hidden: true);
      case AfterDrop.back:
        o.state.value = o.state.value.copyWith(x: o.home.dx, y: o.home.dy);
        o.play('pop');
      case AfterDrop.stay:
        break;
    }
    _dropCounts['${target.def.id}|${r.tag}'] = (_dropCounts['${target.def.id}|${r.tag}'] ?? 0) + 1;
    _persist();
    final done = _checkGoals();
    notifyListeners();
    return InteractionResult(
      sound: r.sound,
      say: r.say,
      animate: {target.def.id: r.anim},
      burstAt: target.position,
      goalCompleted: done,
      matched: true,
      reaction: r,
    );
  }

  bool _checkGoals() {
    if (_goalsDone || scene.goals.isEmpty) return false;
    for (final g in scene.goals) {
      final t = objects[g.target];
      if (t == null) return false;
      if (g.stage != null) {
        if (t.state.value.stage < g.stage!) return false;
      } else if (g.on != null) {
        if (t.state.value.on != g.on) return false;
      } else if ((_dropCounts['${g.target}|${g.tag}'] ?? 0) < g.count) {
        return false;
      }
    }
    _goalsDone = true;
    notifyListeners();
    return true;
  }

  /// همه‌چیز به حالت اول (دکمه‌ی «از نو» در منوی مکث).
  void reset() {
    for (final o in objects.values) {
      o.state.value = ObjectState(x: o.def.x, y: o.def.y);
      o.facingLeft.value = false;
    }
    _dropCounts.clear();
    _goalsDone = false;
    _persist();
    notifyListeners();
  }

  @override
  void dispose() {
    for (final o in objects.values) {
      o.dispose();
    }
    super.dispose();
  }
}
