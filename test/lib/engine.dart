import 'package:samsara/samsara.dart';

final SamsaraEngine engine = SamsaraEngine(
  config: const EngineConfig(
    name: 'Samsara Engine Test',
    debugMode: true,
    showFps: true,
  ),
);

const windowSize = Size(1440.0, 810.0);
