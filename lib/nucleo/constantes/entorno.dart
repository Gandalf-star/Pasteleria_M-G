import 'package:flutter_dotenv/flutter_dotenv.dart';

class Entorno {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get difyApiKey => dotenv.env['DIFY_API_KEY'] ?? '';

  /// UUID fijo del negocio SweetBites en la BD
  static const String idSweetBites = '00000000-0000-0000-0000-000000000001';
}
