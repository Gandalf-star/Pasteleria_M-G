import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../proveedores/supabase_proveedor.dart';

final proveedorRepositorioConversaciones = Provider<RepositorioConversaciones>((
  ref,
) {
  return RepositorioConversaciones(ref.read(supabaseProveedor));
});

class RepositorioConversaciones {
  final SupabaseClient _supabase;
  static const String tabla = 'conversaciones';

  RepositorioConversaciones(this._supabase);

  Stream<List<Map<String, dynamic>>> escucharConversaciones(String idNegocio) {
    return _supabase
        .from(tabla)
        .stream(primaryKey: ['id'])
        .eq('id_negocio', idNegocio)
        .order('fecha_actualizacion', ascending: false);
  }

  Future<void> actualizarEstadoIA(String idConversacion, bool pausar) async {
    await _supabase
        .from(tabla)
        .update({'ia_pausada': pausar, 'fecha_actualizacion': 'now()'})
        .eq('id', idConversacion);
  }
}
