import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'src/weather_data.dart';
import 'src/weather_home.dart';

void main() {
  final store = WeatherStore()..bootstrap();
  runApp(
    MosaicApp(
      title: 'Mosaic Weather',
      builder: (context) => WeatherHome(store: store),
    ),
  );
}
