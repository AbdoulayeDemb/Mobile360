import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/agent_notification.dart';
import '../providers/agent_notification_provider.dart';
import '../widgets/agent_page_header.dart';

class AgentNotificationsScreen extends ConsumerWidget {
  const AgentNotificationsScreen({super.key});

  Future<void> _actualiser(WidgetRef ref) async {
    ref.invalidate(agentNotificationsProvider);
    await ref.read(agentNotificationsProvider.future);
  }

  Future<void> _ouvrirNotification(
    BuildContext context,
    WidgetRef ref,
    AgentNotification notification,
  ) async {
    if (!notification.estLue) {
      try {
        await ref
            .read(agentNotificationRepositoryProvider)
            .marquerCommeLue(notification.idNotification);
        ref.invalidate(agentNotificationsProvider);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de mettre à jour : $error')),
        );
        return;
      }
    }

    if (notification.referenceType == 'SIGNALEMENT' &&
        notification.referenceId != null &&
        context.mounted) {
      context.push('/agent/missions/${notification.referenceId}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(agentNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Column(
          children: [
            AgentPageHeader(
              titre: 'Mes notifications',
              sousTitre: 'Décisions de votre responsable sur vos preuves',
              onBack: () => context.go('/agent/home'),
            ),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryBlue,
                  ),
                ),
                error: (error, _) => _EtatNotifications(
                  icone: Icons.cloud_off_rounded,
                  titre: 'Notifications indisponibles',
                  message: error.toString(),
                  action: () => _actualiser(ref),
                ),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const _EtatNotifications(
                      icone: Icons.notifications_none_rounded,
                      titre: 'Aucune notification',
                      message:
                          'Les décisions de votre responsable sur vos preuves '
                          'apparaîtront ici.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => _actualiser(ref),
                    color: AppColors.primaryBlue,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _CarteNotification(
                          notification: notification,
                          onTap: () =>
                              _ouvrirNotification(context, ref, notification),
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
}

class _CarteNotification extends StatelessWidget {
  final AgentNotification notification;
  final VoidCallback onTap;

  const _CarteNotification({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final estValidee = notification.type == 'PREUVE_VALIDEE';
    final couleur = estValidee
        ? const Color(0xFF15803D)
        : const Color(0xFFDC2626);
    final fond = estValidee ? const Color(0xFFEAFBF0) : const Color(0xFFFEF2F2);

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: notification.estLue
              ? const Color(0xFFE2E8F0)
              : AppColors.primaryBlue.withValues(alpha: 0.35),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: fond,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  estValidee ? Icons.task_alt_rounded : Icons.cancel_outlined,
                  color: couleur,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.titre,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!notification.estLue)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _dateLisible(notification.dateCreation),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11,
                      ),
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

  String _dateLisible(DateTime? date) {
    if (date == null) return 'Date non disponible';
    final local = date.toLocal();
    final jour = local.day.toString().padLeft(2, '0');
    final mois = local.month.toString().padLeft(2, '0');
    final heure = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$jour/$mois/${local.year} à $heure:$minute';
  }
}

class _EtatNotifications extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String message;
  final VoidCallback? action;

  const _EtatNotifications({
    required this.icone,
    required this.titre,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, color: AppColors.primaryBlue, size: 52),
            const SizedBox(height: 16),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: action,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
