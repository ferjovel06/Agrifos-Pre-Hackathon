import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _completed = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await context.read<AuthProvider>().updateRecoveredPassword(
      _passwordController.text,
    );
    if (success && mounted) setState(() => _completed = true);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return PopScope(
      canPop: false,
      child: Scaffold(
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
                    child: _completed
                        ? _SuccessContent(
                            onContinue: auth.completePasswordRecoveryFlow,
                          )
                        : Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircleAvatar(
                                  radius: 28,
                                  backgroundColor: Color(0xFFEAF2EC),
                                  child: Icon(
                                    Icons.lock_reset_rounded,
                                    color: Color(0xFF2E5B3D),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Nueva contraseña',
                                  style: TextStyle(
                                    color: Color(0xFF4B251B),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Crea una contraseña segura para recuperar el acceso a tu cuenta.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF7B6962),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText: 'Nueva contraseña',
                                    prefixIcon: const Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: _confirmController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  decoration: const InputDecoration(
                                    labelText: 'Confirmar contraseña',
                                    prefixIcon: Icon(Icons.lock_outline),
                                  ),
                                  validator: (value) =>
                                      value == _passwordController.text
                                      ? null
                                      : 'Las contraseñas no coinciden.',
                                  onFieldSubmitted: (_) =>
                                      auth.isUpdatingPassword
                                      ? null
                                      : _submit(),
                                ),
                                if (auth.errorMessage != null) ...[
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
                                SizedBox(
                                  width: double.infinity,
                                  child: FilledButton(
                                    onPressed: auth.isUpdatingPassword
                                        ? null
                                        : _submit,
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E5B3D),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 14,
                                      ),
                                    ),
                                    child: auth.isUpdatingPassword
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Guardar contraseña'),
                                  ),
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
      ),
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return 'Usa al menos 8 caracteres.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Incluye mayúscula, minúscula y número.';
    }
    return null;
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircleAvatar(
        radius: 28,
        backgroundColor: Color(0xFFEAF2EC),
        child: Icon(Icons.check_rounded, color: Color(0xFF2E5B3D), size: 32),
      ),
      const SizedBox(height: 16),
      const Text(
        'Contraseña actualizada',
        style: TextStyle(
          color: Color(0xFF4B251B),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Ya puedes continuar de forma segura.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF7B6962)),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onContinue,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E5B3D),
          ),
          child: const Text('Continuar'),
        ),
      ),
    ],
  );
}
