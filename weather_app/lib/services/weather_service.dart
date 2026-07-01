import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = '233bd5b2fc877748d8921efb70ce0c2a';
  static const String _weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _forecastBaseUrl =
      'https://api.openweathermap.org/data/2.5/forecast';

  Future<WeatherModel> getWeatherByCity(String cityName) async {
    final url = Uri.parse(
      '$_weatherBaseUrl?q=$cityName&appid=$_apiKey&units=metric&lang=id',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return WeatherModel.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Kota tidak ditemukan. Coba periksa ejaan nama kota.');
      } else if (response.statusCode == 401) {
        throw Exception(
            'API key tidak valid. Periksa kembali API key Anda di weather_service.dart.');
      } else {
        throw Exception(
            'Gagal mengambil data cuaca (kode ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    }
  }

  Future<List<ForecastItem>> getFiveDayForecastByCity(String cityName) async {
    final url = Uri.parse(
      '$_forecastBaseUrl?q=$cityName&appid=$_apiKey&units=metric&lang=id',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>;
        final forecasts = <ForecastItem>[];
        final seenDays = <String>{};

        for (final item in list) {
          final entry = item as Map<String, dynamic>;
          final date = DateTime.parse(entry['dt_txt'] as String);
          final dayKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

          if (!seenDays.contains(dayKey)) {
            seenDays.add(dayKey);
            forecasts.add(ForecastItem.fromJson(entry));
          }

          if (forecasts.length == 5) {
            break;
          }
        }

        return forecasts;
      } else if (response.statusCode == 404) {
        throw Exception('Kota tidak ditemukan. Coba periksa ejaan nama kota.');
      } else if (response.statusCode == 401) {
        throw Exception(
            'API key tidak valid. Periksa kembali API key Anda di weather_service.dart.');
      } else {
        throw Exception(
            'Gagal mengambil prakiraan cuaca (kode ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    }
  }

  Future<List<ForecastItem>> getHourlyForecastByCity(String cityName) async {
    final url = Uri.parse(
      '$_forecastBaseUrl?q=$cityName&appid=$_apiKey&units=metric&lang=id',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>;
        final forecasts = <ForecastItem>[];

        for (final item in list.take(6)) {
          forecasts.add(ForecastItem.fromJson(item as Map<String, dynamic>));
        }

        return forecasts;
      } else if (response.statusCode == 404) {
        throw Exception('Kota tidak ditemukan. Coba periksa ejaan nama kota.');
      } else if (response.statusCode == 401) {
        throw Exception(
            'API key tidak valid. Periksa kembali API key Anda di weather_service.dart.');
      } else {
        throw Exception(
            'Gagal mengambil prakiraan per jam (kode ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    }
  }

  Future<WeatherModel> getWeatherByLocation(double lat, double lon) async {
    final url = Uri.parse(
      '$_weatherBaseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=id',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return WeatherModel.fromJson(data);
      }
      return Future.error('Gagal mengambil data cuaca lokasi Anda.');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    }
  }

  Future<List<ForecastItem>> getFiveDayForecastByLocation(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      '$_forecastBaseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=id',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>;
        final forecasts = <ForecastItem>[];
        final seenDays = <String>{};

        for (final item in list) {
          final entry = item as Map<String, dynamic>;
          final date = DateTime.parse(entry['dt_txt'] as String);
          final dayKey =
              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

          if (!seenDays.contains(dayKey)) {
            seenDays.add(dayKey);
            forecasts.add(ForecastItem.fromJson(entry));
          }

          if (forecasts.length == 5) {
            break;
          }
        }

        return forecasts;
      }
      return Future.error('Gagal mengambil prakiraan cuaca lokasi Anda.');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    }
  }

  Future<List<ForecastItem>> getHourlyForecastByLocation(
    double lat,
    double lon,
  ) async {
    final url = Uri.parse(
      '$_forecastBaseUrl?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=id',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>;
        final forecasts = <ForecastItem>[];

        for (final item in list.take(6)) {
          forecasts.add(ForecastItem.fromJson(item as Map<String, dynamic>));
        }

        return forecasts;
      }
      return Future.error('Gagal mengambil prakiraan per jam lokasi Anda.');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    }
  }
}
