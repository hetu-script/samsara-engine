import 'package:samsara/samsara.dart';
import 'package:samsara/game_dialog.dart';

final SamsaraEngine engine = SamsaraEngine(
  config: const EngineConfig(
    name: 'Samsara Engine Test',
    developmentMode: true,
    showFps: true,
    enableLlm: false,
  ),
);

const windowSize = Size(1440.0, 810.0);

final dialog = GameDialog();
