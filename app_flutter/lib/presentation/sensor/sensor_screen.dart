import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sensor_provider.dart';
import '../../core/dev_constants.dart';
import '../../shared/field_label.dart';
import '../auth/auth_provider.dart';
import '../home/latest_reading_provider.dart';

class SensorScreen extends StatefulWidget {
  const SensorScreen({super.key});

  @override
  State<SensorScreen> createState() => _SensorScreenState();
}

class _SensorScreenState extends State<SensorScreen> {
  // TODO: replace with a real parcel picker once the parcels screen exists.
  // For now the user pastes the UUID of the parcel this reading belongs to.
  final _parcelIdController = TextEditingController(text: kPlaceholderParcelId);

  @override
  void dispose() {
    _parcelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>();
    final canSave = sensor.lastReading != null &&
        _parcelIdController.text.trim().isNotEmpty &&
        sensor.saveStatus != SaveStatus.saving;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensor NPK'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Estado: ${sensor.status.name}'),
                if (sensor.status == SensorStatus.reconnecting) ...[
                  const SizedBox(width: 8),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            if (sensor.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  sensor.errorMessage!,
                  style: TextStyle(
                    color: sensor.status == SensorStatus.reconnecting
                        ? Colors.orange
                        : Colors.red,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () =>
                      context.read<SensorProvider>().connectAndListen(),
                  child: const Text('Conectar sensor'),
                ),
                const SizedBox(width: 12),
                if (sensor.status == SensorStatus.connected ||
                    sensor.status == SensorStatus.reconnecting)
                  OutlinedButton(
                    onPressed: () =>
                        context.read<SensorProvider>().disconnect(),
                    child: const Text('Desconectar'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (sensor.lastReading != null) ...[
              Text('Nitrógeno: ${sensor.lastReading!.nitrogen}'),
              Text('Fósforo: ${sensor.lastReading!.phosphorus}'),
              Text('Potasio: ${sensor.lastReading!.potassium}'),
              Text('EC: ${sensor.lastReading!.ec}'),
              Text('pH: ${sensor.lastReading!.ph}'),
              Text('Temperatura: ${sensor.lastReading!.temperature} °C'),
              Text('Humedad: ${sensor.lastReading!.humidity} %'),
              const SizedBox(height: 20),
              FieldLabel('ID de la parcela'.toUpperCase()),
              TextField(
                controller: _parcelIdController,
                decoration: const InputDecoration(
                  hintText: 'UUID de la parcela',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: canSave
                        ? () async {
                      final sensorProvider =
                      context.read<SensorProvider>();
                      final parcelId = _parcelIdController.text.trim();
                      await sensorProvider.saveCurrentReading(parcelId);
                      if (sensorProvider.saveStatus ==
                          SaveStatus.saved &&
                          context.mounted) {
                        context
                            .read<LatestReadingProvider>()
                            .fetchLatest(parcelId);
                      }
                    }
                        : null,
                    child: sensor.saveStatus == SaveStatus.saving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text('Guardar lectura'),
                  ),
                  const SizedBox(width: 12),
                  if (sensor.saveStatus == SaveStatus.saved)
                    const Text(
                      'Lectura guardada ✓',
                      style: TextStyle(color: Colors.green),
                    ),
                ],
              ),
              if (sensor.saveStatus == SaveStatus.error &&
                  sensor.saveErrorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    sensor.saveErrorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ] else
              const Text('Sin lecturas todavía'),
          ],
        ),
      ),
    );
  }
}