import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');
  static String get supabasePublishableKey =>
      dotenv.get('SUPABASE_PUBLISHABLE_KEY');

  /// Base URL of the Agrifos FastAPI backend, e.g. https://api.agrifos.com
  static String get apiBaseUrl => dotenv.get('API_BASE_URL');
}
