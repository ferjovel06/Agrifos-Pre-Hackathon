import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:app_flutter/data/api/auth_repository.dart';
import 'package:app_flutter/domain/entities/app_user.dart';
import 'package:app_flutter/domain/entities/mfa_enrollment.dart';

enum AuthStatus {
  idle,
  loading,
  emailConfirmationPending,
  passwordRecovery,
  mfaEnrollmentOffered,
  mfaRequired,
  authenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;
  late final StreamSubscription<AuthState> _authSubscription;

  AuthProvider(this._repository) {
    _authSubscription = _repository.authStateChanges.listen(_handleAuthState);
    _refreshAuthState();
  }

  AuthStatus status = AuthStatus.idle;
  AppUser? user;
  String? errorMessage;
  bool isUpdatingProfile = false;
  bool isVerifyingMfa = false;
  bool isUpdatingMfa = false;
  bool isUpdatingPassword = false;
  bool isSendingPasswordReset = false;
  bool isResendingConfirmation = false;
  bool? mfaEnabled;
  bool emailConfirmationRequired = false;
  String? pendingConfirmationEmail;
  bool _offerMfaEnrollment = false;
  bool _passwordRecoveryActive = false;

  void _handleAuthState(AuthState authState) {
    if (authState.event == AuthChangeEvent.passwordRecovery) {
      _passwordRecoveryActive = true;
    } else if (authState.event == AuthChangeEvent.signedIn) {
      emailConfirmationRequired = false;
      pendingConfirmationEmail = null;
      _offerMfaEnrollment = true;
    }
    _refreshAuthState();
  }

  Future<void> _refreshAuthState() async {
    user = _repository.currentUser;
    if (user == null) {
      status = AuthStatus.idle;
      mfaEnabled = null;
    } else if (_passwordRecoveryActive) {
      status = AuthStatus.passwordRecovery;
    } else {
      if (_repository.requiresMfaVerification) {
        status = AuthStatus.mfaRequired;
      } else if (_offerMfaEnrollment && !_repository.hasVerifiedMfaFactor) {
        status = AuthStatus.mfaEnrollmentOffered;
      } else {
        status = AuthStatus.authenticated;
      }
    }
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
      emailConfirmationRequired = await _repository.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      if (emailConfirmationRequired) {
        pendingConfirmationEmail = email.trim();
        status = AuthStatus.emailConfirmationPending;
        notifyListeners();
        return true;
      }
      _offerMfaEnrollment = true;
      await _refreshAuthState();
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
      _offerMfaEnrollment = true;
      await _refreshAuthState();
      return true;
    } catch (e) {
      status = AuthStatus.error;
      errorMessage = e is AuthException ? e.message : 'Error inesperado.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyMfa(String code) async {
    isVerifyingMfa = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.verifyMfa(code);
      await _refreshAuthState();
      return true;
    } catch (e) {
      status = AuthStatus.mfaRequired;
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo verificar el código.';
      notifyListeners();
      return false;
    } finally {
      isVerifyingMfa = false;
      notifyListeners();
    }
  }

  Future<void> loadMfaStatus() async {
    try {
      mfaEnabled = await _repository.hasMfaEnabled();
    } catch (_) {
      mfaEnabled = null;
    }
    notifyListeners();
  }

  Future<MfaEnrollment?> beginMfaEnrollment() async {
    isUpdatingMfa = true;
    errorMessage = null;
    notifyListeners();
    try {
      return await _repository.beginMfaEnrollment();
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo configurar la verificación en dos pasos.';
      return null;
    } finally {
      isUpdatingMfa = false;
      notifyListeners();
    }
  }

  Future<bool> confirmMfaEnrollment({
    required String factorId,
    required String code,
  }) async {
    isUpdatingMfa = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.confirmMfaEnrollment(factorId: factorId, code: code);
      _offerMfaEnrollment = false;
      mfaEnabled = true;
      await _refreshAuthState();
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo activar la verificación en dos pasos.';
      notifyListeners();
      return false;
    } finally {
      isUpdatingMfa = false;
      notifyListeners();
    }
  }

  Future<void> cancelMfaEnrollment(String factorId) =>
      _repository.cancelMfaEnrollment(factorId);

  Future<void> skipMfaEnrollment() async {
    _offerMfaEnrollment = false;
    await _refreshAuthState();
  }

  Future<bool> disableMfa() async {
    isUpdatingMfa = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.disableMfa();
      mfaEnabled = false;
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo desactivar la verificación en dos pasos.';
      notifyListeners();
      return false;
    } finally {
      isUpdatingMfa = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    isSendingPasswordReset = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.sendPasswordReset(email);
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo enviar el enlace de recuperación.';
      notifyListeners();
      return false;
    } finally {
      isSendingPasswordReset = false;
      notifyListeners();
    }
  }

  Future<bool> resendEmailConfirmation(String email) async {
    isResendingConfirmation = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.resendEmailConfirmation(email);
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo reenviar la confirmación.';
      notifyListeners();
      return false;
    } finally {
      isResendingConfirmation = false;
      notifyListeners();
    }
  }

  void leaveEmailConfirmation() {
    emailConfirmationRequired = false;
    pendingConfirmationEmail = null;
    status = AuthStatus.idle;
    notifyListeners();
  }

  Future<bool> updateRecoveredPassword(String password) async {
    isUpdatingPassword = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.updatePassword(newPassword: password);
      _passwordRecoveryActive = false;
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo actualizar la contraseña.';
      notifyListeners();
      return false;
    } finally {
      isUpdatingPassword = false;
      notifyListeners();
    }
  }

  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    isUpdatingPassword = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo actualizar la contraseña.';
      notifyListeners();
      return false;
    } finally {
      isUpdatingPassword = false;
      notifyListeners();
    }
  }

  Future<void> completePasswordRecoveryFlow() => _refreshAuthState();

  Future<bool> updateNameMetadata(String name) async {
    isUpdatingProfile = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateNameMetadata(name);
      await _refreshAuthState();
      return true;
    } catch (e) {
      errorMessage = e is AuthException
          ? e.message
          : 'No se pudo actualizar el perfil.';
      return false;
    } finally {
      isUpdatingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _offerMfaEnrollment = false;
    _passwordRecoveryActive = false;
    emailConfirmationRequired = false;
    pendingConfirmationEmail = null;
    await _repository.signOut();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }
}
