import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/categorie.dart';
import '../providers/categorie_provider.dart';

class CategoriesSelectionScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  // Transmet la catégorie complète : identifiant, nom et type de structure.
  final ValueChanged<Categorie>? onCategorySelected;

  const CategoriesSelectionScreen({
    super.key,
    this.onBack,
    this.onCategorySelected,
  });

  @override
  ConsumerState<CategoriesSelectionScreen> createState() =>
      _CategoriesSelectionScreenState();
}

class _CategoriesSelectionScreenState
    extends ConsumerState<CategoriesSelectionScreen> {
  Categorie? _selectedCategory;

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectCategory(Categorie categorie) {
    setState(() {
      _selectedCategory = categorie;
    });
  }

  void _onNext() {
    if (_selectedCategory == null) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 68,
                    width: 68,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.category_outlined,
                      color: Color(0xFFEA580C),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Catégorie requise',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 10),

                  const Text(
                    'Veuillez sélectionner une catégorie '
                    'correspondant au problème observé '
                    'avant de continuer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B5998),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Compris',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    widget.onCategorySelected?.call(_selectedCategory!);
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 1. En-tête fixe
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onBack ?? () => Navigator.of(context).pop(),
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
                          'Nouveau signalement',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Étape 1 sur 2 — Choix de la catégorie',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, color: Color(0xFF3B82F6), size: 8),
                        SizedBox(width: 6),
                        Text(
                          'GPS Actif',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // 2. Contenu défilable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Barre de recherche
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: AppColors.darkBlue,
                              ),
                              decoration: const InputDecoration(
                                hintText:
                                    'Quel est le problème observé ? '
                                    '(ex: nid-de-poule)',
                                hintStyle: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: Color(0xFF94A3B8),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            IconButton(
                              tooltip: 'Effacer la recherche',
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                            ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'CHOISISSEZ UNE CATÉGORIE',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlue,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Sélectionnez la catégorie correspondant au '
                      'problème observé.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Catégories chargées depuis le backend
                    categoriesAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF3B5998),
                          ),
                        ),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.cloud_off_outlined,
                                size: 44,
                                color: Color(0xFF94A3B8),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Impossible de charger les catégories.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  ref.invalidate(categoriesProvider);
                                },
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      data: (categories) {
                        final searchTerm = _searchController.text
                            .trim()
                            .toLowerCase();

                        final filteredCategories = categories.where((
                          categorie,
                        ) {
                          return categorie.nom.toLowerCase().contains(
                            searchTerm,
                          );
                        }).toList();

                        if (filteredCategories.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 40,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    categories.isEmpty
                                        ? 'Aucune catégorie disponible.'
                                        : 'Aucune catégorie trouvée.',
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${filteredCategories.length} catégorie(s)',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredCategories.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    mainAxisExtent: 110,
                                  ),
                              itemBuilder: (context, index) {
                                final Categorie categorie =
                                    filteredCategories[index];

                                return _CategoryCard(
                                  title: categorie.nom,
                                  subtitle: categorie.typeStructureCible ?? '',
                                  iconData: _getCategoryIcon(categorie),
                                  iconColor: _getCategoryColor(categorie),
                                  bgColor: _getCategoryBackground(categorie),
                                  isSelected:
                                      _selectedCategory?.idCategorie ==
                                      categorie.idCategorie,
                                  onTap: () => _selectCategory(categorie),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Bannière d'information GPS
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 32,
                            width: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B82F6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.info_outline_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Votre position GPS sera jointe '
                                  'automatiquement',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Vous pourrez ajouter une photo et '
                                  'une note vocale à l’étape suivante.',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: Color(0xFF3B82F6),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // 3. Bouton SUIVANT fixe en bas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B5998),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'SUIVANT',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Icônes indicatives selon le nom reçu du backend.
  IconData _getCategoryIcon(Categorie categorie) {
    final value = categorie.nom.toLowerCase();

    if (value.contains('police') ||
        value.contains('sécurité') ||
        value.contains('securite')) {
      return Icons.shield_outlined;
    }

    if (value.contains('pompier') ||
        value.contains('incendie') ||
        value.contains('feu')) {
      return Icons.local_fire_department_outlined;
    }

    if (value.contains('eau') ||
        value.contains('égout') ||
        value.contains('egout')) {
      return Icons.water_drop_outlined;
    }

    if (value.contains('électricité') ||
        value.contains('electricite') ||
        value.contains('électrique') ||
        value.contains('electrique')) {
      return Icons.bolt_outlined;
    }

    if (value.contains('déchet') ||
        value.contains('dechet') ||
        value.contains('salubrité') ||
        value.contains('salubrite')) {
      return Icons.delete_outline_rounded;
    }

    if (value.contains('route') ||
        value.contains('voirie') ||
        value.contains('chaussée') ||
        value.contains('chaussee')) {
      return Icons.add_location_alt_outlined;
    }

    return Icons.category_outlined;
  }

  Color _getCategoryColor(Categorie categorie) {
    final value = categorie.nom.toLowerCase();

    if (value.contains('police') ||
        value.contains('sécurité') ||
        value.contains('securite')) {
      return const Color(0xFFDC2626);
    }

    if (value.contains('pompier') ||
        value.contains('incendie') ||
        value.contains('feu')) {
      return const Color(0xFFEA580C);
    }

    if (value.contains('eau')) {
      return const Color(0xFF0284C7);
    }

    if (value.contains('électricité') ||
        value.contains('electricite') ||
        value.contains('électrique') ||
        value.contains('electrique')) {
      return const Color(0xFFD97706);
    }

    if (value.contains('déchet') ||
        value.contains('dechet') ||
        value.contains('salubrité') ||
        value.contains('salubrite')) {
      return const Color(0xFFEA580C);
    }

    return const Color(0xFF2563EB);
  }

  Color _getCategoryBackground(Categorie categorie) {
    final value = categorie.nom.toLowerCase();

    if (value.contains('police') ||
        value.contains('sécurité') ||
        value.contains('securite')) {
      return const Color(0xFFFEF2F2);
    }

    if (value.contains('pompier') ||
        value.contains('incendie') ||
        value.contains('feu')) {
      return const Color(0xFFFFF7ED);
    }

    if (value.contains('eau')) {
      return const Color(0xFFF0F9FF);
    }

    if (value.contains('électricité') ||
        value.contains('electricite') ||
        value.contains('électrique') ||
        value.contains('electrique')) {
      return const Color(0xFFFFFBEB);
    }

    if (value.contains('déchet') ||
        value.contains('dechet') ||
        value.contains('salubrité') ||
        value.contains('salubrite')) {
      return const Color(0xFFFFF7ED);
    }

    return const Color(0xFFEFF6FF);
  }
}

// Carte réutilisable de catégorie
class _CategoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData iconData;
  final Color iconColor;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.iconColor,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = isSelected
        ? AppColors.primaryBlue
        : const Color(0xFFE2E8F0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: activeBorderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppColors.primaryBlue.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: bgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(iconData, color: iconColor, size: 20),
                ),
                const Spacer(),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlue,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
