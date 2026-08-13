import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'sensor_provider.dart';
import '../auth/auth_provider.dart';

class SensorScreen extends StatelessWidget {
  const SensorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sensor = context.watch<SensorProvider>();

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
            ] else
              const Text('Sin lecturas todavía'),
          ],
        ),
      ),
    );
  }
}
