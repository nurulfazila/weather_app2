class WeatherModel {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String description;
  final String mainCondition;
  final String icon;
  final int pressure;
  final DateTime dateTime;

  WeatherModel({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.description,
    required this.mainCondition,
    required this.icon,
    required this.pressure,
    required this.dateTime,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] ?? '',
      country: json['sys']?['country'] ?? '',
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['main']?['feels_like'] as num?)?.toDouble() ?? 0.0,
      tempMin: (json['main']?['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (json['main']?['temp_max'] as num?)?.toDouble() ?? 0.0,
      humidity: json['main']?['humidity'] ?? 0,
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      description: json['weather']?[0]?['description'] ?? '',
      mainCondition: json['weather']?[0]?['main'] ?? '',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      pressure: json['main']?['pressure'] ?? 0,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
          (json['dt'] as int?)?.toInt() ?? 0),
    );
  }
}

class ForecastItem {
  final DateTime dateTime;
  final double temperature;
  final String description;
  final String mainCondition;
  final String icon;
  final double precipitation;

  ForecastItem({
    required this.dateTime,
    required this.temperature,
    required this.description,
    required this.mainCondition,
    required this.icon,
    required this.precipitation,
  });

  factory ForecastItem.fromJson(Map<String, dynamic> json) {
    final rain =
        ((json['rain']?['3h'] as num?) ?? (json['snow']?['3h'] as num?) ?? 0)
            .toDouble();

    return ForecastItem(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
          ((json['dt'] as num?)?.toInt() ?? 0) * 1000),
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      description: json['weather']?[0]?['description'] ?? '',
      mainCondition: json['weather']?[0]?['main'] ?? '',
      icon: json['weather']?[0]?['icon'] ?? '01d',
      precipitation: rain,
    );
  }
}
