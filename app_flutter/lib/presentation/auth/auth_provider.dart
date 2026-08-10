import 'package:flutter/foundation.dart';

import 'package:app_flutter/data/api/auth_repository.dart';
import 'package:app_flutter/domain/entities/app_user.dart';

enum AuthStatus { idle, loading, authenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider(this._repository) {
    _repository.authStateChanges.listen((_) {
      _syncUser();
    });
    _syncUser();
  }

  AuthStatus status = AuthStatus.idle;
  AppUser? user;
  String? errorMessage;

  void _syncUser() {
    user = _repository.currentUser;
    status = user != null ? AuthStatus.authenticated : AuthStatus.idle;
    notifyListeners();
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'farmer',
  }) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      return true;
    } catch (e) {
      status = AuthStatus.error;
      errorMessage = e is AuthException ? e.message : 'Error inesperado.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    status = AuthStatus.loading;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.signIn(email: email, password: password);
      return true;
    } catch (e) {
      status = AuthStatus.error;
      errorMessage = e is AuthException ? e.message : 'Error inesperado.';
      notifyListeners();
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _repository.sendPasswordReset(email);

  Future<void> signOut() async {
    await _repository.signOut();
  }
}
