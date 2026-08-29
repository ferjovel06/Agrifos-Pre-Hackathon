import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/env.dart';
import 'core/supabase_http_client.dart';
import 'data/api/auth_repository.dart';
import 'presentation/auth/auth_provider.dart';
import 'presentation/auth/auth_gate.dart';
import 'presentation/farm/farm_provider.dart';
import 'presentation/home/latest_reading_provider.dart';
import 'presentation/home/weather_provider.dart';
import 'presentation/sensor/sensor_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabasePublishableKey,
    httpClient: SupabaseHttpClient(),
  );

  runApp(const AgrifosApp());
}

class AgrifosApp extends StatelessWidget {
  const AgrifosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthRepository())),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => LatestReadingProvider()),
        ChangeNotifierProvider(create: (_) => WeatherProvider()),
        ChangeNotifierProvider(create: (_) => FarmProvider()),
      ],
      child: MaterialApp(
        title: 'Agrifos',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.green,
          textTheme: GoogleFonts.nunitoTextTheme(),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF7F5F1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF2E4A2E),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w400,
            ),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
