import 'package:flutter/material.dart';

import '../../../domain/entities/lab_analysis.dart';

class LabAnalysisCard extends StatelessWidget {
  const LabAnalysisCard({
    super.key,
    required this.analyses,
    required this.isLoading,
    required this.onManage,
    this.errorMessage,
  });

  final List<LabAnalysis> analyses;
  final bool isLoading;
  final VoidCallback onManage;
  final String? errorMessage;

  static const _brown = Color(0xFF472319);
  static const _green = Color(0xFF31543B);
  static const _muted = Color(0xFFA99B96);

  @override
  Widget build(BuildContext context) {
    final latest = analyses.isEmpty ? null : analyses.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.science_outlined, color: _green, size: 20),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Análisis de laboratorio',
                  style: TextStyle(
                    color: _brown,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onManage,
                icon: Icon(analyses.isEmpty ? Icons.add : Icons.tune, size: 17),
                label: Text(analyses.isEmpty ? 'Registrar' : 'Gestionar'),
              ),
            ],
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMessage != null)
            _Message(icon: Icons.error_outline, text: errorMessage!)
          else if (latest == null)
            const _Message(
              icon: Icons.info_outline,
              text:
                  'Registra los resultados del laboratorio para esta parcela.',
            )
          else ...[
            const Divider(height: 22, color: Color(0xFFEDE8E5)),
            Row(
              children: [
                Expanded(
                  child: _Value(
                    label: 'ÚLTIMA MUESTRA',
                    value: latest.sampleCode ?? 'Sin código',
                  ),
                ),
                Expanded(
                  child: _Value(
                    label: 'PH',
                    value: latest.ph.toStringAsFixed(1),
                  ),
                ),
                Expanded(
                  child: _Value(
                    label: 'REGISTROS',
                    value: '${analyses.length}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: const Color(0xFFD78A22), size: 19),
      const SizedBox(width: 9),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: LabAnalysisCard._brown,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ),
    ],
  );
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: LabAnalysisCard._muted,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: LabAnalysisCard._green,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
