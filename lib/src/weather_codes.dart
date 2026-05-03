/// WMO weather interpretation codes used by Open-Meteo.
/// https://open-meteo.com/en/docs#weathervariables
class WeatherCondition {
  const WeatherCondition({required this.label, required this.glyph});
  final String label;
  final String glyph;
}

WeatherCondition describeWeather(int code, {bool isDay = true}) {
  switch (code) {
    case 0:
      return WeatherCondition(label: 'Clear', glyph: isDay ? '☀' : '☾');
    case 1:
      return WeatherCondition(label: 'Mostly clear', glyph: isDay ? '🌤' : '☾');
    case 2:
      return const WeatherCondition(label: 'Partly cloudy', glyph: '⛅');
    case 3:
      return const WeatherCondition(label: 'Overcast', glyph: '☁');
    case 45:
    case 48:
      return const WeatherCondition(label: 'Fog', glyph: '🌫');
    case 51:
    case 53:
    case 55:
      return const WeatherCondition(label: 'Drizzle', glyph: '☂');
    case 56:
    case 57:
      return const WeatherCondition(label: 'Freezing drizzle', glyph: '❄');
    case 61:
    case 63:
    case 65:
      return const WeatherCondition(label: 'Rain', glyph: '☔');
    case 66:
    case 67:
      return const WeatherCondition(label: 'Freezing rain', glyph: '❄');
    case 71:
    case 73:
    case 75:
    case 77:
      return const WeatherCondition(label: 'Snow', glyph: '❄');
    case 80:
    case 81:
    case 82:
      return const WeatherCondition(label: 'Showers', glyph: '☔');
    case 85:
    case 86:
      return const WeatherCondition(label: 'Snow showers', glyph: '❄');
    case 95:
      return const WeatherCondition(label: 'Thunderstorm', glyph: '⛈');
    case 96:
    case 99:
      return const WeatherCondition(label: 'Thunder + hail', glyph: '⛈');
    default:
      return const WeatherCondition(label: 'Unknown', glyph: '·');
  }
}

String windDirectionLabel(double degrees) {
  const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  final i = ((degrees % 360) / 45).round() % 8;
  return directions[i];
}
