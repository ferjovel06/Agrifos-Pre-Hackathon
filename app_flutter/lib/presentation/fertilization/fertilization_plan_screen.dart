import 'package:flutter/material.dart';

import '../../domain/entities/fertilization_recommendation.dart';

class FertilizationPlanScreen extends StatefulWidget {
  const FertilizationPlanScreen({super.key, required this.recommendation});

  final FertilizationRecommendation recommendation;

  @override
  State<FertilizationPlanScreen> createState() =>
      _FertilizationPlanScreenState();
}

class _FertilizationPlanScreenState extends State<FertilizationPlanScreen>
    with SingleTickerProviderStateMixin {
  static const _background = Color(0xFFF8F3EE);
  static const _brown = Color(0xFF472319);
  static const _green = Color(0xFF315C3A);
  static const _softGreen = Color(0xFFEAF2EB);
  static const _muted = Color(0xFF817570);

  late final TabController _tabs;
  int _scenarioIndex = 0;

  FertilizationRecommendation get recommendation => widget.recommendation;
  FertilizerScenario get scenario => recommendation.scenarios[_scenarioIndex];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _brown,
        elevation: 0,
        title: const Text(
          'Plan de fertilización',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (recommendation.scenarios.length > 1) _buildScenarioSelector(),
          Material(
            color: Colors.white,
            child: TabBar(
              controller: _tabs,
              labelColor: _green,
              unselectedLabelColor: _muted,
              indicatorColor: _green,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Resumen'),
                Tab(text: 'Aplicaciones'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [_buildSummaryTab(), _buildScheduleTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final target = recommendation.targetGreenKgHa > 0
        ? '${_number(recommendation.targetGreenKgHa)} kg verde/ha'
        : 'Plan de etapa joven';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${recommendation.crop} · ${recommendation.variety}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _brown,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderPill(
                icon: Icons.eco_outlined,
                label: _lifeStageLabel(recommendation.lifeStage),
              ),
              _HeaderPill(
                icon: Icons.calendar_today_outlined,
                label: '${recommendation.plantAgeMonths} meses',
              ),
              _HeaderPill(icon: Icons.trending_up, label: target),
            ],
          ),
          if (recommendation.sourceType != null) ...[
            const SizedBox(height: 10),
            _SourceLabel(
              sourceType: recommendation.sourceType!,
              recordedAt: recommendation.sourceRecordedAt,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScenarioSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: DropdownButtonFormField<int>(
        initialValue: _scenarioIndex,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Escenario',
          filled: true,
          fillColor: _softGreen,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        items: [
          for (var index = 0; index < recommendation.scenarios.length; index++)
            DropdownMenuItem(
              value: index,
              child: Text(recommendation.scenarios[index].name),
            ),
        ],
        onChanged: (value) {
          if (value != null) setState(() => _scenarioIndex = value);
        },
      ),
    );
  }

  Widget _buildSummaryTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle(
          title: 'Necesidades del cultivo',
          subtitle: 'Kilogramos por hectárea',
        ),
        const SizedBox(height: 10),
        if (recommendation.nutrientRequirements.isEmpty)
          const _EmptyState(message: 'No hay requerimientos calculados.')
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recommendation.nutrientRequirements.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.22,
            ),
            itemBuilder: (_, index) => _NutrientCard(
              requirement: recommendation.nutrientRequirements[index],
            ),
          ),
        const SizedBox(height: 22),
        _SectionTitle(
          title: scenario.name,
          subtitle: scenario.isMathematicallyValid
              ? (recommendation.usesYoungCropSchedule
                    ? 'Totales acumulados del plan hasta el mes 18'
                    : 'Fuentes y dosis totales')
              : 'Requiere revisión técnica',
        ),
        const SizedBox(height: 10),
        if (scenario.products.isEmpty)
          const _EmptyState(message: 'Este escenario no requiere productos.')
        else
          for (final product in scenario.products)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProductCard(product: product),
            ),
        if (recommendation.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NoticeCard(
            title: 'Antes de aplicar',
            items: recommendation.warnings,
            color: const Color(0xFFD48616),
            background: const Color(0xFFFFF5E4),
            icon: Icons.warning_amber_rounded,
          ),
        ],
        if (recommendation.limitingNutrients.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Nutrientes limitantes: '
            '${recommendation.limitingNutrients.join(', ')}',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleTab() {
    final applications = scenario.applicationSchedule;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _SectionTitle(
          title: 'Calendario de aplicación',
          subtitle: 'Dosis fraccionadas según la etapa del cultivo',
        ),
        const SizedBox(height: 14),
        if (applications.isEmpty)
          const _EmptyState(
            message: 'Este plan no tiene aplicaciones programadas.',
          )
        else
          for (var index = 0; index < applications.length; index++)
            _ApplicationStep(
              application: applications[index],
              isLast: index == applications.length - 1,
            ),
      ],
    );
  }
}

class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.sourceType, required this.recordedAt});

  final String sourceType;
  final DateTime? recordedAt;

  @override
  Widget build(BuildContext context) {
    final isLab = sourceType == 'laboratory';
    final date = recordedAt;
    final dateText = date == null
        ? null
        : '${date.day.toString().padLeft(2, '0')}/'
              '${date.month.toString().padLeft(2, '0')}/${date.year}';
    return Row(
      children: [
        Icon(
          isLab ? Icons.biotech_outlined : Icons.sensors_outlined,
          size: 17,
          color: _FertilizationPlanScreenState._green,
        ),
        const SizedBox(width: 7),
        Text(
          isLab ? 'Basado en análisis de laboratorio' : 'Basado en sensor',
          style: const TextStyle(
            color: _FertilizationPlanScreenState._green,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (dateText != null) ...[
          const Text(
            '  ·  ',
            style: TextStyle(color: _FertilizationPlanScreenState._muted),
          ),
          Text(
            dateText,
            style: const TextStyle(
              color: _FertilizationPlanScreenState._muted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _FertilizationPlanScreenState._softGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _FertilizationPlanScreenState._green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: _FertilizationPlanScreenState._green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _FertilizationPlanScreenState._brown,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: _FertilizationPlanScreenState._muted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({required this.requirement});

  final NutrientRequirement requirement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                requirement.nutrient,
                style: const TextStyle(
                  color: _FertilizationPlanScreenState._brown,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              _StatusBadge(status: requirement.soilStatus),
            ],
          ),
          const Spacer(),
          Text(
            _number(requirement.fertilizerRequirementKgHa),
            style: const TextStyle(
              color: _FertilizationPlanScreenState._green,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            'kg/ha a fertilizar',
            style: TextStyle(
              color: _FertilizationPlanScreenState._muted,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Demanda ${_number(requirement.totalDemandKgHa)} · '
            'Suelo ${_number(requirement.soilCreditKgHa)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9A8E88)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'deficient' => const Color(0xFFD48616),
      'high' => const Color(0xFFB9534F),
      _ => _FertilizationPlanScreenState._green,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 92),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _soilStatusLabel(status),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final FertilizerProductDose product;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8E0DA)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _FertilizationPlanScreenState._softGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.grass,
              color: _FertilizationPlanScreenState._green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.displayName,
                  style: const TextStyle(
                    color: _FertilizationPlanScreenState._brown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_number(product.kgPerManzana)} kg/mz · '
                  '${_number(product.gramsPerPlant)} g/planta',
                  style: const TextStyle(
                    color: _FertilizationPlanScreenState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              text: _number(product.kgPerHectare),
              children: const [
                TextSpan(
                  text: '\nkg/ha',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Color(0xFF3478D4),
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationStep extends StatelessWidget {
  const _ApplicationStep({required this.application, required this.isLast});

  final FertilizerApplication application;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: _FertilizationPlanScreenState._green,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${application.number}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: const Color(0xFFD6E3D8)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8E0DA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          application.moment,
                          style: const TextStyle(
                            color: _FertilizationPlanScreenState._brown,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '${(application.fraction * 100).toStringAsFixed(0)} %',
                        style: const TextStyle(
                          color: _FertilizationPlanScreenState._green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final product in application.products)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(product.product)),
                          Text(
                            '${_number(product.kgPerHectare)} kg/ha',
                            style: const TextStyle(
                              color: _FertilizationPlanScreenState._muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.title,
    required this.items,
    required this.color,
    required this.background,
    required this.icon,
  });

  final String title;
  final List<String> items;
  final Color color;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 19),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final item in items) _BulletText(text: item, color: color),
        ],
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  const _BulletText({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: TextStyle(color: color)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, height: 1.35, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _FertilizationPlanScreenState._muted),
      ),
    );
  }
}

String _number(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(2);
}

String _lifeStageLabel(String value) {
  const labels = {
    'nursery': 'Vivero',
    'establishment': 'Establecimiento',
    'vegetative_growth': 'Levante',
    'initial_production': 'Producción inicial',
    'stable_production': 'Producción estable',
  };
  return labels[value] ?? value;
}

String _soilStatusLabel(String value) {
  const labels = {
    'deficient': 'Deficiente',
    'probable_response': 'Respuesta probable',
    'adequate': 'Adecuado',
    'high': 'Alto',
  };
  return labels[value] ?? value;
}
