import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'farm_provider.dart';
import 'farm_registration_screen.dart';
import 'parcel_provider.dart';

class ParcelSelector extends StatelessWidget {
  const ParcelSelector({super.key});

  Future<void> _addParcel(BuildContext context) async {
    final farmId = context.read<FarmProvider>().selectedFarmId;
    if (farmId == null) return;
    await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => FarmRegistrationScreen(farmId: farmId)),
    );
    if (!context.mounted) return;
    await context.read<ParcelProvider>().loadForFarm(farmId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ParcelProvider>();
    final farmId = context.watch<FarmProvider>().selectedFarmId;
    if (farmId == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(child: _buildField(provider)),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          key: const ValueKey('add-parcel-button'),
          tooltip: 'Agregar parcela',
          onPressed: () => _addParcel(context),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildField(ParcelProvider provider) {
    return switch (provider.status) {
      ParcelStatus.loading ||
      ParcelStatus.initial => const LinearProgressIndicator(),
      ParcelStatus.error => Text(
        provider.errorMessage ?? 'No se pudieron cargar las parcelas.',
      ),
      ParcelStatus.noParcel => const Text('Aún no hay parcelas en esta finca.'),
      ParcelStatus.hasParcel => DropdownButtonFormField<String>(
        key: ValueKey('parcel-selector-${provider.selectedParcelId}'),
        initialValue: provider.selectedParcelId,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Parcela activa',
          prefixIcon: const Icon(Icons.grid_view_outlined),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        items: provider.parcels
            .map(
              (parcel) => DropdownMenuItem<String>(
                value: parcel.id,
                child: Text(parcel.name, overflow: TextOverflow.ellipsis),
              ),
            )
            .toList(),
        onChanged: (parcelId) {
          if (parcelId != null) provider.selectParcel(parcelId);
        },
      ),
    };
  }
}
