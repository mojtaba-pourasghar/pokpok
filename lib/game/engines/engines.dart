import 'package:flutter/widgets.dart';

import '../game_data.dart';
import 'action_engines.dart';
import 'backpack_engines.dart';
import 'drag_engines.dart';
import 'engine.dart';
import 'tap_engines.dart';

export 'engine.dart';

/// موتور هر گام از روی نامش (tools/content/build_game.py → ENGINES).
Widget buildEngine(StepDef step, EngineHost host, {Key? key}) => switch (step.engine) {
  'collect' => CollectEngine(key: key, step: step, host: host),
  'sort' => SortEngine(key: key, step: step, host: host),
  'cut' => CutEngine(key: key, step: step, host: host),
  'tap' => TapEngine(key: key, step: step, host: host),
  'rotate' => RotateEngine(key: key, step: step, host: host),
  'pour' => PourEngine(key: key, step: step, host: host),
  'timing' => TimingEngine(key: key, step: step, host: host),
  'assemble' => AssembleEngine(key: key, step: step, host: host),
  'order' => OrderEngine(key: key, step: step, host: host),
  'count' => CountEngine(key: key, step: step, host: host),
  'paint' => PaintEngine(key: key, step: step, host: host),
  'mix' => MixEngine(key: key, step: step, host: host),
  'scrub' => ScrubEngine(key: key, step: step, host: host),
  'dark' => DarkEngine(key: key, step: step, host: host),
  'trace' => TraceEngine(key: key, step: step, host: host),
  'rhythm' => RhythmEngine(key: key, step: step, host: host),
  'puzzle' => PuzzleEngine(key: key, step: step, host: host),
  'use' => UseEngine(key: key, step: step, host: host),
  'serve' => ServeEngine(key: key, step: step, host: host),
  'catch' => CatchEngine(key: key, step: step, host: host),
  'feed' => FeedEngine(key: key, step: step, host: host),
  'stack' => StackEngine(key: key, step: step, host: host),
  'blow' => BlowEngine(key: key, step: step, host: host),
  'steer' => SteerEngine(key: key, step: step, host: host),
  'connect' => ConnectEngine(key: key, step: step, host: host),
  'memory' => MemoryEngine(key: key, step: step, host: host),
  'whack' => WhackEngine(key: key, step: step, host: host),
  _ => TapEngine(key: key, step: step, host: host),
};

const engineNames = {
  'collect', 'sort', 'cut', 'tap', 'rotate', 'pour', 'timing', 'assemble', 'order', 'count', //
  'paint', 'mix', 'scrub', 'dark', 'trace', 'rhythm', 'puzzle', 'use', 'serve', //
  'catch', 'feed', 'stack', 'blow', 'steer', 'connect', 'memory', 'whack',
};
