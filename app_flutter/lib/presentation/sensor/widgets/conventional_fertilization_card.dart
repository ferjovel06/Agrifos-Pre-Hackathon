import 'package:flutter/material.dart';

import '../../../domain/entities/fertilization_recommendation.dart';

class ConventionalFertilizationCard extends StatelessWidget {
  const ConventionalFertilizationCard({
    super.key,
    required this.scenario,
    this.isLoading = false,
    this.emptyMessage =
        'Captura una muestra para generar las fuentes y dosis.',
  });

  final FertilizerScenario? scenario;
  final bool isLoading;
  final String emptyMessage;

  static const _brown = Color(0xFF472319);
  static const _blue = Color(0xFF448AFF);
  static const _muted = Color(0xFFC1B5B0);

  @override
  Widget build(BuildContext context) {
    final currentScenario = scenario;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: _blue, size: 23),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Convencional',
                  style: TextStyle(
                    color: _brown,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7DBFF)),
                ),
                child: const Text(
                  'QUÍMICA',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (currentScenario == null)
            _UnavailableState(message: emptyMessage)
          else ...[
            _NutrientRow(
              label: 'FUENTE DE NITRÓGENO',
              product: currentScenario.sourceFor('N'),
            ),
            const Divider(height: 28, color: Color(0xFFEDE8E5)),
            _NutrientRow(
              label: 'FUENTE DE FÓSFORO',
              product: currentScenario.sourceFor('P2O5'),
            ),
            const Divider(height: 28, color: Color(0xFFEDE8E5)),
            _NutrientRow(
              label: 'FUENTE DE POTASIO',
              product: currentScenario.sourceFor('K2O'),
            ),
          ],
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({required this.label, required this.product});

  final String label;
  final FertilizerProductDose? product;

  @override
  Widget build(BuildContext context) {
    final dose = product;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: ConventionalFertilizationCard._muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.35,
          ),
        ),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dose?.displayName ?? 'No requerida',
                    style: const TextStyle(
                      color: ConventionalFertilizationCard._brown,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (dose != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${dose.gramsPerPlant.toStringAsFixed(2)} g/planta',
                      style: const TextStyle(
                        color: ConventionalFertilizationCard._muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text.rich(
              TextSpan(
                text: dose == null ? '0.0' : dose.kgPerHectare.toStringAsFixed(1),
                children: const [
                  TextSpan(
                    text: ' kg/ha',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
              style: const TextStyle(
                color: ConventionalFertilizationCard._blue,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, color: Color(0xFFD78A22), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: ConventionalFertilizationCard._brown,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
