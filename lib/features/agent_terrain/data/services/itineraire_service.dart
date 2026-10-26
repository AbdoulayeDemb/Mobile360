import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/itineraire.dart';

class ItineraireService {
  /// Vitesse moyenne retenue en ville pour l'estimation hors ligne (km/h).
  static const double _vitesseMoyenneKmh = 25;

  /// Calcule l'itinéraire routier avec OSRM (OpenStreetMap).
  /// En cas d'échec, renvoie un tracé direct approximatif.
  Future<Itineraire> calculer({
    required LatLng depart,
    required LatLng arrivee,
  }) async {
    try {
      final uri = Uri.https(
        'router.project-osrm.org',
        '/route/v1/driving/'
            '${depart.longitude},${depart.latitude};'
            '${arrivee.longitude},${arrivee.latitude}',
        {'overview': 'full', 'geometries': 'geojson', 'steps': 'true'},
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Itinéraire indisponible.');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = json['routes'] as List?;

      if (routes == null || routes.isEmpty) {
        throw Exception('Aucun itinéraire trouvé.');
      }

      final route = routes.first as Map<String, dynamic>;
      final coordonnees =
          (route['geometry'] as Map<String, dynamic>)['coordinates'] as List;

      return Itineraire(
        points: coordonnees
            .map(
              (point) => LatLng(
                ((point as List)[1] as num).toDouble(),
                (point[0] as num).toDouble(),
              ),
            )
            .toList(),
        distanceMetres: (route['distance'] as num).toDouble(),
        dureeSecondes: (route['duration'] as num).toDouble(),
        prochaineInstruction: _prochaineInstruction(route),
      );
    } catch (_) {
      return _itineraireDirect(depart, arrivee);
    }
  }

  Itineraire _itineraireDirect(LatLng depart, LatLng arrivee) {
    final distance = Geolocator.distanceBetween(
      depart.latitude,
      depart.longitude,
      arrivee.latitude,
      arrivee.longitude,
    );

    return Itineraire(
      points: [depart, arrivee],
      distanceMetres: distance,
      dureeSecondes: distance / (_vitesseMoyenneKmh * 1000 / 3600),
      estApproximatif: true,
    );
  }

  /// Traduit la première manœuvre OSRM en consigne lisible.
  String? _prochaineInstruction(Map<String, dynamic> route) {
    final legs = route['legs'] as List?;
    if (legs == null || legs.isEmpty) return null;

    final steps = (legs.first as Map<String, dynamic>)['steps'] as List?;
    if (steps == null || steps.length < 2) return null;

    final depart = steps[0] as Map<String, dynamic>;
    final suivante = steps[1] as Map<String, dynamic>;
    final manoeuvre = suivante['maneuver'] as Map<String, dynamic>? ?? {};

    final distance = (depart['distance'] as num?)?.round() ?? 0;
    final type = manoeuvre['type'] as String? ?? '';
    final direction = manoeuvre['modifier'] as String? ?? '';
    final rue = (suivante['name'] as String?)?.trim() ?? '';

    if (type == 'arrive') return 'Vous arrivez à destination';

    final action = switch (direction) {
      'left' || 'sharp left' => 'tourner à gauche',
      'slight left' => 'serrer à gauche',
      'right' || 'sharp right' => 'tourner à droite',
      'slight right' => 'serrer à droite',
      'uturn' => 'faire demi-tour',
      _ => 'continuer tout droit',
    };

    final surRue = rue.isEmpty ? '' : ' sur $rue';

    return 'Dans $distance m, $action$surRue';
  }
}
