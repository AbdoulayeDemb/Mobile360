import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/itineraire.dart';
import '../../data/models/mission.dart';
import '../providers/mission_provider.dart';
import '../widgets/agent_page_header.dart';
import '../widgets/mission_ui.dart';

class LocalisationMissionScreen extends ConsumerWidget {
  final int idSignalement;

  const LocalisationMissionScreen({super.key, required this.idSignalement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final missionAsync = ref.watch(missionDetailProvider(idSignalement));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AgentPageHeader(
              titre: 'Localisation',
              sousTitre: 'Itinéraire vers le lieu de la mission',
            ),
            Expanded(
              child: missionAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlue),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(error.toString(), textAlign: TextAlign.center),
                  ),
                ),
                data: (mission) => mission.aPositionGps
                    ? _CarteGuidage(mission: mission)
                    : const Center(
                        child: Text(
                          'Ce signalement ne contient pas de position GPS.',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarteGuidage extends ConsumerStatefulWidget {
  final Mission mission;

  const _CarteGuidage({required this.mission});

  @override
  ConsumerState<_CarteGuidage> createState() => _CarteGuidageState();
}

class _CarteGuidageState extends ConsumerState<_CarteGuidage> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _suiviPosition;

  LatLng? _positionAgent;
  Itineraire? _itineraire;
  bool _calculEnCours = true;
  String? _erreurPosition;

  LatLng get _destination => LatLng(
    widget.mission.signalement.latitudeGPS!,
    widget.mission.signalement.longitudeGPS!,
  );

  @override
  void initState() {
    super.initState();
    _demarrerGuidage();
  }

  @override
  void dispose() {
    _suiviPosition?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _demarrerGuidage() async {
    setState(() {
      _calculEnCours = true;
      _erreurPosition = null;
    });

    ref.invalidate(positionAgentProvider);
    final position = await ref.read(positionAgentProvider.future);

    if (!mounted) return;

    if (position == null) {
      setState(() {
        _calculEnCours = false;
        _erreurPosition =
            'Activez la localisation pour afficher votre itinéraire.';
      });
      return;
    }

    final depart = LatLng(position.latitude, position.longitude);

    final itineraire = await ref
        .read(itineraireServiceProvider)
        .calculer(depart: depart, arrivee: _destination);

    if (!mounted) return;

    setState(() {
      _positionAgent = depart;
      _itineraire = itineraire;
      _calculEnCours = false;
    });

    _cadrerTrajet();
    _suivreAgent();
  }

  /// Met à jour le marqueur de l'agent pendant son déplacement.
  void _suivreAgent() {
    _suiviPosition?.cancel();
    _suiviPosition =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 15,
          ),
        ).listen(
          (position) {
            if (!mounted) return;
            setState(() {
              _positionAgent = LatLng(position.latitude, position.longitude);
            });
          },
          onError: (Object e) => debugPrint('Suivi position : $e'),
        );
  }

  void _cadrerTrajet() {
    final points = [
      ?_positionAgent,
      _destination,
      ...?_itineraire?.points,
    ];

    if (points.length < 2) {
      _mapController.move(_destination, 15);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.fromLTRB(40, 90, 40, 200),
      ),
    );
  }

  Future<void> _ouvrirApplication(Uri uri) async {
    final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ouvert && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir l’application.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mission = widget.mission;
    final itineraire = _itineraire;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _destination, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.alert360.alert360_mobile',
            ),
            if (itineraire != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: itineraire.points,
                    strokeWidth: 6,
                    color: const Color(0xFF2563EB),
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                    pattern: itineraire.estApproximatif
                        ? StrokePattern.dashed(segments: const [12, 8])
                        : const StrokePattern.solid(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _destination,
                  width: 150,
                  height: 70,
                  alignment: Alignment.topCenter,
                  child: _MarqueurMission(code: mission.code),
                ),
                if (_positionAgent != null)
                  Marker(
                    point: _positionAgent!,
                    width: 56,
                    height: 56,
                    child: const _MarqueurAgent(),
                  ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('OpenStreetMap contributors'),
            ),
          ],
        ),

        // Destination et recentrage.
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 10,
                        color: MissionUi.bleuLien,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Guidage vers : ${mission.lieu} (${mission.code})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: const Color(0xFFEFF6FF),
                shape: const CircleBorder(
                  side: BorderSide(color: Color(0xFFBFDBFE)),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _calculEnCours ? null : _demarrerGuidage,
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.my_location_rounded,
                      size: 20,
                      color: MissionUi.bleuLien,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Carte de guidage.
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _CarteInstructions(
            itineraire: itineraire,
            calculEnCours: _calculEnCours,
            erreur: _erreurPosition,
            onArrive: () =>
                context.push('/agent/missions/${mission.id}/rapport'),
            onGoogleMaps: () => _ouvrirApplication(
              Uri.https('www.google.com', '/maps/dir/', {
                'api': '1',
                'destination':
                    '${_destination.latitude},${_destination.longitude}',
                'travelmode': 'driving',
              }),
            ),
            onWaze: () => _ouvrirApplication(
              Uri.https('waze.com', '/ul', {
                'll': '${_destination.latitude},${_destination.longitude}',
                'navigate': 'yes',
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _CarteInstructions extends StatelessWidget {
  final Itineraire? itineraire;
  final bool calculEnCours;
  final String? erreur;
  final VoidCallback onArrive;
  final VoidCallback onGoogleMaps;
  final VoidCallback onWaze;

  const _CarteInstructions({
    required this.itineraire,
    required this.calculEnCours,
    required this.erreur,
    required this.onArrive,
    required this.onGoogleMaps,
    required this.onWaze,
  });

  @override
  Widget build(BuildContext context) {
    final itineraire = this.itineraire;

    final instruction = calculEnCours
        ? 'Calcul de l’itinéraire...'
        : erreur ??
              itineraire?.prochaineInstruction ??
              (itineraire?.estApproximatif == true
                  ? 'Itinéraire approximatif (à vol d’oiseau)'
                  : 'Suivez l’itinéraire en bleu');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.darkBlue,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.turn_left_rounded,
                  color: Color(0xFF60A5FA),
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    instruction,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      itineraire?.dureeLisible ?? '-- min',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            itineraire == null
                                ? ''
                                : '(${itineraire.distanceLisible})',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: MissionUi.texteGris,
                            ),
                          ),
                          if (itineraire != null)
                            Text(
                              'Arrivée estimée: '
                              '${MissionUi.heure(itineraire.heureArrivee)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: onArrive,
                      style: FilledButton.styleFrom(
                        backgroundColor: MissionUi.bleuAction,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Arrivé sur place >',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text(
                      'Ouvrir dans : ',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        color: MissionUi.texteGris,
                      ),
                    ),
                    _LienExterne(libelle: 'Google Maps', onTap: onGoogleMaps),
                    const SizedBox(width: 10),
                    _LienExterne(libelle: 'Waze', onTap: onWaze),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LienExterne extends StatelessWidget {
  final String libelle;
  final VoidCallback onTap;

  const _LienExterne({required this.libelle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(
              libelle,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: MissionUi.bleuLien,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.north_east_rounded,
              size: 11,
              color: MissionUi.bleuLien,
            ),
          ],
        ),
      ),
    );
  }
}

class _MarqueurMission extends StatelessWidget {
  final String code;

  const _MarqueurMission({required this.code});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Mission $code',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const Icon(Icons.location_on, size: 40, color: Color(0xFFDC2626)),
      ],
    );
  }
}

class _MarqueurAgent extends StatelessWidget {
  const _MarqueurAgent();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: MissionUi.bleuAction.withValues(alpha: 0.25),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: MissionUi.bleuLien,
          border: Border.all(color: Colors.white, width: 3),
        ),
        child: const Icon(Icons.navigation_rounded, size: 15, color: Colors.white),
      ),
    );
  }
}
