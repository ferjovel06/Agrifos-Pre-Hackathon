import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class PasswordResetRequestScreen extends StatefulWidget {
  const PasswordResetRequestScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<PasswordResetRequestScreen> createState() =>
      _PasswordResetRequestScreenState();
}

class _PasswordResetRequestScreenState
    extends State<PasswordResetRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _sent = false;
  bool _attempted = false;
  bool _closingForRecovery = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send({bool validate = true}) async {
    if (validate && !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _attempted = true);
    final sent = await context.read<AuthProvider>().sendPasswordReset(
      _emailController.text.trim(),
    );
    if (sent && mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.status == AuthStatus.passwordRecovery && !_closingForRecovery) {
      _closingForRecovery = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8F2EC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F2EC),
        foregroundColor: const Color(0xFF4B251B),
        elevation: 0,
        title: const Text('Recuperar contraseña'),
      ),
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
                  child: _sent
                      ? _SentContent(
                          email: _emailController.text.trim(),
                          isSending: auth.isSendingPasswordReset,
                          errorMessage: auth.errorMessage,
                          onResend: () => _send(validate: false),
                          onBack: () => Navigator.of(context).pop(),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: Color(0xFFEAF2EC),
                                child: Icon(
                                  Icons.mark_email_read_outlined,
                                  color: Color(0xFF2E5B3D),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                '¿Olvidaste tu contraseña?',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF4B251B),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Escribe el correo de tu cuenta y te enviaremos un enlace para crear una nueva contraseña.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xFF7B6962),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Correo electrónico',
                                  hintText: 'usuario@finca.com',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: _validateEmail,
                                onFieldSubmitted: (_) =>
                                    auth.isSendingPasswordReset
                                    ? null
                                    : _send(),
                              ),
                              if (_attempted && auth.errorMessage != null) ...[
                                const SizedBox(height: 10),
                                Text(
                                  auth.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFF9B3D35),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: auth.isSendingPasswordReset
                                    ? null
                                    : _send,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E5B3D),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: auth.isSendingPasswordReset
                                    ? const SizedBox.square(
                                        dimension: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Enviar enlace'),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Ingresa tu correo.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Ingresa un correo válido.';
    }
    return null;
  }
}

class _SentContent extends StatelessWidget {
  const _SentContent({
    required this.email,
    required this.isSending,
    required this.errorMessage,
    required this.onResend,
    required this.onBack,
  });

  final String email;
  final bool isSending;
  final String? errorMessage;
  final VoidCallback onResend;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircleAvatar(
        radius: 28,
        backgroundColor: Color(0xFFEAF2EC),
        child: Icon(Icons.outgoing_mail, color: Color(0xFF2E5B3D), size: 30),
      ),
      const SizedBox(height: 16),
      const Text(
        'Revisa tu correo',
        style: TextStyle(
          color: Color(0xFF4B251B),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Si existe una cuenta asociada, enviamos el enlace a\n$email',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFF7B6962), height: 1.4),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onBack,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E5B3D),
          ),
          child: const Text('Volver a iniciar sesión'),
        ),
      ),
      TextButton(
        onPressed: isSending ? null : onResend,
        child: Text(isSending ? 'Enviando…' : 'Reenviar correo'),
      ),
      if (errorMessage != null)
        Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9B3D35)),
        ),
    ],
  );
}
