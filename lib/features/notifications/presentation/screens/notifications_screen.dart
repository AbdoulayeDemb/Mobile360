import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;

  const NotificationsScreen({super.key, this.onBack});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  String _selectedFilter = 'Toutes';

  final List<String> _filters = ['Toutes', 'Non lues'];

  bool _isMarkingAllRead = false;

  Future<void> _actualiser() async {
    ref.invalidate(mesNotificationsProvider);
    ref.invalidate(notificationsNonLuesProvider);
    ref.invalidate(nombreNotificationsNonLuesProvider);

    await ref.read(mesNotificationsProvider.future);
  }

  Future<void> _marquerCommeLue(NotificationModel notification) async {
    if (notification.estLue) return;

    try {
      await ref
          .read(notificationRepositoryProvider)
          .marquerCommeLue(notification.idNotification);

      ref.invalidate(mesNotificationsProvider);
      ref.invalidate(notificationsNonLuesProvider);
      ref.invalidate(nombreNotificationsNonLuesProvider);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de marquer cette notification comme lue.'),
        ),
      );
    }
  }

  Future<void> _toutMarquerCommeLu() async {
    setState(() => _isMarkingAllRead = true);

    try {
      await ref.read(notificationRepositoryProvider).marquerToutesCommeLues();

      ref.invalidate(mesNotificationsProvider);
      ref.invalidate(notificationsNonLuesProvider);
      ref.invalidate(nombreNotificationsNonLuesProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Toutes les notifications ont été lues.')),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre à jour les notifications.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  List<NotificationModel> _filtrer(List<NotificationModel> notifications) {
    final result = notifications.where((notification) {
      if (_selectedFilter == 'Non lues') {
        return !notification.estLue;
      }

      return true;
    }).toList();

    // Les notifications les plus récentes en premier.
    result.sort((a, b) {
      final dateA = a.dateCreation;
      final dateB = b.dateCreation;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(mesNotificationsProvider);
    final nombreNonLuesAsync = ref.watch(nombreNotificationsNonLuesProvider);

    final nombreNonLues = nombreNonLuesAsync.when(
      data: (nombre) => nombre,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête conservé
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
                          'Mes notifications',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Suivez vos signalements en temps réel',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (nombreNonLues > 0)
                    IconButton(
                      tooltip: 'Tout marquer comme lu',
                      onPressed: _isMarkingAllRead ? null : _toutMarquerCommeLu,
                      icon: _isMarkingAllRead
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.done_all_rounded,
                              color: AppColors.darkBlue,
                            ),
                    ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Filtres horizontaux conservés
            Padding(
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
                        setState(() => _selectedFilter = filter);
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filter,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.darkBlue,
                                ),
                              ),
                              if (filter == 'Non lues' &&
                                  nombreNonLues > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$nombreNonLues',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? AppColors.darkBlue
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Liste dynamique depuis le backend
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.darkBlue),
                ),
                error: (error, stackTrace) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off_rounded,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Impossible de charger les notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vérifiez votre connexion puis réessayez.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _actualiser,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Réessayer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.darkBlue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (notifications) {
                  final filtered = _filtrer(notifications);

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: _actualiser,
                    color: AppColors.darkBlue,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = filtered[index];
                        final id = notification.idNotification;

                        return _NotificationCard(
                          notification: notification,
                          onTap: () => _marquerCommeLue(notification),
                        );
                      },
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

  Widget _buildEmptyState() {
    final isUnread = _selectedFilter == 'Non lues';

    final icon = isUnread
        ? Icons.notifications_none_rounded
        : Icons.notifications_active_outlined;

    final message = isUnread
        ? 'Vous êtes à jour !'
        : 'Aucune notification pour le moment';

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 82,
                    width: 82,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 38, color: AppColors.darkBlue),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Les mises à jour de vos signalements apparaîtront ici.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
  });

  Color get _typeColor {
    switch (notification.type) {
      case 'ALERTE_URGENTE':
        return const Color(0xFFDC2626);
      case 'CHANGEMENT_STATUT':
        return const Color(0xFF2563EB);
      case 'ATTRIBUTION_SIGNALEMENT':
        return const Color(0xFFF59E0B);
      case 'NOUVELLE_ACTUALITE':
        return const Color(0xFF7C3AED);
      case 'NOUVEAU_CONTENU_EDUCATIF':
        return const Color(0xFF0D9488);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get _typeIcon {
    switch (notification.type) {
      case 'ALERTE_URGENTE':
        return Icons.warning_amber_rounded;
      case 'CHANGEMENT_STATUT':
        return Icons.sync_rounded;
      case 'ATTRIBUTION_SIGNALEMENT':
        return Icons.assignment_turned_in_outlined;
      case 'NOUVELLE_ACTUALITE':
        return Icons.campaign_outlined;
      case 'NOUVEAU_CONTENU_EDUCATIF':
        return Icons.school_outlined;
      case 'NOUVEAU_SIGNALEMENT':
        return Icons.add_alert_rounded;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String get _typeLabel {
    switch (notification.type) {
      case 'ALERTE_URGENTE':
        return 'Urgent';
      case 'CHANGEMENT_STATUT':
        return 'Mise à jour';
      case 'ATTRIBUTION_SIGNALEMENT':
        return 'Attribution';
      case 'NOUVELLE_ACTUALITE':
        return 'Actualité';
      case 'NOUVEAU_CONTENU_EDUCATIF':
        return 'Éducation';
      case 'NOUVEAU_SIGNALEMENT':
        return 'Signalement';
      default:
        return 'Notification';
    }
  }

  String _formaterDate(DateTime? date) {
    if (date == null) return 'Date inconnue';

    final local = date.toLocal();
    final maintenant = DateTime.now();
    final difference = maintenant.difference(local);

    if (difference.inSeconds >= 0 && difference.inMinutes < 1) {
      return 'À l’instant';
    }
    if (difference.inMinutes >= 1 && difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inHours >= 1 && difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }
    if (difference.inDays == 1) return 'Hier';

    String deuxChiffres(int n) => n.toString().padLeft(2, '0');

    return '${deuxChiffres(local.day)}/${deuxChiffres(local.month)}/${local.year} '
        '${deuxChiffres(local.hour)}:${deuxChiffres(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: notification.estLue ? Colors.white : const Color(0xFFF8FBFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: notification.estLue
                ? const Color(0xFFE2E8F0)
                : const Color(0xFFBFDBFE),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Miniature cohérente avec le type réel de notification
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 70,
                height: 70,
                color: color.withValues(alpha: 0.10),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(_typeIcon, color: color, size: 32),
                    if (!notification.estLue)
                      Positioned(
                        top: 7,
                        right: 7,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2563EB),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.titre,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: notification.estLue
                                ? FontWeight.w500
                                : FontWeight.w700,
                            color: AppColors.darkBlue,
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _typeLabel,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  Text(
                    notification.message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 9),

                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _formaterDate(notification.dateCreation),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10.5,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
