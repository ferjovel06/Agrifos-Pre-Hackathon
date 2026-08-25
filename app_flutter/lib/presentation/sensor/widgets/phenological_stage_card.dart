import 'package:flutter/material.dart';

import '../../../domain/entities/phenological_stage.dart';

class PhenologicalStageCard extends StatelessWidget {
  const PhenologicalStageCard({
    super.key,
    required this.stages,
    required this.currentStageOrder,
  });

  final List<PhenologicalStageTemplate> stages;
  final int? currentStageOrder;

  static const _titleColor = Color(0xFF472319);
  static const _activeGreen = Color(0xFF31543B);
  static const _mutedText = Color(0xFFB7AAA5);
  static const _lineColor = Color(0xFFE8E0DC);

  @override
  Widget build(BuildContext context) {
    final orderedStages = [...stages]
      ..sort((a, b) => a.stageOrder.compareTo(b.stageOrder));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
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
          const Text(
            'Etapa fenológica',
            style: TextStyle(
              color: _titleColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          for (var index = 0; index < orderedStages.length; index++)
            _StageTimelineItem(
              stage: orderedStages[index],
              status: _statusFor(orderedStages[index]),
              timing: _timingFor(orderedStages, index),
              isLast: index == orderedStages.length - 1,
            ),
        ],
      ),
    );
  }

  _StageStatus _statusFor(PhenologicalStageTemplate stage) {
    final currentOrder = currentStageOrder;
    if (currentOrder == null) return _StageStatus.pending;
    if (stage.stageOrder < currentOrder) return _StageStatus.completed;
    if (stage.stageOrder == currentOrder) return _StageStatus.active;
    return _StageStatus.pending;
  }

  String? _timingFor(List<PhenologicalStageTemplate> orderedStages, int index) {
    var startDays = 0;
    for (var previous = 0; previous < index; previous++) {
      final duration = orderedStages[previous].durationDays;
      if (duration == null) {
        return _durationLabel(orderedStages[index].durationDays);
      }
      startDays += duration;
    }

    final duration = orderedStages[index].durationDays;
    if (duration == null) {
      return startDays == 0 ? null : '${_months(startDays)}+ meses';
    }

    final endDays = startDays + duration;
    return '${_months(startDays)} – ${_months(endDays)} meses';
  }

  String? _durationLabel(int? durationDays) {
    if (durationDays == null) return null;
    if (durationDays < 60) return 'Duración estimada: $durationDays días';
    return 'Duración estimada: ${_months(durationDays)} meses';
  }

  int _months(int days) => (days / 30.44).round();
}

enum _StageStatus { completed, active, pending }

class _StageTimelineItem extends StatelessWidget {
  const _StageTimelineItem({
    required this.stage,
    required this.status,
    required this.timing,
    required this.isLast,
  });

  final PhenologicalStageTemplate stage;
  final _StageStatus status;
  final String? timing;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final isActive = status == _StageStatus.active;
    final isCompleted = status == _StageStatus.completed;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 36,
            child: Column(
              children: [
                _StageMarker(status: status),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: PhenologicalStageCard._lineColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          stage.name,
                          style: TextStyle(
                            color: isActive
                                ? PhenologicalStageCard._activeGreen
                                : isCompleted
                                ? const Color(0xFF8E817C)
                                : PhenologicalStageCard._mutedText,
                            fontSize: 14,
                            fontWeight: isActive
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5F1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFC7D6CB)),
                          ),
                          child: const Text(
                            'Activa',
                            style: TextStyle(
                              color: PhenologicalStageCard._activeGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (timing != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      timing!,
                      style: const TextStyle(
                        color: PhenologicalStageCard._mutedText,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageMarker extends StatelessWidget {
  const _StageMarker({required this.status});

  final _StageStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == _StageStatus.active) {
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: PhenologicalStageCard._activeGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.eco_outlined, size: 18, color: Colors.white),
      );
    }

    if (status == _StageStatus.completed) {
      return Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Color(0xFFF1EDEA),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 17, color: Color(0xFFB5AAA5)),
      );
    }

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFDED4CF), width: 1.5),
      ),
    );
  }
}
