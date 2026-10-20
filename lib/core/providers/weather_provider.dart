import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../services/weather_service.dart';

final weatherServiceProvider = Provider<WeatherService>((ref) {
  return WeatherService();
});

final weatherProvider = FutureProvider<WeatherData>((ref) async {
  final service = ref.watch(weatherServiceProvider);

  final enabled = await Geolocator.isLocationServiceEnabled();

  if (!enabled) {
    throw Exception('Active la localisation de ton téléphone.');
  }

  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception('Autorise la localisation pour afficher la météo.');
  }

  final position = await Geolocator.getCurrentPosition();

  return service.getWeather(
    latitude: position.latitude,
    longitude: position.longitude,
  );
});
