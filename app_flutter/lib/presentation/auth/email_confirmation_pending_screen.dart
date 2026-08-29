import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class EmailConfirmationPendingScreen extends StatefulWidget {
  const EmailConfirmationPendingScreen({super.key});

  @override
  State<EmailConfirmationPendingScreen> createState() =>
      _EmailConfirmationPendingScreenState();
}

class _EmailConfirmationPendingScreenState
    extends State<EmailConfirmationPendingScreen> {
  static const _cooldownSeconds = 60;

  String? _feedback;
  Timer? _cooldownTimer;
  int _secondsRemaining = _cooldownSeconds;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _secondsRemaining = _cooldownSeconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsRemaining--);
      if (_secondsRemaining <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    final email = auth.pendingConfirmationEmail;
    if (email == null) return;
    final sent = await auth.resendEmailConfirmation(email);
    if (!mounted) return;
    if (sent) _startCooldown();
    setState(() {
      _feedback = sent
          ? 'Correo de confirmación reenviado.'
          : auth.errorMessage ?? 'No se pudo reenviar el correo.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final email = auth.pendingConfirmationEmail ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2EC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Color(0xFFEAF2EC),
                        child: Icon(
                          Icons.mark_email_unread_outlined,
                          color: Color(0xFF2E5B3D),
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Confirma tu correo',
                        style: TextStyle(
                          color: Color(0xFF4B251B),
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Enviamos un enlace de confirmación a\n$email',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7B6962),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Abre el enlace desde este dispositivo para continuar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFF7B6962)),
                      ),
                      if (_feedback != null) ...[
                        const SizedBox(height: 14),
                        Text(
                          _feedback!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: auth.errorMessage == null
                                ? const Color(0xFF2E5B3D)
                                : const Color(0xFF9B3D35),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              auth.isResendingConfirmation ||
                                  _secondsRemaining > 0
                              ? null
                              : _resend,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2E5B3D),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: auth.isResendingConfirmation
                              ? const SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _secondsRemaining > 0
                                      ? 'Reenviar en $_secondsRemaining s'
                                      : 'Reenviar correo',
                                ),
                        ),
                      ),
                      TextButton(
                        onPressed: auth.leaveEmailConfirmation,
                        child: const Text('Volver a iniciar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
