import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl => dotenv.get('SUPABASE_URL');
  static String get supabasePublishableKey => dotenv.get('SUPABASE_PUBLISHABLE_KEY');
}