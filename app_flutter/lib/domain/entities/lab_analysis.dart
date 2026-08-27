class LabAnalysis {
  const LabAnalysis({
    required this.id,
    required this.parcelId,
    required this.sampleCode,
    required this.sampledAt,
    required this.depthStartCm,
    required this.depthEndCm,
    required this.lab,
    required this.ph,
    required this.phMethod,
    required this.ec,
    required this.ecMethod,
    required this.organicMatterPct,
    required this.cic,
    required this.clayPct,
    required this.siltPct,
    required this.sandPct,
    required this.nitrogen,
    required this.phosphorus,
    required this.phosphorusMethod,
    required this.potassium,
    required this.potassiumMethod,
    required this.calcium,
    required this.magnesium,
    required this.sulfur,
    required this.recordedAt,
  });

  final String id;
  final String parcelId;
  final String? sampleCode;
  final DateTime? sampledAt;
  final double? depthStartCm;
  final double? depthEndCm;
  final String lab;
  final double ph;
  final String? phMethod;
  final double? ec;
  final String? ecMethod;
  final double organicMatterPct;
  final double cic;
  final double clayPct;
  final double siltPct;
  final double sandPct;
  final double nitrogen;
  final double phosphorus;
  final String? phosphorusMethod;
  final double potassium;
  final String? potassiumMethod;
  final double calcium;
  final double magnesium;
  final double sulfur;
  final DateTime recordedAt;

  factory LabAnalysis.fromJson(Map<String, dynamic> json) => LabAnalysis(
    id: json['id'] as String,
    parcelId: json['parcel_id'] as String,
    sampleCode: json['sample_code'] as String?,
    sampledAt: _date(json['sampled_at']),
    depthStartCm: _number(json['depth_start_cm']),
    depthEndCm: _number(json['depth_end_cm']),
    lab: json['lab'] as String,
    ph: _number(json['ph'])!,
    phMethod: json['ph_method'] as String?,
    ec: _number(json['ec']),
    ecMethod: json['ec_method'] as String?,
    organicMatterPct: _number(json['organic_matter_pct'])!,
    cic: _number(json['cic'])!,
    clayPct: _number(json['clay_pct'])!,
    siltPct: _number(json['silt_pct'])!,
    sandPct: _number(json['sand_pct'])!,
    nitrogen: _number(json['nitrogen'])!,
    phosphorus: _number(json['phosphorus'])!,
    phosphorusMethod: json['phosphorus_method'] as String?,
    potassium: _number(json['potassium'])!,
    potassiumMethod: json['potassium_method'] as String?,
    calcium: _number(json['calcium'])!,
    magnesium: _number(json['magnesium'])!,
    sulfur: _number(json['sulfur'])!,
    recordedAt: DateTime.parse(json['recorded_at'] as String),
  );

  static double? _number(dynamic value) => (value as num?)?.toDouble();
  static DateTime? _date(dynamic value) =>
      value == null ? null : DateTime.parse(value as String);
}

class LabAnalysisInput {
  const LabAnalysisInput({
    required this.sampleCode,
    required this.sampledAt,
    required this.depthStartCm,
    required this.depthEndCm,
    required this.lab,
    required this.ph,
    required this.phMethod,
    required this.ec,
    required this.ecMethod,
    required this.organicMatterPct,
    required this.cic,
    required this.clayPct,
    required this.siltPct,
    required this.sandPct,
    required this.nitrogen,
    required this.phosphorus,
    required this.phosphorusMethod,
    required this.potassium,
    required this.potassiumMethod,
    required this.calcium,
    required this.magnesium,
    required this.sulfur,
  });

  final String sampleCode;
  final DateTime sampledAt;
  final double depthStartCm;
  final double depthEndCm;
  final String lab;
  final double ph;
  final String phMethod;
  final double ec;
  final String ecMethod;
  final double organicMatterPct;
  final double cic;
  final double clayPct;
  final double siltPct;
  final double sandPct;
  final double nitrogen;
  final double phosphorus;
  final String phosphorusMethod;
  final double potassium;
  final String potassiumMethod;
  final double calcium;
  final double magnesium;
  final double sulfur;

  Map<String, dynamic> toJson() => {
    'sample_code': sampleCode,
    'sampled_at': sampledAt.toIso8601String(),
    'depth_start_cm': depthStartCm,
    'depth_end_cm': depthEndCm,
    'lab': lab,
    'ph': ph,
    'ph_method': phMethod,
    'ec': ec,
    'ec_method': ecMethod,
    'organic_matter_pct': organicMatterPct,
    'cic': cic,
    'clay_pct': clayPct,
    'silt_pct': siltPct,
    'sand_pct': sandPct,
    'nitrogen': nitrogen,
    'phosphorus': phosphorus,
    'phosphorus_method': phosphorusMethod,
    'potassium': potassium,
    'potassium_method': potassiumMethod,
    'calcium': calcium,
    'magnesium': magnesium,
    'sulfur': sulfur,
  };
}
