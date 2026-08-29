import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/mfa_enrollment.dart';
import 'auth_provider.dart';

class MfaEnrollmentOfferScreen extends StatefulWidget {
  const MfaEnrollmentOfferScreen({super.key});

  @override
  State<MfaEnrollmentOfferScreen> createState() =>
      _MfaEnrollmentOfferScreenState();
}

class _MfaEnrollmentOfferScreenState extends State<MfaEnrollmentOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  MfaEnrollment? _enrollment;
  String? _loadError;
  bool _configuring = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startEnrollment() async {
    setState(() {
      _configuring = true;
      _loadError = null;
      _enrollment = null;
    });
    final auth = context.read<AuthProvider>();
    final enrollment = await auth.beginMfaEnrollment();
    if (!mounted) return;
    setState(() {
      _enrollment = enrollment;
      _loadError = enrollment == null ? auth.errorMessage : null;
    });
  }

  Future<void> _skip() async {
    final auth = context.read<AuthProvider>();
    final enrollment = _enrollment;
    if (enrollment != null) {
      await auth.cancelMfaEnrollment(enrollment.factorId);
    }
    await auth.skipMfaEnrollment();
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate() || _enrollment == null) return;
    await context.read<AuthProvider>().confirmMfaEnrollment(
      factorId: _enrollment!.factorId,
      code: _codeController.text,
    );
  }

  String _svgMarkup(String dataUri) {
    final comma = dataUri.indexOf(',');
    final encoded = comma >= 0 ? dataUri.substring(comma + 1) : dataUri;
    return encoded.trimLeft().startsWith('<svg')
        ? encoded
        : Uri.decodeComponent(encoded);
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
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _configuring
                        ? _buildEnrollment(auth)
                        : _buildOffer(auth),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffer(AuthProvider auth) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const CircleAvatar(
        radius: 28,
        backgroundColor: Color(0xFFEAF2EC),
        child: Icon(Icons.security_rounded, color: Color(0xFF2E5B3D), size: 30),
      ),
      const SizedBox(height: 16),
      const Text(
        'Protege mejor tu cuenta',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFF4B251B),
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Activa la verificación en dos pasos con una aplicación autenticadora. Es opcional y puedes desactivarla después desde Configuración.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF7B6962), height: 1.5),
      ),
      const SizedBox(height: 22),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: auth.isUpdatingMfa ? null : _startEnrollment,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Configurar ahora'),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E5B3D),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
      TextButton(
        onPressed: auth.isUpdatingMfa ? null : _skip,
        child: const Text('Ahora no'),
      ),
    ],
  );

  Widget _buildEnrollment(AuthProvider auth) {
    if (_enrollment == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_loadError == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )
          else ...[
            const Icon(Icons.error_outline, size: 40, color: Color(0xFF9B3D35)),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: auth.isUpdatingMfa ? null : _startEnrollment,
              child: const Text('Reintentar'),
            ),
          ],
          TextButton(
            onPressed: auth.isUpdatingMfa ? null : _skip,
            child: const Text('Ahora no'),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Escanea el código con Google Authenticator, Microsoft Authenticator u otra app compatible.',
            textAlign: TextAlign.center,
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: 190,
            height: 190,
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: SvgPicture.string(_svgMarkup(_enrollment!.qrCode)),
          ),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Ingresar la clave manualmente'),
            children: [
              SelectableText(
                _enrollment!.secret,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                tooltip: 'Copiar clave',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _enrollment!.secret));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Clave copiada.')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Código de verificación',
              hintText: '000000',
              counterText: '',
            ),
            validator: (value) =>
                value?.length == 6 ? null : 'Ingresa los 6 dígitos.',
          ),
          if (auth.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              auth.errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF9B3D35)),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: auth.isUpdatingMfa ? null : _confirm,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E5B3D),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: auth.isUpdatingMfa
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Activar'),
            ),
          ),
          TextButton(
            onPressed: auth.isUpdatingMfa ? null : _skip,
            child: const Text('Ahora no'),
          ),
        ],
      ),
    );
  }
}
