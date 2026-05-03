import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A geographic place. Either resolved from IP or returned by the
/// Open-Meteo geocoding endpoint.
@immutable
class Place {
  const Place({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.timezone,
  });

  final String name;
  final String country;
  final String? admin1;
  final double latitude;
  final double longitude;
  final String? timezone;

  String get displayLabel {
    if (admin1 != null && admin1!.isNotEmpty && admin1 != name) {
      return '$name, $admin1';
    }
    return name;
  }

  String get fullLabel => '$displayLabel · $country';

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.name == name &&
      other.country == country &&
      other.admin1 == admin1 &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(name, country, admin1, latitude, longitude);
}

@immutable
class HourlyPoint {
  const HourlyPoint({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.weatherCode,
  });

  final DateTime time;
  final double temperature;
  final int precipitationProbability;
  final double windSpeed;
  final int weatherCode;
}

@immutable
class DailyPoint {
  const DailyPoint({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.windSpeedMax,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;
  final double windSpeedMax;
  final int weatherCode;
  final DateTime sunrise;
  final DateTime sunset;
}

@immutable
class WeatherSnapshot {
  const WeatherSnapshot({
    required this.place,
    required this.fetchedAt,
    required this.currentTemperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.windDirection,
    required this.humidity,
    required this.isDay,
    required this.hourly,
    required this.daily,
  });

  final Place place;
  final DateTime fetchedAt;
  final double currentTemperature;
  final double apparentTemperature;
  final int weatherCode;
  final double windSpeed;
  final double windDirection;
  final int humidity;
  final bool isDay;
  final List<HourlyPoint> hourly;
  final List<DailyPoint> daily;

  DailyPoint? get today => daily.isEmpty ? null : daily.first;
}

/// Talks to Open-Meteo and ip-api.com. Both are free, no-auth, and
/// CORS-friendly so the demo works in browsers without a proxy.
class WeatherClient {
  WeatherClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Place> resolveCurrentLocation() async {
    final uri = Uri.parse('https://ipapi.co/json/');
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw _httpError('IP geolocation', response);
    }
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final lat = (json['latitude'] as num?)?.toDouble();
    final lon = (json['longitude'] as num?)?.toDouble();
    if (lat == null || lon == null) {
      throw const FormatException('IP geolocation missing coordinates');
    }
    return Place(
      name: (json['city'] as String?) ?? 'Here',
      country: (json['country_name'] as String?) ?? '',
      admin1: json['region'] as String?,
      latitude: lat,
      longitude: lon,
      timezone: json['timezone'] as String?,
    );
  }

  Future<List<Place>> searchCities(String query) async {
    if (query.trim().length < 2) return const [];
    final uri = Uri.https(
      'geocoding-api.open-meteo.com',
      '/v1/search',
      <String, String>{
        'name': query.trim(),
        'count': '8',
        'language': 'en',
        'format': 'json',
      },
    );
    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw _httpError('Geocoding', response);
    }
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final results = json['results'] as List<Object?>?;
    if (results == null) return const [];
    return [
      for (final entry in results)
        if (entry is Map<String, Object?>)
          Place(
            name: (entry['name'] as String?) ?? '',
            country: (entry['country'] as String?) ?? '',
            admin1: entry['admin1'] as String?,
            latitude: (entry['latitude'] as num).toDouble(),
            longitude: (entry['longitude'] as num).toDouble(),
            timezone: entry['timezone'] as String?,
          ),
    ];
  }

  Future<WeatherSnapshot> fetchForecast(Place place) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', <
      String,
      String
    >{
      'latitude': place.latitude.toString(),
      'longitude': place.longitude.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,is_day,'
          'weather_code,wind_speed_10m,wind_direction_10m',
      'hourly':
          'temperature_2m,precipitation_probability,wind_speed_10m,weather_code',
      'daily':
          'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,'
          'precipitation_sum,wind_speed_10m_max',
      'timezone': place.timezone ?? 'auto',
      'forecast_days': '7',
    });

    final response = await _client.get(uri);
    if (response.statusCode != 200) {
      throw _httpError('Forecast', response);
    }
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final current = json['current'] as Map<String, Object?>? ?? const {};
    final hourly = json['hourly'] as Map<String, Object?>? ?? const {};
    final daily = json['daily'] as Map<String, Object?>? ?? const {};

    return WeatherSnapshot(
      place: place,
      fetchedAt: DateTime.now(),
      currentTemperature: _double(current['temperature_2m']) ?? 0,
      apparentTemperature: _double(current['apparent_temperature']) ?? 0,
      weatherCode: _int(current['weather_code']) ?? 0,
      windSpeed: _double(current['wind_speed_10m']) ?? 0,
      windDirection: _double(current['wind_direction_10m']) ?? 0,
      humidity: _int(current['relative_humidity_2m']) ?? 0,
      isDay: (_int(current['is_day']) ?? 1) == 1,
      hourly: _parseHourly(hourly),
      daily: _parseDaily(daily),
    );
  }

  void close() => _client.close();

  // ----- helpers -----------------------------------------------------

  List<HourlyPoint> _parseHourly(Map<String, Object?> map) {
    final times = _stringList(map['time']);
    final temps = _doubleList(map['temperature_2m']);
    final precip = _intList(map['precipitation_probability']);
    final winds = _doubleList(map['wind_speed_10m']);
    final codes = _intList(map['weather_code']);
    final length = [
      times.length,
      temps.length,
      precip.length,
      winds.length,
      codes.length,
    ].reduce((a, b) => a < b ? a : b);
    return [
      for (var i = 0; i < length; i++)
        HourlyPoint(
          time: DateTime.parse(times[i]),
          temperature: temps[i],
          precipitationProbability: precip[i],
          windSpeed: winds[i],
          weatherCode: codes[i],
        ),
    ];
  }

  List<DailyPoint> _parseDaily(Map<String, Object?> map) {
    final dates = _stringList(map['time']);
    final maxs = _doubleList(map['temperature_2m_max']);
    final mins = _doubleList(map['temperature_2m_min']);
    final sums = _doubleList(map['precipitation_sum']);
    final winds = _doubleList(map['wind_speed_10m_max']);
    final codes = _intList(map['weather_code']);
    final sunrises = _stringList(map['sunrise']);
    final sunsets = _stringList(map['sunset']);
    final length = [
      dates.length,
      maxs.length,
      mins.length,
      sums.length,
      winds.length,
      codes.length,
      sunrises.length,
      sunsets.length,
    ].reduce((a, b) => a < b ? a : b);
    return [
      for (var i = 0; i < length; i++)
        DailyPoint(
          date: DateTime.parse(dates[i]),
          tempMax: maxs[i],
          tempMin: mins[i],
          precipitationSum: sums[i],
          windSpeedMax: winds[i],
          weatherCode: codes[i],
          sunrise: DateTime.parse(sunrises[i]),
          sunset: DateTime.parse(sunsets[i]),
        ),
    ];
  }

  Exception _httpError(String op, http.Response response) =>
      Exception('$op failed: HTTP ${response.statusCode}');

  double? _double(Object? v) =>
      v is num ? v.toDouble() : (v is String ? double.tryParse(v) : null);

  int? _int(Object? v) =>
      v is num ? v.toInt() : (v is String ? int.tryParse(v) : null);

  List<String> _stringList(Object? v) =>
      v is List ? v.whereType<String>().toList() : const [];

  List<double> _doubleList(Object? v) {
    if (v is! List) return const [];
    return [
      for (final element in v)
        if (element is num) element.toDouble(),
    ];
  }

  List<int> _intList(Object? v) {
    if (v is! List) return const [];
    return [
      for (final element in v)
        if (element is num) element.toInt(),
    ];
  }
}

/// Owns the active [Place] and the latest [WeatherSnapshot] / fetch
/// state. UI binds via [snapshot] (a [ValueListenable]).
class WeatherStore {
  WeatherStore({WeatherClient? client}) : _client = client ?? WeatherClient();

  final WeatherClient _client;
  Timer? _refreshTimer;
  Place? _place;

  final ValueNotifier<AsyncWeatherState> snapshot = ValueNotifier(
    const AsyncWeatherState.loading(),
  );

  Future<void> bootstrap() async {
    snapshot.value = const AsyncWeatherState.loading();
    try {
      final place = await _client.resolveCurrentLocation();
      await selectPlace(place);
    } catch (e) {
      // If IP lookup fails, fall back to a sensible default city.
      const fallback = Place(
        name: 'London',
        country: 'United Kingdom',
        latitude: 51.5074,
        longitude: -0.1278,
        timezone: 'Europe/London',
      );
      await selectPlace(fallback);
    }
  }

  Future<void> selectPlace(Place place) async {
    _place = place;
    snapshot.value = AsyncWeatherState.loading(place: place);
    await _refresh();
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => unawaited(_refresh()),
    );
  }

  Future<void> refresh() => _refresh();

  Future<List<Place>> searchCities(String query) => _client.searchCities(query);

  Future<void> _refresh() async {
    final place = _place;
    if (place == null) return;
    final previous = snapshot.value.snapshot;
    snapshot.value = AsyncWeatherState(
      place: place,
      snapshot: previous,
      isFetching: true,
    );
    try {
      final fresh = await _client.fetchForecast(place);
      snapshot.value = AsyncWeatherState(place: place, snapshot: fresh);
    } catch (e) {
      snapshot.value = AsyncWeatherState(
        place: place,
        snapshot: previous,
        error: e,
      );
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
    snapshot.dispose();
    _client.close();
  }
}

/// State envelope for the store. Mirrors the spec invariant: a fresh
/// fetch (or a failure) preserves the previous [snapshot] so the UI
/// keeps showing the last known data while the new one loads.
@immutable
class AsyncWeatherState {
  const AsyncWeatherState({
    this.place,
    this.snapshot,
    this.isFetching = false,
    this.error,
  });

  const AsyncWeatherState.loading({this.place})
    : snapshot = null,
      isFetching = true,
      error = null;

  final Place? place;
  final WeatherSnapshot? snapshot;
  final bool isFetching;
  final Object? error;

  bool get hasValue => snapshot != null;
  bool get isInitialLoading => isFetching && snapshot == null;
  bool get hasError => error != null;
}
