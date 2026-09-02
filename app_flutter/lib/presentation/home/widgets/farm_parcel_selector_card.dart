import 'package:flutter/material.dart';

import '../../farm/farm_selector.dart';
import '../../farm/parcel_selector.dart';

class FarmParcelSelectorCard extends StatelessWidget {
  const FarmParcelSelectorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EAE2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1E321F),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.landscape_outlined, color: Color(0xFF31543B)),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Finca y parcela',
                      style: TextStyle(
                        color: Color(0xFF472319),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Selecciona dónde quieres trabajar',
                      style: TextStyle(color: Color(0xFF737A72), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14),
          FarmSelector(),
          SizedBox(height: 10),
          ParcelSelector(),
        ],
      ),
    );
  }
}
