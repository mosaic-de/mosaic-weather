import 'package:flutter/widgets.dart';
import 'package:mosaic_ui/mosaic_ui.dart';

import 'format.dart';
import 'weather_codes.dart';
import 'weather_data.dart';

class WeatherHome extends StatelessWidget {
  const WeatherHome({super.key, required this.store});

  final WeatherStore store;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: MosaicSurfaceHost(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spacing.md),
              child: Column(
                children: [
                  Expanded(
                    child: ValueListenableBuilder<AsyncWeatherState>(
                      valueListenable: store.snapshot,
                      builder: (context, state, _) =>
                          _Body(state: state, store: store),
                    ),
                  ),
                  SizedBox(height: tokens.spacing.sm),
                  _CommandBar(store: store),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.store});

  final AsyncWeatherState state;
  final WeatherStore store;

  @override
  Widget build(BuildContext context) {
    if (state.isInitialLoading) {
      return const _Loading(message: 'Locating you…');
    }
    final snap = state.snapshot;
    if (snap == null) {
      return _Error(error: state.error ?? 'No data');
    }
    return _Loaded(state: state, snapshot: snap, store: store);
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return Center(
      child: Text(
        message,
        style: tokens.typography.body.copyWith(
          color: tokens.color.textSecondary,
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load weather',
              style: tokens.typography.title.copyWith(
                color: tokens.color.textPrimary,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: tokens.typography.body.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.state,
    required this.snapshot,
    required this.store,
  });

  final AsyncWeatherState state;
  final WeatherSnapshot snapshot;
  final WeatherStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(state: state, store: store),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _CurrentBlock(snapshot: snapshot),
                _HourlyBlock(hourly: snapshot.hourly),
                _DailyBlock(daily: snapshot.daily),
                _DetailGrid(snapshot: snapshot),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.store});

  final AsyncWeatherState state;
  final WeatherStore store;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final place = state.place ?? state.snapshot?.place;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place?.displayLabel ?? 'Weather',
                  style: tokens.typography.headline.copyWith(
                    color: tokens.color.textPrimary,
                  ),
                ),
                if (state.snapshot != null)
                  Text(
                    '${place?.country ?? ''} · '
                    'updated ${formatRelativeFromNow(state.snapshot!.fetchedAt)}'
                    '${state.isFetching ? ' · refreshing' : ''}',
                    style: tokens.typography.caption.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  )
                else if (state.hasError)
                  Text(
                    'Last fetch failed',
                    style: tokens.typography.caption.copyWith(
                      color: tokens.color.error,
                    ),
                  ),
              ],
            ),
          ),
          MosaicPressFeedback(
            onPressed: () {
              MosaicSurfaceScope.of(
                context,
              ).push((_) => CitySearchPanel(store: store));
            },
            semanticLabel: 'Change city',
            child: MosaicSurface(
              kind: MosaicSurfaceKind.muted,
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spacing.md,
                vertical: tokens.spacing.sm,
              ),
              child: Text(
                '⌕ Change',
                style: tokens.typography.tileTitle.copyWith(
                  color: tokens.color.accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentBlock extends StatelessWidget {
  const _CurrentBlock({required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final condition = describeWeather(
      snapshot.weatherCode,
      isDay: snapshot.isDay,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
      child: MosaicSurface(
        kind: MosaicSurfaceKind.tile,
        padding: EdgeInsets.all(tokens.spacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    condition.label,
                    style: tokens.typography.tileSubtitle.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  ),
                  SizedBox(height: tokens.spacing.xs),
                  Text(
                    formatTemp(snapshot.currentTemperature),
                    style: tokens.typography.display.copyWith(
                      color: tokens.color.textPrimary,
                    ),
                  ),
                  Text(
                    'Feels like ${formatTemp(snapshot.apparentTemperature)}',
                    style: tokens.typography.caption.copyWith(
                      color: tokens.color.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(condition.glyph, style: const TextStyle(fontSize: 72)),
          ],
        ),
      ),
    );
  }
}

class _HourlyBlock extends StatelessWidget {
  const _HourlyBlock({required this.hourly});

  final List<HourlyPoint> hourly;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final now = DateTime.now();
    final upcoming = hourly
        .where((p) => p.time.isAfter(now.subtract(const Duration(hours: 1))))
        .take(12)
        .toList();
    if (upcoming.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
      child: MosaicSurface(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next 12 hours',
              style: tokens.typography.tileSubtitle.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: upcoming.length,
                separatorBuilder: (_, _) => SizedBox(width: tokens.spacing.md),
                itemBuilder: (context, i) {
                  final point = upcoming[i];
                  final cond = describeWeather(point.weatherCode);
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatHour(point.time),
                        style: tokens.typography.caption.copyWith(
                          color: tokens.color.textSecondary,
                        ),
                      ),
                      Text(cond.glyph, style: const TextStyle(fontSize: 24)),
                      Text(
                        formatTemp(point.temperature),
                        style: tokens.typography.body.copyWith(
                          color: tokens.color.textPrimary,
                        ),
                      ),
                      Text(
                        '${point.precipitationProbability}%',
                        style: tokens.typography.caption.copyWith(
                          color: tokens.color.accent,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyBlock extends StatelessWidget {
  const _DailyBlock({required this.daily});

  final List<DailyPoint> daily;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    if (daily.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
      child: MosaicSurface(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: tokens.spacing.sm),
              child: Text(
                '7-day forecast',
                style: tokens.typography.tileSubtitle.copyWith(
                  color: tokens.color.textSecondary,
                ),
              ),
            ),
            for (final day in daily) _DailyRow(day: day),
          ],
        ),
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  const _DailyRow({required this.day});

  final DailyPoint day;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final cond = describeWeather(day.weatherCode);
    final isToday =
        day.date.day == DateTime.now().day &&
        day.date.month == DateTime.now().month;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(
              isToday ? 'Today' : formatWeekdayShort(day.date),
              style: tokens.typography.body.copyWith(
                color: tokens.color.textPrimary,
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(cond.glyph, style: const TextStyle(fontSize: 18)),
          ),
          Expanded(
            child: Text(
              cond.label,
              style: tokens.typography.body.copyWith(
                color: tokens.color.textSecondary,
              ),
            ),
          ),
          Text(
            formatTempRange(day.tempMin, day.tempMax),
            style: tokens.typography.body.copyWith(
              color: tokens.color.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGrid extends StatelessWidget {
  const _DetailGrid({required this.snapshot});

  final WeatherSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final today = snapshot.today;
    final entries = <_DetailEntry>[
      _DetailEntry(
        label: 'Wind',
        value: '${snapshot.windSpeed.round()} km/h',
        sub: windDirectionLabel(snapshot.windDirection),
      ),
      _DetailEntry(
        label: 'Humidity',
        value: '${snapshot.humidity}%',
        sub: 'Relative',
      ),
      if (today != null)
        _DetailEntry(
          label: 'Sunrise',
          value: formatTimeOfDay(today.sunrise.toLocal()),
          sub: 'Today',
        ),
      if (today != null)
        _DetailEntry(
          label: 'Sunset',
          value: formatTimeOfDay(today.sunset.toLocal()),
          sub: 'Today',
        ),
      if (today != null)
        _DetailEntry(
          label: 'Rain',
          value: '${today.precipitationSum.toStringAsFixed(1)} mm',
          sub: 'Today',
        ),
      if (today != null)
        _DetailEntry(
          label: 'Wind max',
          value: '${today.windSpeedMax.round()} km/h',
          sub: 'Today',
        ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.spacing.sm),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final col = constraints.maxWidth > 360 ? 3 : 2;
          return Wrap(
            spacing: tokens.spacing.sm,
            runSpacing: tokens.spacing.sm,
            children: [
              for (final entry in entries)
                SizedBox(
                  width:
                      (constraints.maxWidth - tokens.spacing.sm * (col - 1)) /
                      col,
                  child: _DetailTile(entry: entry),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailEntry {
  const _DetailEntry({
    required this.label,
    required this.value,
    required this.sub,
  });
  final String label;
  final String value;
  final String sub;
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.entry});

  final _DetailEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    return MosaicSurface(
      padding: EdgeInsets.all(tokens.spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            entry.label,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.textSecondary,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            entry.value,
            style: tokens.typography.metric.copyWith(
              color: tokens.color.textPrimary,
            ),
          ),
          SizedBox(height: tokens.spacing.xs),
          Text(
            entry.sub,
            style: tokens.typography.caption.copyWith(
              color: tokens.color.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandBar extends StatelessWidget {
  const _CommandBar({required this.store});

  final WeatherStore store;

  @override
  Widget build(BuildContext context) {
    final app = MosaicAppScope.of(context);
    return MosaicCommandBar(
      commands: [
        MosaicCommand(label: 'Refresh', glyph: '↻', onPressed: store.refresh),
        MosaicCommand(
          label: app.mode == MosaicMode.metro ? 'Modern' : 'Metro',
          glyph: '◐',
          onPressed: app.toggleMode,
        ),
        MosaicCommand(
          label: app.brightness == Brightness.dark ? 'Light' : 'Dark',
          glyph: '☀',
          onPressed: app.toggleBrightness,
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// City search panel
// ----------------------------------------------------------------------

class CitySearchPanel extends StatefulWidget {
  const CitySearchPanel({super.key, required this.store});

  final WeatherStore store;

  @override
  State<CitySearchPanel> createState() => _CitySearchPanelState();
}

class _CitySearchPanelState extends State<CitySearchPanel> {
  String _query = '';
  bool _searching = false;
  List<Place> _results = const [];
  Object? _error;

  Future<void> _runSearch(String value) async {
    setState(() {
      _query = value;
      _searching = true;
      _error = null;
    });
    try {
      final places = await widget.store.searchCities(value);
      if (!mounted) return;
      setState(() {
        _results = places;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = MosaicTheme.of(context);
    final scope = MosaicSurfaceScope.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spacing.md,
        vertical: tokens.spacing.md,
      ),
      child: MosaicPanel(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MosaicPressFeedback(
                  onPressed: scope.pop,
                  semanticLabel: 'Back',
                  child: MosaicSurface(
                    kind: MosaicSurfaceKind.muted,
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.spacing.sm,
                      vertical: tokens.spacing.xs,
                    ),
                    child: Text(
                      '←',
                      style: tokens.typography.title.copyWith(
                        color: tokens.color.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: tokens.spacing.md),
                Expanded(
                  child: Text(
                    'Change city',
                    style: tokens.typography.title.copyWith(
                      color: tokens.color.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.spacing.md),
            MosaicSearchInput(
              placeholder: 'City',
              autofocus: true,
              onChanged: _runSearch,
            ),
            SizedBox(height: tokens.spacing.sm),
            Flexible(child: _resultBody(tokens, scope)),
          ],
        ),
      ),
    );
  }

  Widget _resultBody(MosaicTokens tokens, MosaicSurfaceScope scope) {
    if (_query.trim().length < 2) {
      return Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Text(
          'Type at least two letters',
          style: tokens.typography.body.copyWith(
            color: tokens.color.textSecondary,
          ),
        ),
      );
    }
    if (_searching) {
      return Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Text(
          'Searching…',
          style: tokens.typography.body.copyWith(
            color: tokens.color.textSecondary,
          ),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Text(
          'Search failed: $_error',
          style: tokens.typography.body.copyWith(color: tokens.color.error),
        ),
      );
    }
    if (_results.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(tokens.spacing.md),
        child: Text(
          'No matches',
          style: tokens.typography.body.copyWith(
            color: tokens.color.textSecondary,
          ),
        ),
      );
    }
    return MosaicList(
      shrinkWrap: true,
      rows: [
        for (final place in _results)
          MosaicListRow(
            title: place.displayLabel,
            subtitle: place.country,
            onPressed: () {
              widget.store.selectPlace(place);
              scope.pop();
            },
          ),
      ],
    );
  }
}
