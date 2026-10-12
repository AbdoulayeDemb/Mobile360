import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/auth_response.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthResponse?>(AuthController.new);

class AuthController extends AsyncNotifier<AuthResponse?> {
  @override
  Future<AuthResponse?> build() async {
    return null;
  }

  Future<void> login({
    required String telephone,
    required String motDePasse,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      return ref
          .read(authRepositoryProvider)
          .login(telephone: telephone, motDePasse: motDePasse);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}
