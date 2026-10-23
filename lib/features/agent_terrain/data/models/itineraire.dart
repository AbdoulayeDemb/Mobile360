import 'package:latlong2/latlong.dart';

class Itineraire {
  /// Points du tracé à afficher sur la carte.
  final List<LatLng> points;

  /// Distance totale en mètres.
  final double distanceMetres;

  /// Durée estimée en secondes.
  final double dureeSecondes;

  /// Prochaine instruction de guidage, si disponible.
  final String? prochaineInstruction;

  /// Indique un tracé à vol d'oiseau (service d'itinéraire indisponible).
  final bool estApproximatif;

  const Itineraire({
    required this.points,
    required this.distanceMetres,
    required this.dureeSecondes,
    this.prochaineInstruction,
    this.estApproximatif = false,
  });

  String get distanceLisible {
    if (distanceMetres < 1000) return '${distanceMetres.round()} m';
    return '${(distanceMetres / 1000).toStringAsFixed(1)} km';
  }

  String get dureeLisible {
    final minutes = (dureeSecondes / 60).ceil();
    if (minutes < 60) return '$minutes min';
    return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
  }

  DateTime get heureArrivee =>
      DateTime.now().add(Duration(seconds: dureeSecondes.round()));
}
