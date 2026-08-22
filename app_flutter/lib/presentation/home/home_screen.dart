import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/dev_constants.dart';
import '../auth/auth_provider.dart';
import '../sensor/sensor_provider.dart';
import 'latest_reading_provider.dart';
import 'widgets/last_reading_card.dart';
import 'widgets/panel_header.dart';

/// Home / dashboard tab shown in [MainShell].
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // TODO: use the parcel the user has selected once parcel selection exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LatestReadingProvider>().fetchLatest(kPlaceholderParcelId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final latestReading = context.watch<LatestReadingProvider>();
    final sensor = context.watch<SensorProvider>();
    final isSensorConnected = sensor.status == SensorStatus.connected;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PanelHeader(
                userName: auth.user?.name ?? auth.user?.email,
                onNotificationsTap: () {},
                onProfileTap: () {},
              ),
              const SizedBox(height: 20),
              LastReadingCard(
                reading: latestReading.reading,
                isLoading: latestReading.status == LatestReadingStatus.loading,
                isSensorConnected: isSensorConnected,
                errorMessage: latestReading.status == LatestReadingStatus.error
                    ? latestReading.errorMessage
                    : null,
                onRetry: () => context
                    .read<LatestReadingProvider>()
                    .fetchLatest(kPlaceholderParcelId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}