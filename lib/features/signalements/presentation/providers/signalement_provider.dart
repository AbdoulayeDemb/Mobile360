import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/signalement.dart';
import '../../data/models/signalement_request.dart';
import '../../data/repositories/signalement_repository.dart';

/// Fournit le repository des signalements.
final signalementRepositoryProvider = Provider<SignalementRepository>((ref) {
  return SignalementRepository();
});

/// Récupère automatiquement l'identifiant du citoyen connecté.
final currentCitoyenIdProvider = FutureProvider<int?>((ref) async {
  return ref.read(authServiceProvider).getCurrentUserId();
});

/// Récupère les signalements d'un citoyen.
final signalementsByCitoyenProvider =
    FutureProvider.family<List<Signalement>, int>((ref, idCitoyen) {
      return ref
          .watch(signalementRepositoryProvider)
          .getSignalementsByCitoyen(idCitoyen);
    });

/// Récupère le détail d'un signalement.
final signalementDetailProvider = FutureProvider.family<Signalement, int>((
  ref,
  idSignalement,
) {
  return ref
      .watch(signalementRepositoryProvider)
      .getSignalementById(idSignalement);
});

/// Gère la création d'un signalement.
class CreationSignalementNotifier extends AsyncNotifier<Signalement?> {
  @override
  Future<Signalement?> build() async => null;

  Future<Signalement> creerSignalement({
    required SignalementRequest request,
  }) async {
    state = const AsyncLoading();

    try {
      // Récupérer l'identifiant du citoyen connecté.
      final citoyenId = await ref.read(authServiceProvider).getCurrentUserId();

      if (citoyenId == null) {
        throw Exception(
          'Impossible de créer le signalement : '
          'aucun citoyen connecté.',
        );
      }

      // Construire la requête avec l'identifiant réel de la session.
      final requestAvecCitoyenConnecte = SignalementRequest(
        typeUrgence: request.typeUrgence,
        description: request.description,
        latitudeGPS: request.latitudeGPS,
        longitudeGPS: request.longitudeGPS,
        citoyenId: citoyenId,
        categorieId: request.categorieId,
        photoAvantUrl: request.photoAvantUrl,
        audioUrl: request.audioUrl,
        repereVisuel: request.repereVisuel,
      );

      final signalement = await ref
          .read(signalementRepositoryProvider)
          .creerSignalement(requestAvecCitoyenConnecte);

      // Actualiser les listes de signalements.
      ref.invalidate(signalementsByCitoyenProvider);

      state = AsyncData(signalement);
      return signalement;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

/// Provider de création d'un signalement.
final creationSignalementProvider =
    AsyncNotifierProvider<CreationSignalementNotifier, Signalement?>(
      CreationSignalementNotifier.new,
    );
