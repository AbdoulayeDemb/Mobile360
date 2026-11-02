import 'package:alert360_mobile/core/network/media_url_helper.dart';
import 'package:alert360_mobile/core/theme/app_colors.dart';
import 'package:alert360_mobile/features/agent_terrain/data/models/preuve_resolution.dart';
import 'package:alert360_mobile/features/agent_terrain/presentation/providers/mission_provider.dart';
import 'package:alert360_mobile/features/signalements/data/models/signalement.dart';
import 'package:alert360_mobile/features/signalements/presentation/providers/signalement_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preuveResolutionBySignalementProvider = FutureProvider.autoDispose
    .family<PreuveResolution?, int>((ref, id) {
      return ref.watch(missionRepositoryProvider).getPreuveBySignalement(id);
    });

class PreuvesResolutionScreen extends ConsumerWidget {
  const PreuvesResolutionScreen({super.key});

  Future<void> _actualiser(WidgetRef ref) async {
    ref.invalidate(currentCitoyenIdProvider);
    try {
      final idCitoyen = await ref.read(currentCitoyenIdProvider.future);
      if (idCitoyen != null) {
        ref.invalidate(signalementsByCitoyenProvider(idCitoyen));
        final signalements = await ref.read(
          signalementsByCitoyenProvider(idCitoyen).future,
        );
        for (final signalement in signalements.where(_estResolu)) {
          ref.invalidate(
            preuveResolutionBySignalementProvider(signalement.idSignalement),
          );
        }
      }
    } catch (_) {
      // L'état AsyncValue de la page affiche l'erreur de chargement.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citoyenIdAsync = ref.watch(currentCitoyenIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlue,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preuves de résolution',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Photos et rapports des interventions terminées',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      body: citoyenIdAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.darkBlue),
        ),
        error: (error, stackTrace) => _ErreurPreuves(
          message: 'Impossible de vérifier votre session.',
          onRetry: () => ref.invalidate(currentCitoyenIdProvider),
        ),
        data: (idCitoyen) {
          if (idCitoyen == null) {
            return const _EtatVide(
              message:
                  'Connectez-vous pour consulter les preuves de résolution.',
            );
          }

          final signalementsAsync = ref.watch(
            signalementsByCitoyenProvider(idCitoyen),
          );
          return signalementsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.darkBlue),
            ),
            error: (error, stackTrace) => _ErreurPreuves(
              message: 'Impossible de charger vos signalements.',
              onRetry: () =>
                  ref.invalidate(signalementsByCitoyenProvider(idCitoyen)),
            ),
            data: (signalements) {
              final resolus = signalements.where(_estResolu).toList()
                ..sort((a, b) {
                  final dateA =
                      a.dateHeureAlerte ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  final dateB =
                      b.dateHeureAlerte ??
                      DateTime.fromMillisecondsSinceEpoch(0);
                  return dateB.compareTo(dateA);
                });

              if (resolus.isEmpty) {
                return const _EtatVide(
                  message:
                      'Les preuves apparaîtront ici lorsque vos signalements '
                      'seront résolus par un agent.',
                );
              }

              return RefreshIndicator(
                color: AppColors.darkBlue,
                onRefresh: () => _actualiser(ref),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  itemCount: resolus.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 14),
                  itemBuilder: (context, index) =>
                      _PreuveResolutionCard(signalement: resolus[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _estResolu(Signalement signalement) {
    final statut = signalement.statut.trim().toUpperCase();
    return statut == 'RESOLU' || statut == 'RÉSOLU';
  }
}

class _PreuveResolutionCard extends ConsumerWidget {
  final Signalement signalement;

  const _PreuveResolutionCard({required this.signalement});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preuveAsync = ref.watch(
      preuveResolutionBySignalementProvider(signalement.idSignalement),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.task_alt_rounded,
                  color: Color(0xFF16A34A),
                  size: 21,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    signalement.categorieNom?.trim().isNotEmpty == true
                        ? signalement.categorieNom!.trim()
                        : 'Signalement résolu',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ),
                Text(
                  signalement.codeTrackingUnique?.trim().isNotEmpty == true
                      ? signalement.codeTrackingUnique!.trim()
                      : '#${signalement.idSignalement}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          preuveAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.darkBlue),
              ),
            ),
            error: (error, stackTrace) => _PreuveMessage(
              message: 'Impossible de charger la preuve de cette intervention.',
              actionLabel: 'Réessayer',
              onAction: () => ref.invalidate(
                preuveResolutionBySignalementProvider(
                  signalement.idSignalement,
                ),
              ),
            ),
            data: (preuve) {
              if (preuve == null) {
                return const _PreuveMessage(
                  message: 'La preuve de l’agent n’est pas encore disponible.',
                );
              }
              return _ContenuPreuve(preuve: preuve);
            },
          ),
        ],
      ),
    );
  }
}

class _ContenuPreuve extends StatelessWidget {
  final PreuveResolution preuve;

  const _ContenuPreuve({required this.preuve});

  @override
  Widget build(BuildContext context) {
    final photoUrl = MediaUrlHelper.construireUrl(preuve.photoApresUrl);
    final rapport = preuve.rapportSansStatut;
    final agent = [
      preuve.prenomAgent,
      preuve.nomAgent,
    ].where((part) => part?.trim().isNotEmpty == true).join(' ').trim();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photoUrl.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Image.network(
                photoUrl,
                width: double.infinity,
                height: 210,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const SizedBox(
                    height: 210,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkBlue,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text('Photo de l’intervention indisponible.'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (rapport.isNotEmpty) ...[
            const Text(
              'Rapport de l’agent',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              rapport,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.55,
                color: Color(0xFF475569),
              ),
            ),
          ],
          if (agent.isNotEmpty || preuve.dateResolution != null) ...[
            const SizedBox(height: 12),
            Text(
              [
                if (agent.isNotEmpty) 'Intervention par $agent',
                if (preuve.dateResolution != null)
                  'Le ${_dateLisible(preuve.dateResolution!)}',
              ].join(' • '),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (photoUrl.isEmpty && rapport.isEmpty)
            const _PreuveMessage(
              message:
                  'La preuve de résolution ne contient ni photo ni rapport.',
            ),
        ],
      ),
    );
  }

  String _dateLisible(DateTime date) {
    final local = date.toLocal();
    final jour = local.day.toString().padLeft(2, '0');
    final mois = local.month.toString().padLeft(2, '0');
    return '$jour/$mois/${local.year}';
  }
}

class _PreuveMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PreuveMessage({
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _ErreurPreuves extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErreurPreuves({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(height: 14),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EtatVide extends StatelessWidget {
  final String message;

  const _EtatVide({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fact_check_outlined,
              size: 54,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune preuve de résolution',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
