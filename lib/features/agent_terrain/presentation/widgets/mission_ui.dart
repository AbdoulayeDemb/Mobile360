import 'package:flutter/material.dart';

import '../../data/models/mission.dart';

/// Couleurs et libellés partagés par les écrans de l'agent.
class MissionUi {
  MissionUi._();

  static const Color bleuAction = Color(0xFF3B82F6);
  static const Color bleuLien = Color(0xFF2563EB);
  static const Color bordure = Color(0xFFE2E8F0);
  static const Color texteGris = Color(0xFF64748B);
  static const Color fondGris = Color(0xFFF1F5F9);

  /// Style d'un badge d'urgence : (libellé, texte, fond, bordure de carte).
  static ({String libelle, Color texte, Color fond, Color bordure}) urgence(
    Mission mission,
  ) {
    switch (mission.signalement.typeUrgence.trim().toUpperCase()) {
      case 'CRITIQUE':
        return (
          libelle: 'CRITIQUE',
          texte: const Color(0xFFB91C1C),
          fond: const Color(0xFFFEE2E2),
          bordure: const Color(0xFFF87171),
        );
      case 'ELEVEE':
        return (
          libelle: 'URGENT',
          texte: const Color(0xFFDC2626),
          fond: const Color(0xFFFEF2F2),
          bordure: const Color(0xFFFCA5A5),
        );
      case 'MOYENNE':
        return (
          libelle: 'MOYENNE',
          texte: const Color(0xFFC2410C),
          fond: const Color(0xFFFFF4E5),
          bordure: const Color(0xFFFDBA8C),
        );
      default:
        return (
          libelle: 'FAIBLE',
          texte: const Color(0xFF16A34A),
          fond: const Color(0xFFEAFBF0),
          bordure: const Color(0xFF9FD8B4),
        );
    }
  }

  static String libelleEtat(EtatMission etat) {
    switch (etat) {
      case EtatMission.aTraiter:
        return 'À traiter';
      case EtatMission.enCours:
        return 'Pris en charge';
      case EtatMission.enAttenteValidation:
        return 'En attente de validation';
      case EtatMission.resolue:
        return 'Résolu';
      case EtatMission.rejetee:
        return 'Rejeté';
    }
  }

  static Color couleurEtat(EtatMission etat) {
    switch (etat) {
      case EtatMission.aTraiter:
        return bleuAction;
      case EtatMission.enCours:
        return const Color(0xFFF59E0B);
      case EtatMission.enAttenteValidation:
        return const Color(0xFF35527E);
      case EtatMission.resolue:
        return const Color(0xFF10B981);
      case EtatMission.rejetee:
        return const Color(0xFFEF4444);
    }
  }

  static String distanceLisible(double metres) {
    if (metres < 1000) return '${metres.round()} m';
    return '${(metres / 1000).toStringAsFixed(1)} km';
  }

  static String heure(DateTime date) {
    final d = date.toLocal();
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  /// "aujourd'hui 08:30", "hier 14:00" ou "12/10/2026 09:15".
  static String dateRelative(DateTime? date) {
    if (date == null) return 'date inconnue';

    final d = date.toLocal();
    final maintenant = DateTime.now();
    final jour = DateTime(d.year, d.month, d.day);
    final aujourdhui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final ecart = aujourdhui.difference(jour).inDays;

    if (ecart == 0) return 'aujourd’hui ${heure(d)}';
    if (ecart == 1) return 'hier ${heure(d)}';

    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year} ${heure(d)}';
  }

  static String initiales(String? prenom, String? nom) {
    final lettres = [prenom, nom]
        .map((valeur) => valeur?.trim() ?? '')
        .where((valeur) => valeur.isNotEmpty)
        .map((valeur) => valeur[0].toUpperCase())
        .join();

    return lettres.isEmpty ? 'AG' : lettres;
  }
}

/// Badge d'urgence arrondi (URGENT, MOYENNE, FAIBLE...).
class BadgeUrgence extends StatelessWidget {
  final Mission mission;

  const BadgeUrgence({super.key, required this.mission});

  @override
  Widget build(BuildContext context) {
    final style = MissionUi.urgence(mission);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: style.fond,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.libelle,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: style.texte,
        ),
      ),
    );
  }
}
