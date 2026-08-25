import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../proveedores/supabase_proveedor.dart';
import '../proveedores/proveedor_carrito.dart';

final proveedorRepositorioOrdenes = Provider<RepositorioOrdenes>((ref) {
  return RepositorioOrdenes(ref.read(supabaseProveedor));
});

class RepositorioOrdenes {
  final SupabaseClient _supabase;

  RepositorioOrdenes(this._supabase);

  Future<String> crearOrden(List<ItemCarrito> items, double total, {bool esFinanciamiento = false}) async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) throw Exception('Usuario no autenticado');

    // Insertar orden principal
    final ordenRes = await _supabase.from('ordenes').insert({
      'id_cliente': usuario.id,
      'total': total,
      'estado': 'pendiente',
      'es_financiamiento': esFinanciamiento,
    }).select('id').single();

    final idOrden = ordenRes['id'] as String;

    // Insertar detalles
    final detalles = items.map((item) {
      return {
        'id_orden': idOrden,
        'id_producto': item.producto['id'],
        'cantidad': item.cantidad,
        'precio_unitario': item.producto['precio'],
      };
    }).toList();

    await _supabase.from('detalles_orden').insert(detalles);

    return idOrden;
  }

  Stream<List<Map<String, dynamic>>> escucharTodasLasOrdenes() {
    // Escucha órdenes entrantes (Solo Super Admin)
    return _supabase
        .from('ordenes')
        .stream(primaryKey: ['id'])
        .order('fecha_creacion', ascending: false);
  }

  Future<Map<String, dynamic>> obtenerEstadisticasUsuario() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return {'total_pedidos': 0, 'total_gastado': 0.0};

    try {
      final res = await _supabase
          .from('ordenes')
          .select('total')
          .eq('id_cliente', usuario.id);
      
      final ordenes = List<Map<String, dynamic>>.from(res);
      double totalGastado = 0;
      for (var orden in ordenes) {
        totalGastado += double.parse(orden['total'].toString());
      }
      
      return {
        'total_pedidos': ordenes.length,
        'total_gastado': totalGastado,
      };
    } catch (e) {
      return {'total_pedidos': 0, 'total_gastado': 0.0};
    }
  }
}
