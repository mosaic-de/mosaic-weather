import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'src/walkthrough_gate.dart';
import 'src/weather_data.dart';
import 'src/weather_home.dart';

void main() {
  final store = WeatherStore()..bootstrap();
  runApp(
    MosaicApp(
      title: 'Mosaic Weather',
      builder: (context) => WalkthroughGate(
        prefsKey: 'weather_demo.walkthrough.seen',
        steps: const [
          MosaicWalkthroughStep(
            title: 'Welcome to Mosaic Weather',
            body:
                'Real Open-Meteo data for any city in the world — '
                'no demo state, no fake numbers.',
            glyph: '☀',
          ),
          MosaicWalkthroughStep(
            title: 'Auto-detected location',
            body:
                'On first launch we resolve your approximate '
                'location from your IP. Tap Change to pick another.',
            glyph: '⌖',
          ),
          MosaicWalkthroughStep(
            title: 'Forecast at a glance',
            body:
                'Now, next 12 hours, and 7 days. Wind, rain, sunrise '
                'and sunset live in the detail tiles below.',
            glyph: '◫',
          ),
          MosaicWalkthroughStep(
            title: 'Tune your style',
            body:
                'Use the bottom command bar to refresh, swap modes, '
                'or flip dark/light.',
            glyph: '◐',
          ),
        ],
        child: WeatherHome(store: store),
      ),
    ),
  );
}
