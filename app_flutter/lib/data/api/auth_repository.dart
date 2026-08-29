import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:app_flutter/core/env.dart';
import 'package:app_flutter/domain/entities/app_user.dart';
import 'package:app_flutter/domain/entities/mfa_enrollment.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
}

class AuthRepository {
  static const authRedirectUrl = 'dev.agrifos.agrifos://auth-callback/';

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

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String role = 'farmer',
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: authRedirectUrl,
        data: {'name': name, 'role': role},
      );
      return response.session == null;
    } on AuthRetryableFetchException {
      throw AuthException(_connectionErrorMessage);
    } on AuthApiException catch (e) {
      throw AuthException(_mapErrorMessage(e.message));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException(
        'No se pudo completar el registro. Intenta de nuevo.',
      );
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on AuthRetryableFetchException {
      throw AuthException(_connectionErrorMessage);
    } on AuthApiException catch (e) {
      throw AuthException(_mapErrorMessage(e.message));
    } catch (_) {
      throw AuthException('No se pudo iniciar sesión. Intenta de nuevo.');
    }
  }

  bool get requiresMfaVerification {
    if (_client.auth.currentSession == null) return false;
    final assurance = _client.auth.mfa.getAuthenticatorAssuranceLevel();
    return assurance.currentLevel == AuthenticatorAssuranceLevels.aal1 &&
        assurance.nextLevel == AuthenticatorAssuranceLevels.aal2;
  }

  bool get hasVerifiedMfaFactor {
    final factors = _client.auth.currentUser?.factors ?? const <Factor>[];
    return factors.any(
      (factor) =>
          factor.factorType == FactorType.totp &&
          factor.status == FactorStatus.verified,
    );
  }

  Future<bool> hasMfaEnabled() async {
    final factors = await _client.auth.mfa.listFactors();
    return factors.totp.isNotEmpty;
  }

  Future<void> verifyMfa(String code) async {
    try {
      final factors = await _client.auth.mfa.listFactors();
      if (factors.totp.isEmpty) {
        throw AuthException(
          'No hay un autenticador configurado para esta cuenta.',
        );
      }
      await _client.auth.mfa.challengeAndVerify(
        factorId: factors.totp.first.id,
        code: code,
      );
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapMfaErrorMessage(e.message));
    } catch (_) {
      throw AuthException('No se pudo verificar el código. Intenta de nuevo.');
    }
  }

  Future<MfaEnrollment> beginMfaEnrollment() async {
    try {
      final existingFactors =
          _client.auth.currentUser?.factors ?? const <Factor>[];
      for (final factor in existingFactors.where(
        (factor) =>
            factor.factorType == FactorType.totp &&
            factor.status == FactorStatus.unverified,
      )) {
        await _client.auth.mfa.unenroll(factor.id);
      }
      final response = await _client.auth.mfa.enroll(
        factorType: FactorType.totp,
        issuer: 'Agrifos',
        friendlyName: 'Agrifos Authenticator',
      );
      final totp = response.totp;
      if (totp == null) {
        throw AuthException('No se pudo preparar el autenticador.');
      }
      return MfaEnrollment(
        factorId: response.id,
        qrCode: totp.qrCode,
        secret: totp.secret,
      );
    } on AuthException {
      rethrow;
    } on AuthApiException catch (e) {
      throw AuthException(_mapMfaErrorMessage(e.message));
    } catch (_) {
      throw AuthException('No se pudo iniciar la configuración de seguridad.');
    }
  }

  Future<void> confirmMfaEnrollment({
    required String factorId,
    required String code,
  }) async {
    try {
      await _client.auth.mfa.challengeAndVerify(factorId: factorId, code: code);
    } on AuthApiException catch (e) {
      throw AuthException(_mapMfaErrorMessage(e.message));
    } catch (_) {
      throw AuthException('No se pudo activar la verificación en dos pasos.');
    }
  }

  Future<void> cancelMfaEnrollment(String factorId) async {
    try {
      await _client.auth.mfa.unenroll(factorId);
    } catch (_) {
      // Cancelling is best-effort because unverified factors can expire.
    }
  }

  Future<void> disableMfa() async {
    try {
      final factors = await _client.auth.mfa.listFactors();
      for (final factor in factors.totp) {
        await _client.auth.mfa.unenroll(factor.id);
      }
    } on AuthApiException catch (e) {
      throw AuthException(_mapMfaErrorMessage(e.message));
    } catch (_) {
      throw AuthException(
        'No se pudo desactivar la verificación en dos pasos.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: authRedirectUrl,
      );
    } on AuthRetryableFetchException {
      throw AuthException(_connectionErrorMessage);
    } on AuthApiException catch (e) {
      throw AuthException(_mapErrorMessage(e.message));
    } catch (_) {
      throw AuthException(
        'No se pudo enviar el enlace de recuperación. Intenta de nuevo.',
      );
    }
  }

  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: authRedirectUrl,
      );
    } on AuthRetryableFetchException {
      throw AuthException(_connectionErrorMessage);
    } on AuthApiException catch (e) {
      throw AuthException(_mapErrorMessage(e.message));
    } catch (_) {
      throw AuthException(
        'No se pudo reenviar la confirmación. Intenta de nuevo.',
      );
    }
  }

  Future<void> updatePassword({
    String? currentPassword,
    required String newPassword,
  }) async {
    try {
      if (currentPassword != null) {
        final email = _client.auth.currentUser?.email;
        if (email == null) {
          throw AuthException('Tu sesión venció. Inicia sesión nuevamente.');
        }
        final response = await http
            .post(
              Uri.parse('${Env.supabaseUrl}/auth/v1/token?grant_type=password'),
              headers: {
                'apikey': Env.supabasePublishableKey,
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'email': email,
                'password': currentPassword,
              }),
            )
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 400 || response.statusCode == 401) {
          throw AuthException('La contraseña actual no es correcta.');
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw AuthException(
            'No se pudo verificar la contraseña actual. Intenta de nuevo.',
          );
        }
      }
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthApiException catch (e) {
      throw AuthException(_mapPasswordErrorMessage(e.message));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw AuthException('No se pudo actualizar la contraseña.');
    }
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

  String _mapMfaErrorMessage(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('invalid') || normalized.contains('expired')) {
      return 'El código no es válido o ya venció.';
    }
    if (normalized.contains('factor') && normalized.contains('exist')) {
      return 'Ya existe un autenticador configurado para esta cuenta.';
    }
    return 'No se pudo completar la verificación. Intenta de nuevo.';
  }

  String _mapPasswordErrorMessage(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('different') || normalized.contains('same')) {
      return 'La nueva contraseña debe ser diferente de la anterior.';
    }
    if (normalized.contains('weak') || normalized.contains('characters')) {
      return 'La contraseña no cumple los requisitos de seguridad.';
    }
    if (normalized.contains('expired')) {
      return 'El enlace venció. Solicita uno nuevo.';
    }
    return 'No se pudo actualizar la contraseña. Intenta de nuevo.';
  }

  String _mapErrorMessage(String raw) {
    final normalized = raw.toLowerCase();
    if (normalized.contains('rate limit') ||
        normalized.contains('rate_limit') ||
        normalized.contains('too many')) {
      return 'Se alcanzó el límite temporal de correos. Revisa tu bandeja '
          'o espera unos minutos antes de intentarlo de nuevo.';
    }
    if (raw.contains('Invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (raw.contains('Email not confirmed')) {
      return 'Confirma tu correo antes de iniciar sesión.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }

  static const _connectionErrorMessage =
      'No pudimos conectar con el servicio de acceso. '
      'Revisa tu conexión, cambia de red o intenta nuevamente.';
}
