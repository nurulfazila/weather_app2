import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/models/weather_model.dart';
import 'package:weather_app/screens/home_screen.dart';
import 'package:weather_app/services/weather_service.dart';

class FakeWeatherService extends WeatherService {
  @override
  Future<WeatherModel> getWeatherByCity(String cityName) async {
    return WeatherModel(
      cityName: cityName,
      country: 'ID',
      temperature: 30,
      feelsLike: 32,
      tempMin: 28,
      tempMax: 33,
      humidity: 70,
      windSpeed: 4.5,
      description: 'cerah berawan',
      mainCondition: 'Clouds',
      icon: '02d',
      pressure: 1012,
      dateTime: DateTime(2026, 6, 24, 12, 0),
    );
  }

  @override
  Future<List<ForecastItem>> getFiveDayForecastByCity(String cityName) async {
    return [
      ForecastItem(
        dateTime: DateTime(2026, 6, 25, 12, 0),
        temperature: 31,
        description: 'cerah',
        icon: '01d',
        mainCondition: 'Clear',
        precipitation: 0.0,
      ),
    ];
  }

  @override
  Future<List<ForecastItem>> getHourlyForecastByCity(String cityName) async {
    return [
      ForecastItem(
        dateTime: DateTime(2026, 6, 24, 13, 0),
        temperature: 31,
        description: 'cerah',
        icon: '01d',
        mainCondition: 'Clear',
        precipitation: 0.0,
      ),
    ];
  }
}

void main() {
  test('parses weather without wind data safely', () {
    final weather = WeatherModel.fromJson({
      'name': 'Bandung',
      'sys': {'country': 'ID'},
      'main': {
        'temp': 25,
        'feels_like': 24,
        'temp_min': 22,
        'temp_max': 26,
        'humidity': 80,
        'pressure': 1000,
      },
      'weather': [
        {'description': 'cerah', 'main': 'Clear', 'icon': '01d'}
      ],
    });

    expect(weather.windSpeed, 0.0);
  });

  testWidgets('shows favorites and forecast sections', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(weatherService: FakeWeatherService()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Favorit'), findsOneWidget);
    expect(find.text('Prakiraan 5 Hari'), findsOneWidget);
    expect(find.text('Prakiraan per Jam'), findsOneWidget);
    expect(find.text('°F'), findsOneWidget);
  });
}
