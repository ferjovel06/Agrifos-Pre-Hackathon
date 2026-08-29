import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';

class MfaChallengeScreen extends StatefulWidget {
  const MfaChallengeScreen({super.key});

  @override
  State<MfaChallengeScreen> createState() => _MfaChallengeScreenState();
}

class _MfaChallengeScreenState extends State<MfaChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AuthProvider>().verifyMfa(_codeController.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundColor: Color(0xFFEAF2EC),
                          child: Icon(
                            Icons.security_rounded,
                            color: Color(0xFF2E5B3D),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Verificación en dos pasos',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF4B251B),
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Ingresa el código de 6 dígitos de tu aplicación autenticadora.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7B6962),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _codeController,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Código de seguridad',
                            hintText: '000000',
                            counterText: '',
                            prefixIcon: Icon(Icons.password_rounded),
                          ),
                          validator: (value) => value?.length == 6
                              ? null
                              : 'Ingresa los 6 dígitos.',
                          onFieldSubmitted: (_) =>
                              auth.isVerifyingMfa ? null : _verify(),
                        ),
                        if (auth.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            auth.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFF9B3D35)),
                          ),
                        ],
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: auth.isVerifyingMfa ? null : _verify,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E5B3D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: auth.isVerifyingMfa
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Verificar'),
                          ),
                        ),
                        TextButton(
                          onPressed: auth.isVerifyingMfa
                              ? null
                              : () => auth.signOut(),
                          child: const Text('Usar otra cuenta'),
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
}
