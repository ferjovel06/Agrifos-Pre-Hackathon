import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_flutter/domain/entities/app_user.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthRepository {
  final SupabaseClient _client = Supabase.instance.client;

  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
      role: user.userMetadata?['role'] as String?,
    );
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'farmer',
  }) async {
    try {
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'role': role},
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('No se pudo completar el registro: $e');
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthApiException catch (e) {
      throw AuthException(_mapErrorMessage(e.message));
    } catch (e) {
      throw AuthException('No se pudo iniciar sesión: $e');
    }
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> updateNameMetadata(String name) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(data: {'name': name.trim()}),
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('No se pudo actualizar el perfil: $e');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String _mapErrorMessage(String raw) {
    if (raw.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}
