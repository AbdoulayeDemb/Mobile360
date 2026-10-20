import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherData {
  final double temperature;
  final int weatherCode;

  const WeatherData({required this.temperature, required this.weatherCode});

  String get description {
    if (weatherCode == 0) return 'Ciel dégagé';
    if ([1, 2, 3].contains(weatherCode)) return 'Nuageux';
    if ([45, 48].contains(weatherCode)) return 'Brouillard';
    if ([51, 53, 55, 61, 63, 65].contains(weatherCode)) {
      return 'Pluie';
    }
    if ([71, 73, 75, 77].contains(weatherCode)) {
      return 'Neige';
    }
    if ([80, 81, 82].contains(weatherCode)) {
      return 'Averses';
    }
    if ([95, 96, 99].contains(weatherCode)) {
      return 'Orage';
    }
    return 'Conditions variables';
  }

  String get icon {
    if (weatherCode == 0) return '☀️';
    if ([1, 2, 3].contains(weatherCode)) return '⛅';
    if ([45, 48].contains(weatherCode)) return '🌫️';
    if ([51, 53, 55, 61, 63, 65, 80, 81, 82].contains(weatherCode)) {
      return '🌧️';
    }
    if ([71, 73, 75, 77].contains(weatherCode)) return '❄️';
    if ([95, 96, 99].contains(weatherCode)) return '⛈️';
    return '🌤️';
  }
}

class WeatherService {
  Future<WeatherData> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current': 'temperature_2m,weather_code',
      'timezone': 'auto',
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Impossible de récupérer la météo.');
    }

    final json = jsonDecode(response.body);
    final current = json['current'];

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
    );
  }
}
