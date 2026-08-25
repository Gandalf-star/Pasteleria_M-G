import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../proveedores/supabase_proveedor.dart';

final proveedorRepositorioCredito = Provider<RepositorioCredito>((ref) {
  return RepositorioCredito(ref.read(supabaseProveedor));
});

class RepositorioCredito {
  final SupabaseClient _supabase;

  RepositorioCredito(this._supabase);

  String get _idUsuarioActual => _supabase.auth.currentUser?.id ?? '';

  Stream<Map<String, dynamic>?> escucharLineaCredito() {
    if (_idUsuarioActual.isEmpty) return const Stream.empty();
    return _supabase
        .from('lineas_credito')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', _idUsuarioActual)
        .map((lista) => lista.isNotEmpty ? lista.first : null);
  }

  Stream<List<Map<String, dynamic>>> escucharPlanesActivos() {
    if (_idUsuarioActual.isEmpty) return const Stream.empty();
    return _supabase
        .from('planes_financiamiento')
        .stream(primaryKey: ['id'])
        .eq('cliente_id', _idUsuarioActual)
        .map(
          (lista) => lista
              .where((e) => e['estado'] == 'ACTIVO' || e['estado'] == 'EN_MORA')
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> obtenerCuotasPlan(String planId) async {
    final res = await _supabase
        .from('cuotas')
        .select('*')
        .eq('plan_id', planId)
        .order('fecha_vencimiento', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> reportarPagoCuota(String cuotaId) async {
    await _supabase
        .from('cuotas')
        .update({'estado': 'REPORTADO'})
        .eq('id', cuotaId);
  }

  Future<bool> tieneCuotasVencidas() async {
    if (_idUsuarioActual.isEmpty) return false;

    // Buscar si existe alguna cuota vencida para los planes activos del usuario
    final res = await _supabase
        .from('planes_financiamiento')
        .select('id, cuotas!inner(estado)')
        .eq('cliente_id', _idUsuarioActual)
        .eq('cuotas.estado', 'VENCIDA');

    return res.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> obtenerNivelesCredito() async {
    final res = await _supabase
        .from('niveles_credito')
        .select('*')
        .order('nivel', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }
}
