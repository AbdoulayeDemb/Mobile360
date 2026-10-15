import 'package:alert360_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';

import '../../data/models/signalement.dart';
import '../../data/repositories/signalement_repository.dart';

final mesSignalementsRepositoryProvider = Provider<SignalementRepository>((
  ref,
) {
  return SignalementRepository();
});

class MesSignalementsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final ValueChanged<String>? onDetailTap;

  const MesSignalementsScreen({super.key, this.onBack, this.onDetailTap});

  @override
  ConsumerState<MesSignalementsScreen> createState() =>
      _MesSignalementsScreenState();
}

class _MesSignalementsScreenState extends ConsumerState<MesSignalementsScreen> {
  String _selectedFilter = 'Tous';

  List<Signalement> _signalements = [];
  bool _isLoading = true;
  String? _errorMessage;
  int? _idCitoyenCharge;

  static const List<String> _filters = [
    'Tous',
    'Déclaré',
    'En cours',
    'Résolu',
    'Rejeté',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _chargerSignalements();
      }
    });
  }

  Future<void> _chargerSignalements({bool actualiser = false}) async {
    final authState = ref.read(authControllerProvider);

    if (authState.isLoading) {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      try {
        final auth = await ref.read(authControllerProvider.future);
        if (!mounted) return;

        if (auth == null) {
          setState(() {
            _isLoading = false;
            _signalements = [];
            _errorMessage = 'Connectez-vous pour consulter vos signalements.';
          });
          return;
        }

        await _chargerPourCitoyen(auth.idUtilisateur, auth.role);
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Impossible de vérifier votre session. Réessayez.';
        });
      }

      return;
    }

    if (authState.hasError) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de récupérer votre session. Réessayez.';
      });
      return;
    }

    final auth = authState.value;

    if (auth == null) {
      setState(() {
        _isLoading = false;
        _signalements = [];
        _errorMessage = 'Connectez-vous pour consulter vos signalements.';
      });
      return;
    }

    await _chargerPourCitoyen(auth.idUtilisateur, auth.role);
  }

  Future<void> _chargerPourCitoyen(int? idCitoyen, String? role) async {
    if (idCitoyen == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Identifiant du citoyen indisponible. Reconnectez-vous.';
      });
      return;
    }

    if (role?.toUpperCase() != 'CITOYEN') {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _signalements = [];
        _errorMessage = 'Cette liste est réservée aux comptes citoyens.';
      });
      return;
    }

    if (_idCitoyenCharge == idCitoyen && !_isLoading && _errorMessage == null) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _idCitoyenCharge = idCitoyen;
    });

    try {
      final result = await ref
          .read(mesSignalementsRepositoryProvider)
          .getSignalementsByCitoyen(idCitoyen);

      if (!mounted) return;

      result.sort((a, b) {
        final dateA = a.dateHeureAlerte;
        final dateB = b.dateHeureAlerte;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      setState(() {
        _signalements = result;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Impossible de charger vos signalements. Vérifiez votre connexion.';
      });
    }
  }

  String _statutLisible(String statut) {
    switch (statut.trim().toUpperCase()) {
      case 'DECLARE':
      case 'DÉCLARÉ':
      case 'DECLARÉ':
        return 'Déclaré';
      case 'EN_COURS':
      case 'EN COURS':
        return 'En cours';
      case 'RESOLU':
      case 'RÉSOLU':
        return 'Résolu';
      case 'REJETE':
      case 'REJETÉ':
        return 'Rejeté';
      default:
        return statut;
    }
  }

  Color _couleurStatut(String statut) {
    switch (statut.trim().toUpperCase()) {
      case 'DECLARE':
      case 'DÉCLARÉ':
      case 'DECLARÉ':
        return Colors.white; // Texte blanc pour le badge plein style maquette
      case 'EN_COURS':
      case 'EN COURS':
        return Colors.white;
      case 'RESOLU':
      case 'RÉSOLU':
        return Colors.white;
      case 'REJETE':
      case 'REJETÉ':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  Color _fondStatut(String statut) {
    switch (statut.trim().toUpperCase()) {
      case 'DECLARE':
      case 'DÉCLARÉ':
      case 'DECLARÉ':
        return const Color(0xFF3B82F6); // Bleu vif identique maquette
      case 'EN_COURS':
      case 'EN COURS':
        return const Color(0xFFF59E0B); // Orange vif identique maquette
      case 'RESOLU':
      case 'RÉSOLU':
        return const Color(0xFF10B981); // Vert vif identique maquette
      case 'REJETE':
      case 'REJETÉ':
        return const Color(0xFFDC2626);
      default:
        return AppColors.textSecondary;
    }
  }

  String _dateLisible(DateTime? date) {
    if (date == null) return 'Date non disponible';

    const mois = [
      'janv.',
      'févr.',
      'mars',
      'avr.',
      'mai',
      'juin',
      'juil.',
      'août',
      'sept.',
      'oct.',
      'nov.',
      'déc.',
    ];

    final localeDate = date.toLocal();
    return 'Signalé le ${localeDate.day} ${mois[localeDate.month - 1]} ${localeDate.year}';
  }

  String _localisation(Signalement signalement) {
    final repere = signalement.repereVisuel?.trim();

    if (repere != null && repere.isNotEmpty) {
      return repere;
    }

    final lat = signalement.latitudeGPS;
    final lng = signalement.longitudeGPS;

    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    }

    return 'Localisation non renseignée';
  }

  List<Signalement> get _signalementsFiltres {
    if (_selectedFilter == 'Tous') return _signalements;

    return _signalements.where((signalement) {
      return _statutLisible(signalement.statut) == _selectedFilter;
    }).toList();
  }

  void _ouvrirDetail(Signalement signalement) {
    widget.onDetailTap?.call(signalement.idSignalement.toString());
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _signalementsFiltres;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête fixe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap:
                        widget.onBack ?? () => Navigator.of(context).maybePop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.darkBlue,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mes signalements',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Voir tous mes signalements',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualiser',
                    onPressed: _isLoading
                        ? null
                        : () => _chargerSignalements(actualiser: true),
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.darkBlue,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Filtres horizontaux
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filters.map((filter) {
                    final isSelected = _selectedFilter == filter;

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() => _selectedFilter = filter);
                        },
                        selectedColor: AppColors.darkBlue,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.darkBlue,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.darkBlue
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.darkBlue,
                      ),
                    )
                  : _errorMessage != null
                  ? _MessageEtat(
                      icon: Icons.cloud_off_outlined,
                      message: _errorMessage!,
                      actionLabel: 'Réessayer',
                      onAction: () => _chargerSignalements(actualiser: true),
                    )
                  : filteredList.isEmpty
                  ? _MessageEtat(
                      icon: Icons.assignment_outlined,
                      message: _selectedFilter == 'Tous'
                          ? 'Vous n’avez pas encore de signalement.'
                          : 'Aucun signalement avec le statut « $_selectedFilter ».',
                    )
                  : RefreshIndicator(
                      color: AppColors.darkBlue,
                      onRefresh: () async {
                        _idCitoyenCharge = null;
                        await _chargerSignalements(actualiser: true);
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 4,
                        ),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final item = filteredList[index];

                          return _SignalementCard(
                            signalement: item,
                            categorie:
                                (item.categorieNom?.trim().isNotEmpty ?? false)
                                ? item.categorieNom!.toUpperCase()
                                : 'CATÉGORIE NON RENSEIGNÉE',
                            titre:
                                (item.description?.trim().isNotEmpty ?? false)
                                ? item.description!.trim()
                                : 'Aucune description disponible',
                            localisation: _localisation(item),
                            date: _dateLisible(item.dateHeureAlerte),
                            statut: _statutLisible(item.statut),
                            couleurStatut: _couleurStatut(item.statut),
                            bgStatut: _fondStatut(item.statut),
                            onTap: () => _ouvrirDetail(item),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageEtat extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageEtat({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SignalementCard extends StatelessWidget {
  final Signalement signalement;
  final String categorie;
  final String titre;
  final String localisation;
  final String date;
  final String statut;
  final Color couleurStatut;
  final Color bgStatut;
  final VoidCallback onTap;

  const _SignalementCard({
    required this.signalement,
    required this.categorie,
    required this.titre,
    required this.localisation,
    required this.date,
    required this.statut,
    required this.couleurStatut,
    required this.bgStatut,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = signalement.photoAvantUrl?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Catégorie et badge de statut plein style maquette
              Row(
                children: [
                  Expanded(
                    child: Text(
                      categorie,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: bgStatut,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statut,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: couleurStatut,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Photo et informations
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 72,
                      width: 72,
                      color: const Color(0xFFF1F5F9),
                      child: photoUrl != null && photoUrl.isNotEmpty
                          ? Image.network(
                              photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlue,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_pin,
                              color: Color(0xFF94A3B8),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                localisation,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Date et lien "Voir les détails"
              Row(
                children: [
                  Expanded(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Voir les détails',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBlue,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.darkBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() {
    return const Center(
      child: Icon(Icons.image_outlined, color: Color(0xFF94A3B8), size: 28),
    );
  }
}
