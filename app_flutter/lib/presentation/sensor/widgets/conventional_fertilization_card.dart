import 'package:flutter/material.dart';

import '../../../domain/entities/fertilization_recommendation.dart';

class ConventionalFertilizationCard extends StatelessWidget {
  const ConventionalFertilizationCard({
    super.key,
    required this.scenario,
    this.application,
    this.isLoading = false,
    this.onViewDetails,
    this.emptyMessage = 'Captura una muestra para generar las fuentes y dosis.',
  });

  final FertilizerScenario? scenario;
  final FertilizerApplication? application;
  final bool isLoading;
  final VoidCallback? onViewDetails;
  final String emptyMessage;

  static const _brown = Color(0xFF472319);
  static const _blue = Color(0xFF448AFF);
  static const _muted = Color(0xFFC1B5B0);

  @override
  Widget build(BuildContext context) {
    final currentScenario = scenario;
    final currentApplication = application;
    final hasRecommendation =
        currentApplication != null || currentScenario != null;
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
          else if (!hasRecommendation)
            _UnavailableState(message: emptyMessage)
          else ...[
            if (currentApplication != null) ...[
              _ApplicationLabel(application: currentApplication),
              const SizedBox(height: 18),
            ],
            _NutrientRow(
              label: 'FUENTE DE NITRÓGENO',
              product:
                  currentApplication?.sourceFor('N') ??
                  currentScenario?.sourceFor('N'),
            ),
            const Divider(height: 28, color: Color(0xFFEDE8E5)),
            _NutrientRow(
              label: 'FUENTE DE FÓSFORO',
              product:
                  currentApplication?.sourceFor('P2O5') ??
                  currentScenario?.sourceFor('P2O5'),
            ),
            const Divider(height: 28, color: Color(0xFFEDE8E5)),
            _NutrientRow(
              label: 'FUENTE DE POTASIO',
              product:
                  currentApplication?.sourceFor('K2O') ??
                  currentScenario?.sourceFor('K2O'),
            ),
            if (onViewDetails != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.description_outlined),
                label: const Text('Ver plan completo'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ApplicationLabel extends StatelessWidget {
  const _ApplicationLabel({required this.application});

  final FertilizerApplication application;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: Color(0xFF2F6842),
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Próxima aplicación: ${application.moment}',
              style: const TextStyle(
                color: Color(0xFF2F6842),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${(application.fraction * 100).toStringAsFixed(0)} %',
            style: const TextStyle(
              color: Color(0xFF2F6842),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
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
                text: dose == null
                    ? '0.0'
                    : dose.kgPerHectare.toStringAsFixed(1),
                children: const [
                  TextSpan(text: ' kg/ha', style: TextStyle(fontSize: 13)),
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
