import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Proveedor global para acceder al cliente de Supabase
final supabaseProveedor = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
