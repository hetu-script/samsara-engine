import 'package:samsara/samsara.dart';

final SamsaraEngine engine = SamsaraEngine(
  config: const EngineConfig(
    name: 'Card Game Test',
    debugMode: true,
  ),
);

late final Map<String, dynamic> cardsData;
