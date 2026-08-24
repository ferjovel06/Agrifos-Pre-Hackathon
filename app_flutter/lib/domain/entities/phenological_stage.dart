class PhenologicalStageTemplate {
  final String id;
  final String cropId;
  final String name;
  final int stageOrder;

  const PhenologicalStageTemplate({
    required this.id,
    required this.cropId,
    required this.name,
    required this.stageOrder,
  });

  factory PhenologicalStageTemplate.fromJson(Map<String, dynamic> json) {
    return PhenologicalStageTemplate(
      id: json['id'] as String,
      cropId: json['crop_id'] as String,
      name: json['name'] as String,
      stageOrder: json['stage_order'] as int,
    );
  }
}

class PhenologicalStageInstance {
  final String id;
  final String parcelId;
  final String templateId;
  final String name;
  final int stageOrder;
  final DateTime? actualDate;

  const PhenologicalStageInstance({
    required this.id,
    required this.parcelId,
    required this.templateId,
    required this.name,
    required this.stageOrder,
    required this.actualDate,
  });

  factory PhenologicalStageInstance.fromJson(Map<String, dynamic> json) {
    final actualDate = json['actual_date'] as String?;
    return PhenologicalStageInstance(
      id: json['id'] as String,
      parcelId: json['parcel_id'] as String,
      templateId: json['template_id'] as String,
      name: json['name'] as String,
      stageOrder: json['stage_order'] as int,
      actualDate: actualDate == null ? null : DateTime.parse(actualDate),
    );
  }
}
