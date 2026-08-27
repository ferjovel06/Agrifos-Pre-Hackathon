import 'package:app_flutter/domain/entities/lab_analysis.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps a laboratory analysis response', () {
    final analysis = LabAnalysis.fromJson({
      'id': 'analysis-1',
      'parcel_id': 'parcel-1',
      'sample_code': 'M-001',
      'sampled_at': '2026-08-20T00:00:00Z',
      'depth_start_cm': 0,
      'depth_end_cm': 20,
      'lab': 'Laboratorio Agrícola',
      'ph': 5.8,
      'ph_method': 'Agua 1:2.5',
      'ec': 0.4,
      'ec_method': 'Extracto 1:2.5',
      'organic_matter_pct': 4.2,
      'cic': 18,
      'clay_pct': 30,
      'silt_pct': 30,
      'sand_pct': 40,
      'nitrogen': 24,
      'phosphorus': 12,
      'phosphorus_method': 'Bray II',
      'potassium': 110,
      'potassium_method': 'Acetato de amonio',
      'calcium': 1200,
      'magnesium': 180,
      'sulfur': 14,
      'recorded_at': '2026-08-21T10:30:00Z',
    });

    expect(analysis.sampleCode, 'M-001');
    expect(analysis.ph, 5.8);
    expect(analysis.potassium, 110);
    expect(analysis.sampledAt, DateTime.utc(2026, 8, 20));
  });

  test('serializes input using backend field names', () {
    final input = LabAnalysisInput(
      sampleCode: 'M-002',
      sampledAt: DateTime.utc(2026, 8, 22),
      depthStartCm: 0,
      depthEndCm: 20,
      lab: 'Lab',
      ph: 6,
      phMethod: 'Agua',
      ec: 0.5,
      ecMethod: 'Extracto',
      organicMatterPct: 4,
      cic: 16,
      clayPct: 30,
      siltPct: 30,
      sandPct: 40,
      nitrogen: 20,
      phosphorus: 10,
      phosphorusMethod: 'Bray II',
      potassium: 100,
      potassiumMethod: 'Acetato',
      calcium: 1000,
      magnesium: 150,
      sulfur: 12,
    );

    expect(input.toJson()['sample_code'], 'M-002');
    expect(input.toJson()['organic_matter_pct'], 4);
    expect(input.toJson()['sampled_at'], '2026-08-22T00:00:00.000Z');
  });
}
