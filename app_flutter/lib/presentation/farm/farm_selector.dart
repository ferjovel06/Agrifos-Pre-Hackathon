import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'farm_provider.dart';
import 'farm_registration_screen.dart';
import 'parcel_provider.dart';

/// Chooses the farm used by all farm-scoped sections of the application.
class FarmSelector extends StatelessWidget {
  const FarmSelector({super.key});

  Future<void> _addFarm(BuildContext context) async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const FarmRegistrationScreen()),
    );
    if (!context.mounted) return;
    final farmId = context.read<FarmProvider>().selectedFarmId;
    await context.read<ParcelProvider>().loadForFarm(farmId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FarmProvider>();
    if (provider.status != FarmStatus.hasFarm || provider.currentFarm == null) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            key: ValueKey('farm-selector-${provider.selectedFarmId}'),
            initialValue: provider.selectedFarmId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Finca activa',
              prefixIcon: const Icon(Icons.eco_outlined),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            items: provider.farms
                .map(
                  (farm) => DropdownMenuItem<String>(
                    value: farm.id,
                    child: Text(farm.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (farmId) {
              if (farmId != null) provider.selectFarm(farmId);
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          key: const ValueKey('add-farm-button'),
          tooltip: 'Agregar finca',
          onPressed: () => _addFarm(context),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
