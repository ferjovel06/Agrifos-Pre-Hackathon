class PhenologicalStageTemplate {
  final String id;
  final String cropId;
  final String name;
  final int stageOrder;
  final int? durationDays;

  const PhenologicalStageTemplate({
    required this.id,
    required this.cropId,
    required this.name,
    required this.stageOrder,
    required this.durationDays,
  });

  factory PhenologicalStageTemplate.fromJson(Map<String, dynamic> json) {
    return PhenologicalStageTemplate(
      id: json['id'] as String,
      cropId: json['crop_id'] as String,
      name: json['name'] as String,
      stageOrder: json['stage_order'] as int,
      durationDays: (json['duration_days'] as num?)?.toInt(),
    );
  }
}

class PhenologicalStageInstance {
  final String id;
  final String parcelId;
  final String templateId;
  final String name;
  final int stageOrder;
  final int? durationDays;
  final DateTime? estimatedDate;
  final DateTime? actualDate;
  final DateTime? selectedAt;

  const PhenologicalStageInstance({
    required this.id,
    required this.parcelId,
    required this.templateId,
    required this.name,
    required this.stageOrder,
    required this.durationDays,
    required this.estimatedDate,
    required this.actualDate,
    required this.selectedAt,
  });

  factory PhenologicalStageInstance.fromJson(Map<String, dynamic> json) {
    final actualDate = json['actual_date'] as String?;
    final estimatedDate = json['estimated_date'] as String?;
    final selectedAt = json['selected_at'] as String?;
    return PhenologicalStageInstance(
      id: json['id'] as String,
      parcelId: json['parcel_id'] as String,
      templateId: json['template_id'] as String,
      name: json['name'] as String,
      stageOrder: json['stage_order'] as int,
      durationDays: (json['duration_days'] as num?)?.toInt(),
      estimatedDate: estimatedDate == null
          ? null
          : DateTime.parse(estimatedDate),
      actualDate: actualDate == null ? null : DateTime.parse(actualDate),
      selectedAt: selectedAt == null ? null : DateTime.parse(selectedAt),
    );
  }
}
