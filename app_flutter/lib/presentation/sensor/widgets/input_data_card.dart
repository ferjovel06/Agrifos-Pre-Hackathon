import 'package:flutter/material.dart';

class InputDataCard extends StatelessWidget {
  const InputDataCard({
    super.key,
    required this.parcelName,
    required this.cropName,
    required this.varietyName,
    required this.stageName,
    required this.ageMonths,
    required this.plantsPerHectare,
  });

  final String parcelName;
  final String cropName;
  final String varietyName;
  final String stageName;
  final int ageMonths;
  final int? plantsPerHectare;

  static const _titleColor = Color(0xFF472319);
  static const _brandGreen = Color(0xFF31543B);
  static const _fieldBackground = Color(0xFFFAF6F3);

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.eco_outlined, size: 20, color: _brandGreen),
              const SizedBox(width: 9),
              const Expanded(
                child: Text(
                  'Datos de entrada',
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  parcelName,
                  style: const TextStyle(
                    color: _brandGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DataField(label: 'CULTIVO PRINCIPAL', value: cropName),
          const SizedBox(height: 14),
          _DataField(label: 'VARIEDAD GENÉTICA', value: varietyName),
          const SizedBox(height: 14),
          _DataField(label: 'ETAPA FENOLÓGICA', value: stageName),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DataField(label: 'EDAD (MESES)', value: '$ageMonths'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DataField(
                  label: 'DENSIDAD (PL/HA)',
                  value: plantsPerHectare?.toString() ?? 'Sin especificar',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataField extends StatelessWidget {
  const _DataField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            color: InputDataCard._fieldBackground,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: const Color(0xFFE8DDD7)),
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: InputDataCard._titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
