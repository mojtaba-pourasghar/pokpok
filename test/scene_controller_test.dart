import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popo/core/content/content.dart';
import 'package:popo/data/models/models.dart';
import 'package:popo/features/worlds/engine/scene_controller.dart';

SceneDef scene(Map<String, dynamic> j) =>
    SceneDef.fromJson({'id': 't', 'world': 'w', 'title': 't', 'icon': 'sun', 'background': 'living', ...j});

void main() {
  const stage = Size(1000, 800);

  test('tap with toggle flips on/off and persists', () {
    Map<String, ObjectState>? saved;
    final c = SceneController(
      scene: scene({
        'objects': [
          {
            'id': 'lamp',
            'art': 'lamp',
            'x': .5,
            'y': .5,
            'size': .2,
            'glow': true,
            'tap': {'anim': 'pop', 'sound': 's.mp3', 'toggle': true},
          },
        ],
      }),
      onPersist: (s) => saved = s,
    );
    final r = c.tap('lamp');
    expect(r.sound, 's.mp3');
    expect(r.animate, {'lamp': 'pop'});
    expect(c.objects['lamp']!.state.value.on, isTrue);
    expect(saved!['lamp']!.on, isTrue);
    c.tap('lamp');
    expect(c.objects['lamp']!.state.value.on, isFalse);
  });

  test('path drag stays on the road polyline and faces the way it moves', () {
    final c = SceneController(
      scene: scene({
        'paths': {
          'road': [
            [0, .7],
            [1, .7],
          ],
        },
        'objects': [
          {'id': 'car', 'art': 'car', 'x': .5, 'y': .7, 'drag': 'path:road'},
        ],
      }),
    );
    c.startDrag('car');
    c.moveTo('car', const Offset(.3, .2));
    expect(c.objects['car']!.state.value.y, closeTo(.7, 1e-9));
    expect(c.objects['car']!.state.value.x, closeTo(.3, 1e-9));
    expect(c.objects['car']!.facingLeft.value, isTrue);
    c.moveTo('car', const Offset(.6, .95));
    expect(c.objects['car']!.facingLeft.value, isFalse);
  });

  test('projectOnPath picks the nearest segment', () {
    final p = SceneController.projectOnPath(const [Offset(0, 0), Offset(.5, .5), Offset(1, 0)], const Offset(.75, .4));
    expect(p.dx, closeTo(.675, .01));
    expect(p.dy, closeTo(.325, .01));
  });

  test('objects without drag cannot be moved', () {
    final c = SceneController(
      scene: scene({
        'objects': [
          {'id': 'tv', 'art': 'tv', 'x': .5, 'y': .5},
        ],
      }),
    );
    c.moveTo('tv', const Offset(.1, .1));
    expect(c.objects['tv']!.position, const Offset(.5, .5));
  });

  group('drop combinations', () {
    SceneController make() => SceneController(
      scene: scene({
        'goals': [
          {'target': 'pot', 'tag': 'food', 'count': 2},
        ],
        'objects': [
          {
            'id': 'pot',
            'art': 'pot',
            'x': .5,
            'y': .5,
            'size': .3,
            'accepts': [
              {'tag': 'food', 'anim': 'jump', 'sound': 'b.mp3', 'then': 'hide'},
            ],
          },
          {
            'id': 'dog',
            'art': 'dog',
            'x': .2,
            'y': .5,
            'size': .3,
            'accepts': [
              {'tag': 'toy', 'then': 'return'},
            ],
          },
          {
            'id': 'seed',
            'art': 'seed',
            'x': .8,
            'y': .5,
            'size': .3,
            'states': ['seed', 'sprout', 'flower_red'],
            'accepts': [
              {'tag': 'water', 'anim': 'grow', 'advance': true, 'then': 'return'},
            ],
          },
          {
            'id': 'carrot',
            'art': 'carrot',
            'x': .5,
            'y': .9,
            'drag': 'free',
            'tags': ['food'],
          },
          {
            'id': 'apple',
            'art': 'apple',
            'x': .6,
            'y': .9,
            'drag': 'free',
            'tags': ['food'],
          },
          {
            'id': 'ball',
            'art': 'ball',
            'x': .3,
            'y': .9,
            'drag': 'free',
            'tags': ['toy'],
          },
          {
            'id': 'can',
            'art': 'watering_can',
            'x': .9,
            'y': .9,
            'drag': 'free',
            'tags': ['water'],
          },
        ],
      }),
    );

    InteractionResult dropOn(SceneController c, String id, Offset at) {
      c.startDrag(id);
      c.moveTo(id, at);
      return c.endDrag(id, stage);
    }

    test('hide: dropped food disappears into the pot and counts toward the goal', () {
      final c = make();
      final r = dropOn(c, 'carrot', const Offset(.5, .5));
      expect(r.matched, isTrue);
      expect(r.sound, 'b.mp3');
      expect(c.objects['carrot']!.state.value.hidden, isTrue);
      expect(c.goalProgress, .5);
      expect(r.goalCompleted, isFalse);
      final r2 = dropOn(c, 'apple', const Offset(.52, .48));
      expect(r2.goalCompleted, isTrue);
      expect(c.goalsDone, isTrue);
    });

    test('return: the toy goes back to where the drag started', () {
      final c = make();
      final r = dropOn(c, 'ball', const Offset(.2, .5));
      expect(r.matched, isTrue);
      expect(c.objects['ball']!.position, const Offset(.3, .9));
    });

    test('advance: watering grows the seed one stage at a time, up to the last', () {
      final c = make();
      for (var i = 0; i < 4; i++) {
        dropOn(c, 'can', const Offset(.8, .5));
      }
      expect(c.objects['seed']!.state.value.stage, 2);
      expect(c.objects['seed']!.def.artFor(2), 'flower_red');
    });

    test('a tag the target does not accept is no match; the object stays where dropped', () {
      final c = make();
      final r = dropOn(c, 'ball', const Offset(.5, .5));
      expect(r.matched, isFalse);
      expect(c.objects['ball']!.position, const Offset(.5, .5));
      expect(c.objects['pot']!.state.value.hidden, isFalse);
    });

    test('reset restores every object and the goals', () {
      final c = make();
      dropOn(c, 'carrot', const Offset(.5, .5));
      c.reset();
      expect(c.objects['carrot']!.state.value.hidden, isFalse);
      expect(c.goalProgress, 0);
    });
  });

  test('saved states are restored only for persistent objects', () {
    final c = SceneController(
      scene: scene({
        'objects': [
          {'id': 'a', 'art': 'ball', 'x': .1, 'y': .1, 'drag': 'free'},
          {'id': 'b', 'art': 'ball', 'x': .1, 'y': .1, 'drag': 'free', 'persist': false},
        ],
      }),
      saved: {'a': const ObjectState(x: .7, y: .7), 'b': const ObjectState(x: .7, y: .7)},
    );
    expect(c.objects['a']!.position, const Offset(.7, .7));
    expect(c.objects['b']!.position, const Offset(.1, .1));
  });
}
