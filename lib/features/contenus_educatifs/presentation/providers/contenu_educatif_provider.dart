import 'package:alert360_mobile/features/contenus_educatifs/data/repositories/contenu_educatif_repository';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/contenu_educatif.dart';

final contenuEducatifRepositoryProvider = Provider<ContenuEducatifRepository>((
  ref,
) {
  return ContenuEducatifRepository();
});

final contenusEducatifsProvider = FutureProvider<List<ContenuEducatif>>((ref) {
  return ref.watch(contenuEducatifRepositoryProvider).getContenusEducatifs();
});

final contenuEducatifDetailProvider =
    FutureProvider.family<ContenuEducatif, int>((ref, idContenu) {
      return ref
          .watch(contenuEducatifRepositoryProvider)
          .getContenuEducatifById(idContenu);
    });
