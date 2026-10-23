import '../../../signalements/data/models/signalement.dart';
import 'preuve_resolution.dart';

/// Avancement d'une mission du point de vue de l'agent de terrain.
enum EtatMission { aTraiter, enCours, enAttenteValidation, resolue, rejetee }

/// Signalement assigné à l'agent, accompagné de son éventuelle preuve.
class Mission {
  final Signalement signalement;
  final PreuveResolution? preuve;

  const Mission({required this.signalement, this.preuve});

  int get id => signalement.idSignalement;

  String get code {
    final code = signalement.codeTrackingUnique?.trim();
    return code != null && code.isNotEmpty
        ? code
        : '#${signalement.idSignalement}';
  }

  String get titre {
    final categorie = signalement.categorieNom?.trim();
    return categorie != null && categorie.isNotEmpty ? categorie : 'Mission';
  }

  String get lieu {
    final repere = signalement.repereVisuel?.trim();
    return repere != null && repere.isNotEmpty
        ? repere
        : 'Localisation GPS du signalement';
  }

  bool get aPositionGps =>
      signalement.latitudeGPS != null && signalement.longitudeGPS != null;

  String get _statut => signalement.statut.trim().toUpperCase();

  String get _urgence => signalement.typeUrgence.trim().toUpperCase();

  bool get estUrgente => _urgence == 'CRITIQUE' || _urgence == 'ELEVEE';

  bool get estTerminee =>
      etat == EtatMission.resolue || etat == EtatMission.rejetee;

  EtatMission get etat {
    if (_statut == 'RESOLU') return EtatMission.resolue;
    if (_statut == 'REJETE') return EtatMission.rejetee;

    final preuve = this.preuve;

    if (preuve != null) {
      return preuve.statutPropose == StatutPropose.enCours
          ? EtatMission.enCours
          : EtatMission.enAttenteValidation;
    }

    if (_statut == 'EN_COURS') return EtatMission.enCours;

    return EtatMission.aTraiter;
  }

  /// Ordre de priorité : critique d'abord, puis le plus ancien.
  int get rangUrgence {
    switch (_urgence) {
      case 'CRITIQUE':
        return 0;
      case 'ELEVEE':
        return 1;
      case 'MOYENNE':
        return 2;
      default:
        return 3;
    }
  }
}
