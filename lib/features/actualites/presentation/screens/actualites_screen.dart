import 'package:alert360_mobile/features/actualites/presentation/providers/actualite_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/actualite.dart';

class ActualitesScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const ActualitesScreen({super.key, this.onBack});

  @override
  ConsumerState<ActualitesScreen> createState() => _ActualitesScreenState();
}

class _ActualitesScreenState extends ConsumerState<ActualitesScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedFilter = 'Toutes';
  String _searchQuery = '';
  bool _showSearch = false;

  final List<String> _filters = ['Toutes', 'Urgentes', 'Récentes'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;

      if (!_showSearch) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  Future<void> _refreshActualites() async {
    ref.invalidate(actualitesProvider);

    try {
      await ref.read(actualitesProvider.future);
    } catch (_) {
      // L'erreur sera affichée par l'état AsyncValue.
    }
  }

  List<Actualite> _filterActualites(List<Actualite> actualites) {
    final query = _searchQuery.trim().toLowerCase();

    var result = actualites.where((actualite) {
      if (query.isEmpty) return true;

      return actualite.titre.toLowerCase().contains(query) ||
          actualite.corpsTexte.toLowerCase().contains(query) ||
          (actualite.communeCible ?? '').toLowerCase().contains(query) ||
          (actualite.nomAdminAuteur ?? '').toLowerCase().contains(query);
    }).toList();

    switch (_selectedFilter) {
      case 'Urgentes':
        result = result.where((actualite) => actualite.estUrgent).toList();
        break;

      case 'Récentes':
        result.sort((a, b) {
          final dateA = a.datePublication;
          final dateB = b.datePublication;

          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;

          return dateB.compareTo(dateA);
        });
        break;
    }

    return result;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date non disponible';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
    }

    if (difference.inMinutes < 1) {
      return 'À l’instant';
    }

    if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    }

    if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    }

    if (difference.inDays == 1) {
      return 'Hier';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatFullDate(DateTime? date) {
    if (date == null) return 'Date non disponible';

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}'
        ' à ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  void _showActualiteDetail(Actualite actualite) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                      children: [
                        Row(
                          children: [
                            if (actualite.estUrgent)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.priority_high_rounded,
                                      color: Color(0xFFDC2626),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'URGENT',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Fermer',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          actualite.titre,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _DetailInfoRow(
                          icon: Icons.calendar_today_rounded,
                          text: _formatFullDate(actualite.datePublication),
                        ),
                        if ((actualite.communeCible ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _DetailInfoRow(
                            icon: Icons.location_on_outlined,
                            text: actualite.communeCible!,
                          ),
                        ],
                        if ((actualite.nomAdminAuteur ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _DetailInfoRow(
                            icon: Icons.person_outline_rounded,
                            text: actualite.nomAdminAuteur!,
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 22),
                          child: Divider(color: Color(0xFFE2E8F0)),
                        ),
                        const Text(
                          'Détails de l’actualité',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SelectableText(
                          actualite.corpsTexte.trim().isEmpty
                              ? 'Aucun détail supplémentaire disponible.'
                              : actualite.corpsTexte,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.8,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final actualitesAsync = ref.watch(actualitesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSearch) _buildSearchField(),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            _buildFilters(),
            Expanded(
              child: actualitesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlue),
                ),
                error: (error, stackTrace) => _buildErrorState(),
                data: (actualites) {
                  if (actualites.isEmpty) {
                    return _buildEmptyState(
                      title: 'Aucune actualité disponible',
                      message: 'Les nouvelles informations publiées apparaîtront ici.',
                      onRefresh: _refreshActualites,
                    );
                  }

                  final filtered = _filterActualites(actualites);

                  if (filtered.isEmpty) {
                    return _buildEmptyState(
                      title: 'Aucun résultat',
                      message: 'Essaie une autre recherche ou modifie le filtre sélectionné.',
                      onRefresh: _refreshActualites,
                    );
                  }

                  final urgentes = filtered
                      .where((actualite) => actualite.estUrgent)
                      .toList();

                  final actualiteALaUne = urgentes.isNotEmpty
                      ? urgentes.first
                      : null;

                  final recentes = actualiteALaUne == null
                      ? filtered
                      : filtered
                            .where(
                              (actualite) =>
                                  actualite.idActualite !=
                                  actualiteALaUne.idActualite,
                            )
                            .toList();

                  return RefreshIndicator(
                    onRefresh: _refreshActualites,
                    color: AppColors.darkBlue,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                      children: [
                        if (actualiteALaUne != null) ...[
                          _buildFeaturedCard(actualiteALaUne),
                          const SizedBox(height: 26),
                        ],
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'ACTUALITÉS PUBLIÉES',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkBlue,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Text(
                              '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (recentes.isEmpty && actualiteALaUne != null)
                          _buildOnlyFeaturedMessage()
                        else
                          ...recentes.map(
                            (actualite) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActualiteCard(actualite),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 42,
              width: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.darkBlue,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fil d’actualités',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Informations et communiqués officiels',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: IconButton(
              tooltip: _showSearch ? 'Fermer la recherche' : 'Rechercher',
              padding: EdgeInsets.zero,
              onPressed: _toggleSearch,
              icon: Icon(
                _showSearch ? Icons.close_rounded : Icons.search_rounded,
                color: const Color(0xFF2563EB),
                size: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Rechercher une actualité...',
          hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                  icon: const Icon(Icons.clear_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.darkBlue : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.darkBlue
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.darkBlue,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(Actualite actualite) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showActualiteDetail(actualite),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 190),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'ACTUALITÉ URGENTE',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                actualite.titre,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  height: 1.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                actualite.corpsTexte,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      _formatDate(actualite.datePublication),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActualiteCard(Actualite actualite) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showActualiteDetail(actualite),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: actualite.estUrgent
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  actualite.estUrgent
                      ? Icons.campaign_rounded
                      : Icons.article_outlined,
                  color: actualite.estUrgent
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (actualite.estUrgent)
                          _buildTag(
                            'URGENT',
                            const Color(0xFFFEE2E2),
                            const Color(0xFFB91C1C),
                          ),
                        if ((actualite.communeCible ?? '').trim().isNotEmpty)
                          _buildTag(
                            actualite.communeCible!.trim(),
                            const Color(0xFFEFF6FF),
                            const Color(0xFF1D4ED8),
                          ),
                      ],
                    ),
                    if (actualite.estUrgent ||
                        (actualite.communeCible ?? '').trim().isNotEmpty)
                      const SizedBox(height: 7),
                    Text(
                      actualite.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      actualite.corpsTexte,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatDate(actualite.datePublication),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 76,
              width: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFFDC2626),
                size: 35,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Impossible de charger les actualités',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vérifie ta connexion puis réessaie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshActualites,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.darkBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.darkBlue,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.10),
          Container(
            height: 86,
            width: 86,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.article_outlined,
              size: 42,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlue,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Actualiser'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlyFeaturedMessage() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF64748B)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'C’est tout pour le moment. Consulte cette actualité pour en savoir plus.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DetailInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }
}
