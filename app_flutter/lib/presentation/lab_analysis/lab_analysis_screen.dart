import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/api/api_client.dart';
import '../../data/api/lab_analysis_repository.dart';
import '../../domain/entities/lab_analysis.dart';

class LabAnalysisScreen extends StatefulWidget {
  const LabAnalysisScreen({
    super.key,
    required this.parcelId,
    required this.parcelName,
    this.repository,
  });

  final String parcelId;
  final String parcelName;
  final LabAnalysisRepository? repository;

  @override
  State<LabAnalysisScreen> createState() => _LabAnalysisScreenState();
}

class _LabAnalysisScreenState extends State<LabAnalysisScreen> {
  late final LabAnalysisRepository _repository;
  List<LabAnalysis> _analyses = const [];
  bool _loading = true;
  String? _error;

  static const _background = Color(0xFFF9F2EC);
  static const _brown = Color(0xFF472319);
  static const _green = Color(0xFF31543B);

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LabAnalysisRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final analyses = await _repository.listForParcel(widget.parcelId);
      if (!mounted) return;
      setState(() {
        _analyses = analyses;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _message(error);
      });
    }
  }

  Future<void> _openForm([LabAnalysis? analysis]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LabAnalysisFormScreen(
          parcelId: widget.parcelId,
          analysis: analysis,
          repository: _repository,
        ),
      ),
    );
    if (saved == true) {
      await _load();
    }
  }

  Future<void> _delete(LabAnalysis analysis) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar análisis'),
        content: Text(
          '¿Deseas eliminar la muestra "${analysis.sampleCode ?? 'Sin código'}"? '
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _repository.delete(analysis.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Análisis eliminado.')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  String _message(Object error) {
    if (error is ApiAuthException) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder. Verifica tu conexión.';
    }
    if (error is ApiException) {
      switch (error.statusCode) {
        case 403:
          return 'No tienes permiso para consultar esta parcela.';
        case 404:
          return 'La parcela o el análisis ya no existe.';
        case 409:
          return 'Ese código de muestra ya está registrado.';
        default:
          if (error.statusCode >= 500) {
            return 'El servidor no pudo completar la operación. Intenta más tarde.';
          }
      }
    }
    return 'No se pudo completar la operación. Verifica tu conexión.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _brown,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Análisis de laboratorio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.parcelName,
              style: const TextStyle(
                color: Color(0xFFA99B96),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo análisis'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFD78A22)),
              const SizedBox(height: 10),
              Text(_error!, textAlign: TextAlign.center),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_analyses.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.science_outlined, size: 48, color: Color(0xFFA99B96)),
              SizedBox(height: 12),
              Text(
                'Aún no hay análisis para esta parcela.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _brown, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 5),
              Text(
                'Registra los resultados entregados por el laboratorio.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF8D817C)),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: _analyses.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final analysis = _analyses[index];
          return _AnalysisTile(
            analysis: analysis,
            onEdit: () => _openForm(analysis),
            onDelete: () => _delete(analysis),
          );
        },
      ),
    );
  }
}

class _AnalysisTile extends StatelessWidget {
  const _AnalysisTile({
    required this.analysis,
    required this.onEdit,
    required this.onDelete,
  });

  final LabAnalysis analysis;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final date = analysis.sampledAt ?? analysis.recordedAt;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F0),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.science_outlined,
                  color: Color(0xFF31543B),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      analysis.sampleCode ?? 'Sin código',
                      style: const TextStyle(
                        color: Color(0xFF472319),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${_date(date)} · ${analysis.lab}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9D908B),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Editar')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFEDE8E5)),
          Row(
            children: [
              _Metric(label: 'pH', value: analysis.ph.toStringAsFixed(1)),
              _Metric(label: 'N', value: analysis.nitrogen.toStringAsFixed(1)),
              _Metric(
                label: 'P',
                value: analysis.phosphorus.toStringAsFixed(1),
              ),
              _Metric(label: 'K', value: analysis.potassium.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFFA99B96), fontSize: 10),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF31543B),
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class LabAnalysisFormScreen extends StatefulWidget {
  const LabAnalysisFormScreen({
    super.key,
    required this.parcelId,
    required this.repository,
    this.analysis,
  });

  final String parcelId;
  final LabAnalysisRepository repository;
  final LabAnalysis? analysis;

  @override
  State<LabAnalysisFormScreen> createState() => _LabAnalysisFormScreenState();
}

class _LabAnalysisFormScreenState extends State<LabAnalysisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  late DateTime _sampledAt;
  bool _saving = false;

  static const _background = Color(0xFFF9F2EC);
  static const _brown = Color(0xFF472319);
  static const _green = Color(0xFF31543B);
  static const _phMethods = [
    'Potenciométrico en agua 1:1',
    'Potenciométrico en agua 1:2.5',
    'Potenciométrico en KCl',
  ];
  static const _ecMethods = [
    'Pasta saturada',
    'Extracto suelo:agua 1:1',
    'Extracto suelo:agua 1:2.5',
  ];
  static const _phosphorusMethods = ['Bray I', 'Bray II', 'Olsen', 'Mehlich 3'];
  static const _potassiumMethods = ['Acetato de amonio', 'Mehlich 3'];

  @override
  void initState() {
    super.initState();
    final value = widget.analysis;
    _sampledAt = value?.sampledAt ?? DateTime.now();
    _set('sampleCode', value?.sampleCode);
    _set('lab', value?.lab);
    _set('depthStart', value?.depthStartCm);
    _set('depthEnd', value?.depthEndCm);
    _set('ph', value?.ph);
    _set('phMethod', value?.phMethod);
    _set('ec', value?.ec);
    _set('ecMethod', value?.ecMethod);
    _set('organicMatter', value?.organicMatterPct);
    _set('cic', value?.cic);
    _set('clay', value?.clayPct);
    _set('silt', value?.siltPct);
    _set('sand', value?.sandPct);
    _set('nitrogen', value?.nitrogen);
    _set('phosphorus', value?.phosphorus);
    _set('phosphorusMethod', value?.phosphorusMethod);
    _set('potassium', value?.potassium);
    _set('potassiumMethod', value?.potassiumMethod);
    _set('calcium', value?.calcium);
    _set('magnesium', value?.magnesium);
    _set('sulfur', value?.sulfur);
  }

  void _set(String key, Object? value) {
    _controllers[key] = TextEditingController(text: value?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _number(String key) => double.parse(_controllers[key]!.text.trim());

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _sampledAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Fecha de muestreo',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (selected != null && mounted) setState(() => _sampledAt = selected);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa los campos pendientes en cada sección.'),
        ),
      );
      return;
    }
    final texture = _number('clay') + _number('silt') + _number('sand');
    if (texture < 99.5 || texture > 100.5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arcilla, limo y arena deben sumar 100%.'),
        ),
      );
      return;
    }
    if (_number('depthEnd') <= _number('depthStart')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La profundidad final debe ser mayor que la inicial.'),
        ),
      );
      return;
    }
    if (_number('ec') >= 1.1 && !await _confirmHighConductivity()) return;

    final input = LabAnalysisInput(
      sampleCode: _text('sampleCode'),
      sampledAt: _sampledAt,
      depthStartCm: _number('depthStart'),
      depthEndCm: _number('depthEnd'),
      lab: _text('lab'),
      ph: _number('ph'),
      phMethod: _text('phMethod'),
      ec: _number('ec'),
      ecMethod: _text('ecMethod'),
      organicMatterPct: _number('organicMatter'),
      cic: _number('cic'),
      clayPct: _number('clay'),
      siltPct: _number('silt'),
      sandPct: _number('sand'),
      nitrogen: _number('nitrogen'),
      phosphorus: _number('phosphorus'),
      phosphorusMethod: _text('phosphorusMethod'),
      potassium: _number('potassium'),
      potassiumMethod: _text('potassiumMethod'),
      calcium: _number('calcium'),
      magnesium: _number('magnesium'),
      sulfur: _number('sulfur'),
    );

    setState(() => _saving = true);
    try {
      final analysis = widget.analysis;
      if (analysis == null) {
        await widget.repository.create(widget.parcelId, input);
      } else {
        await widget.repository.update(analysis.id, input);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = _friendlyError(error);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _text(String key) => _controllers[key]!.text.trim();

  Future<bool> _confirmHighConductivity() async {
    final value = _number('ec');
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD78A22),
            ),
            title: const Text('Conductividad elevada'),
            content: Text(
              'Ingresaste $value dS/m. Desde 1.1 dS/m existe riesgo de '
              'salinidad y el sistema no generará un plan automático.\n\n'
              'Si el informe usa µS/cm, divide el valor entre 1,000. '
              'Por ejemplo: 100 µS/cm = 0.10 dS/m.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Corregir valor'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Guardar de todos modos'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _friendlyError(Object error) {
    if (error is ApiAuthException) {
      return 'Tu sesión venció. Inicia sesión nuevamente.';
    }
    if (error is TimeoutException) {
      return 'El servidor tardó demasiado en responder. Verifica tu conexión.';
    }
    if (error is ApiException) {
      switch (error.statusCode) {
        case 403:
          return 'No tienes permiso para modificar esta parcela.';
        case 404:
          return 'La parcela o el análisis ya no existe. Actualiza la lista.';
        case 409:
          return 'Ese código de muestra ya está registrado en esta parcela.';
        case 422:
          return _validationErrorMessage(error.message);
        default:
          if (error.statusCode >= 500) {
            return 'El servidor no pudo guardar el análisis. Intenta más tarde.';
          }
      }
    }
    return 'No se pudo guardar el análisis. Verifica tu conexión e intenta de nuevo.';
  }

  String _validationErrorMessage(String message) {
    const labels = <String, String>{
      'sample_code': 'código de muestra',
      'sampled_at': 'fecha de muestreo',
      'depth_start_cm': 'profundidad inicial',
      'depth_end_cm': 'profundidad final',
      'lab': 'laboratorio',
      'ph_method': 'método de pH',
      'ph': 'pH',
      'ec_method': 'método de conductividad',
      'ec': 'conductividad',
      'organic_matter_pct': 'materia orgánica',
      'cic': 'CIC',
      'clay_pct': 'arcilla',
      'silt_pct': 'limo',
      'sand_pct': 'arena',
      'nitrogen': 'nitrógeno',
      'phosphorus_method': 'método de fósforo',
      'phosphorus': 'fósforo',
      'potassium_method': 'método de potasio',
      'potassium': 'potasio',
      'calcium': 'calcio',
      'magnesium': 'magnesio',
      'sulfur': 'azufre',
    };
    final tokens = message.split(RegExp(r'[^A-Za-z0-9_]')).toSet();
    final invalid = labels.entries
        .where((entry) => tokens.contains(entry.key))
        .map((entry) => entry.value)
        .toSet()
        .toList();
    if (invalid.isEmpty) {
      return 'Hay datos no válidos. Revisa los campos marcados y sus unidades.';
    }
    return 'Revisa: ${invalid.join(', ')}.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _brown,
        elevation: 0,
        title: Text(
          widget.analysis == null ? 'Registrar análisis' : 'Editar análisis',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _FormHelp(),
            const SizedBox(height: 14),
            _Section(
              title: 'Identificación de la muestra',
              icon: Icons.assignment_outlined,
              initiallyExpanded: true,
              children: [
                _textField(
                  'sampleCode',
                  'Código de muestra',
                  'Ej. M-2026-001',
                  maxLength: 100,
                ),
                _textField(
                  'lab',
                  'Laboratorio',
                  'Nombre del laboratorio',
                  minLength: 2,
                  maxLength: 150,
                ),
                _dateField(),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField(
                        'depthStart',
                        'Desde',
                        'cm',
                        max: 200,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField('depthEnd', 'Hasta', 'cm', max: 300),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Propiedades del suelo',
              icon: Icons.landscape_outlined,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField(
                        'ph',
                        'pH',
                        'unidad',
                        min: 2,
                        max: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField(
                        'ec',
                        'Conductividad',
                        'dS/m',
                        max: 20,
                      ),
                    ),
                  ],
                ),
                const _HelpCallout(
                  icon: Icons.swap_horiz,
                  text:
                      'Conversión: si el informe usa µS/cm, divide el valor '
                      'entre 1,000. Ejemplo: 100 µS/cm = 0.10 dS/m.',
                ),
                const SizedBox(height: 12),
                _methodField('phMethod', 'Método de pH', _phMethods),
                _methodField('ecMethod', 'Método de conductividad', _ecMethods),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField(
                        'organicMatter',
                        'Materia orgánica',
                        '%',
                        max: 100,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField(
                        'cic',
                        'CIC (cmolc/kg)',
                        '',
                        max: 200,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Textura',
              icon: Icons.grain,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField('clay', 'Arcilla', '%', max: 100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField('silt', 'Limo', '%', max: 100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _numberField('sand', 'Arena', '%', max: 100),
                    ),
                  ],
                ),
                const _SubtleNote(
                  text: 'Arcilla, limo y arena deben sumar exactamente 100%.',
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Section(
              title: 'Nutrientes',
              icon: Icons.eco_outlined,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField('nitrogen', 'Nitrógeno', 'mg/kg'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField('phosphorus', 'Fósforo', 'mg/kg'),
                    ),
                  ],
                ),
                _methodField(
                  'phosphorusMethod',
                  'Método de fósforo',
                  _phosphorusMethods,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField('potassium', 'Potasio', 'mg/kg'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField('calcium', 'Calcio', 'mg/kg')),
                  ],
                ),
                _methodField(
                  'potassiumMethod',
                  'Método de potasio',
                  _potassiumMethods,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _numberField('magnesium', 'Magnesio', 'mg/kg'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _numberField('sulfur', 'Azufre', 'mg/kg')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Guardando...' : 'Guardar análisis'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateField() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Fecha de muestreo',
          suffixIcon: Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          '${_sampledAt.day.toString().padLeft(2, '0')}/'
          '${_sampledAt.month.toString().padLeft(2, '0')}/${_sampledAt.year}',
        ),
      ),
    ),
  );

  Widget _textField(
    String key,
    String label,
    String hint, {
    int minLength = 1,
    int? maxLength,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controllers[key],
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return 'Completa este campo.';
        if (text.length < minLength) {
          return 'Escribe al menos $minLength caracteres.';
        }
        if (maxLength != null && text.length > maxLength) {
          return 'Máximo $maxLength caracteres.';
        }
        return null;
      },
    ),
  );

  Widget _methodField(String key, String label, List<String> options) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: _controllers[key],
          readOnly: true,
          onTap: () => _selectMethod(key, label, options),
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Seleccionar según el informe',
            suffixIcon: const Icon(Icons.keyboard_arrow_down),
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Selecciona un método.';
            if (text.length < 2) return 'Especifica mejor el método.';
            if (text.length > 100) return 'Máximo 100 caracteres.';
            return null;
          },
        ),
      );

  Future<void> _selectMethod(
    String key,
    String label,
    List<String> options,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                label,
                style: const TextStyle(
                  color: _brown,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...options.map(
              (option) => ListTile(
                leading: Icon(
                  _controllers[key]!.text == option
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: _controllers[key]!.text == option
                      ? _green
                      : const Color(0xFFA99B96),
                ),
                title: Text(option),
                onTap: () => Navigator.pop(context, option),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Otro método'),
              subtitle: const Text(
                'Escribir exactamente como aparece en el informe',
              ),
              onTap: () => Navigator.pop(context, '__other__'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == '__other__') {
      await _enterOtherMethod(key, label);
    } else {
      setState(() => _controllers[key]!.text = selected);
    }
  }

  Future<void> _enterOtherMethod(String key, String label) async {
    final controller = TextEditingController(text: _controllers[key]!.text);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(label),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Método indicado por el laboratorio',
            hintText: 'Escríbelo como aparece en el informe',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) Navigator.pop(context, text);
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (mounted && value != null) {
      setState(() => _controllers[key]!.text = value);
    }
  }

  Widget _numberField(
    String key,
    String label,
    String suffix, {
    double min = 0,
    double? max,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: _controllers[key],
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix.isEmpty ? null : suffix,
        suffixStyle: const TextStyle(color: Color(0xFF9D908B), fontSize: 12),
      ),
      validator: (value) {
        final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
        if (parsed == null) return 'Ingresa un valor.';
        if (parsed < min || (max != null && parsed > max)) {
          return max == null
              ? 'Debe ser $min o mayor.'
              : 'Debe estar entre $min y $max.';
        }
        return null;
      },
      onChanged: (value) {
        if (value.contains(',')) {
          final normalized = value.replaceAll(',', '.');
          _controllers[key]!.value = TextEditingValue(
            text: normalized,
            selection: TextSelection.collapsed(offset: normalized.length),
          );
        }
      },
    ),
  );
}

class _HelpCallout extends StatelessWidget {
  const _HelpCallout({required this.text, this.icon = Icons.info_outline});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF6E8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFD78A22)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF70422E),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  );
}

class _SubtleNote extends StatelessWidget {
  const _SubtleNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 15, color: Color(0xFF9D908B)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF8D817C),
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FormHelp extends StatelessWidget {
  const _FormHelp();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, color: Color(0xFF8D817C), size: 17),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Ingresa los resultados usando las unidades mostradas en cada campo. '
            'Abre cada sección para continuar.',
            style: TextStyle(
              color: Color(0xFF8D817C),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        maintainState: true,
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        childrenPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        iconColor: const Color(0xFF31543B),
        collapsedIconColor: const Color(0xFF8D817C),
        title: Row(
          children: [
            Icon(icon, color: const Color(0xFF31543B), size: 20),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF472319),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        children: children,
      ),
    ),
  );
}
