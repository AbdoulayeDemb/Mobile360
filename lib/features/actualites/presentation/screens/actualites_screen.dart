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

  static const Color _primary = Color(0xFF173B70);
  static const Color _blue = Color(0xFF2563EB);
  static const Color _text = Color(0xFF172B4D);
  static const Color _muted = Color(0xFF718096);
  static const Color _border = Color(0xFFE7ECF3);
  static const Color _surface = Color(0xFFF7F9FC);
  static const Color _red = Color(0xFFDC3545);

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
      // L'état AsyncValue affichera l'erreur.
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
        result = result.where((a) => a.estUrgent).toList();
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
      default:
        // Pour "Toutes", on conserve l'ordre du backend.
        break;
    }

    return result;
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date non disponible';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.isNegative) {
      return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
    }
    if (difference.inMinutes < 1) return 'À l’instant';
    if (difference.inHours < 1) return 'Il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'Il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return 'Il y a ${difference.inDays} jours';

    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _formatFullDate(DateTime? date) {
    if (date == null) return 'Date non disponible';
    return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}'
        ' à ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final actualitesAsync = ref.watch(actualitesProvider);

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_showSearch) _buildSearchField(),
            const Divider(height: 1, color: _border),
            _buildFilters(),
            Expanded(
              child: actualitesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _primary),
                ),
                error: (error, stackTrace) => _buildErrorState(),
                data: (actualites) {
                  if (actualites.isEmpty) {
                    return _buildEmptyState(
                      title: 'Aucune actualité disponible',
                      message: 'Les nouvelles informations publiées apparaîtront ici.',
                    );
                  }

                  final filtered = _filterActualites(actualites);

                  if (filtered.isEmpty) {
                    return _buildEmptyState(
                      title: 'Aucun résultat',
                      message: 'Essaie une autre recherche ou modifie le filtre sélectionné.',
                    );
                  }

                  // On met une actualité urgente en avant uniquement
                  // lorsqu'on consulte toutes les actualités.
                  final Actualite? featured = _selectedFilter == 'Toutes'
                      ? filtered.cast<Actualite?>().firstWhere(
                          (a) => a!.estUrgent,
                          orElse: () => null,
                        )
                      : null;

                  final remaining = featured == null
                      ? filtered
                      : filtered
                            .where((a) => a.idActualite != featured.idActualite)
                            .toList();

                  return RefreshIndicator(
                    onRefresh: _refreshActualites,
                    color: _primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                      children: [
                        if (featured != null) ...[
                          _buildFeaturedCard(featured),
                          const SizedBox(height: 28),
                        ],
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'FIL D’ACTUALITÉS',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _text,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${filtered.length} résultat${filtered.length > 1 ? 's' : ''}',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: _muted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (remaining.isEmpty && featured != null)
                          _buildOnlyFeaturedMessage()
                        else
                          ...remaining.map(
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
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          _circleButton(
            icon: Icons.arrow_back_rounded,
            onTap: widget.onBack ?? () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fil d’actualités',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                    height: 1.25,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Informations et communiqués officiels',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _circleButton(
            icon: _showSearch ? Icons.close_rounded : Icons.search_rounded,
            onTap: _toggleSearch,
            foreground: _blue,
            background: const Color(0xFFEDF4FF),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color foreground = _primary,
    Color background = Colors.white,
  }) {
    return Material(
      color: background,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: Icon(icon, color: foreground, size: 21),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Rechercher une actualité...',
          hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: _muted),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  icon: const Icon(Icons.clear_rounded),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _blue, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 9),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _selectedFilter == filter;

          return Material(
            color: selected ? _primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => setState(() => _selectedFilter = filter),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected ? _primary : const Color(0xFFDCE4EF),
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : _primary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActualiteImage(
    String? imageUrl, {
    required double height,
    double? width,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(14)),
  }) {
    final url = imageUrl?.trim();

    Widget placeholder() => Container(
      height: height,
      width: width ?? double.infinity,
      color: const Color(0xFFEDF2F8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 30,
        color: Color(0xFF91A0B5),
      ),
    );

    if (url == null ||
        url.isEmpty ||
        (!url.startsWith('https://') && !url.startsWith('http://'))) {
      return ClipRRect(borderRadius: borderRadius, child: placeholder());
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: Image.network(
        url,
        height: height,
        width: width ?? double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return SizedBox(
            height: height,
            width: width ?? double.infinity,
            child: Container(
              color: const Color(0xFFEDF2F8),
              alignment: Alignment.center,
              child: const SizedBox(
                width: 23,
                height: 23,
                child: CircularProgressIndicator(strokeWidth: 2, color: _blue),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder(),
      ),
    );
  }

  Widget _buildFeaturedCard(Actualite actualite) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showActualiteDetail(actualite),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((actualite.imageUrl ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: _buildActualiteImage(
                    actualite.imageUrl,
                    height: 185,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 16, 17, 17),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F1),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded, color: _red, size: 15),
                              SizedBox(width: 4),
                              Text(
                                'URGENT',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                  color: _red,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if ((actualite.communeCible ?? '').trim().isNotEmpty)
                          Flexible(
                            child: Text(
                              actualite.communeCible!.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: _muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      actualite.titre,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actualite.corpsTexte.trim().isEmpty
                          ? 'Consultez les détails de cette actualité.'
                          : actualite.corpsTexte.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        height: 1.6,
                        color: Color(0xFF68778D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 15,
                          color: _muted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatDate(actualite.datePublication),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: _muted,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 19,
                          color: _primary,
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

  Widget _buildActualiteCard(Actualite actualite) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showActualiteDetail(actualite),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildActualiteImage(
                actualite.imageUrl,
                height: 92,
                width: 94,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        if (actualite.estUrgent)
                          _buildTag('URGENT', const Color(0xFFFFF0F1), _red),
                        if ((actualite.communeCible ?? '').trim().isNotEmpty)
                          _buildTag(
                            actualite.communeCible!.trim(),
                            const Color(0xFFEDF4FF),
                            _blue,
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
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      actualite.corpsTexte.trim().isEmpty
                          ? 'Consultez les détails de cette actualité.'
                          : actualite.corpsTexte.trim(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        height: 1.45,
                        color: _muted,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 12,
                          color: _muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(actualite.datePublication),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: _muted,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 19,
                          color: _primary,
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

  Widget _buildTag(String label, Color background, Color foreground) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }

  void _showActualiteDetail(Actualite actualite) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.48,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 11),
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DFE9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      children: [
                        Row(
                          children: [
                            if (actualite.estUrgent)
                              _buildTag(
                                'ACTUALITÉ URGENTE',
                                const Color(0xFFFFF0F1),
                                _red,
                              ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              tooltip: 'Fermer',
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if ((actualite.imageUrl ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _buildActualiteImage(
                            actualite.imageUrl,
                            height: 205,
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ],
                        const SizedBox(height: 17),
                        Text(
                          actualite.titre,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                            text: actualite.communeCible!.trim(),
                          ),
                        ],
                        if ((actualite.nomAdminAuteur ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _DetailInfoRow(
                            icon: Icons.person_outline_rounded,
                            text: actualite.nomAdminAuteur!.trim(),
                          ),
                        ],
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: _border),
                        ),
                        const Text(
                          'Détails de l’actualité',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _text,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SelectableText(
                          actualite.corpsTexte.trim().isEmpty
                              ? 'Aucun détail supplémentaire disponible.'
                              : actualite.corpsTexte.trim(),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            height: 1.8,
                            color: Color(0xFF536278),
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, color: _red, size: 32),
            ),
            const SizedBox(height: 18),
            const Text(
              'Impossible de charger les actualités',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _text,
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
                color: _muted,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _refreshActualites,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({required String title, required String message}) {
    return RefreshIndicator(
      onRefresh: _refreshActualites,
      color: _primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.11),
          Container(
            height: 78,
            width: 78,
            decoration: const BoxDecoration(
              color: Color(0xFFEDF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.article_outlined, size: 37, color: _blue),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _text,
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
              color: _muted,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton.icon(
              onPressed: _refreshActualites,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _muted, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'C’est tout pour le moment. Consulte cette actualité pour en savoir plus.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.5,
                color: _muted,
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
        Icon(icon, size: 17, color: const Color(0xFF718096)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF718096),
            ),
          ),
        ),
      ],
    );
  }
}
