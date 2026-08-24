import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../proveedores/supabase_proveedor.dart';

final proveedorRepositorioProductos = Provider<RepositorioProductos>((ref) {
  return RepositorioProductos(ref.read(supabaseProveedor));
});

class RepositorioProductos {
  final SupabaseClient _supabase;
  static const String tabla = 'productos';

  RepositorioProductos(this._supabase);

  // Obtener stream de productos para un negocio
  Stream<List<Map<String, dynamic>>> escucharProductos(String idNegocio) {
    return _supabase
        .from(tabla)
        .stream(primaryKey: ['id'])
        .eq('id_negocio', idNegocio)
        .order('fecha_creacion', ascending: false);
  }

  // Obtener todos los productos (Para el catálogo global de SweetBites)
  Stream<List<Map<String, dynamic>>> escucharTodosLosProductos() {
    return _supabase
        .from(tabla)
        .stream(primaryKey: ['id'])
        .order('fecha_creacion', ascending: false);
  }

  Future<void> crearProducto({
    required String idNegocio,
    required String nombre,
    String? descripcion,
    required double precio,
    required int inventario,
    String? urlImagen,
    String? categoria,
    Map<String, dynamic>? atributos,
  }) async {
    await _supabase.from(tabla).insert({
      'id_negocio': idNegocio,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'inventario': inventario,
      'url_imagen': urlImagen,
      'categoria': categoria,
      'atributos': atributos ?? {},
    });
  }

  Future<void> actualizarProducto({
    required String id,
    required String nombre,
    String? descripcion,
    required double precio,
    required int inventario,
    String? urlImagen,
    String? categoria,
    Map<String, dynamic>? atributos,
  }) async {
    await _supabase
        .from(tabla)
        .update({
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'inventario': inventario,
          'url_imagen': urlImagen,
          'categoria': categoria,
          'atributos': atributos ?? {},
          'fecha_actualizacion': 'now()',
        })
        .eq('id', id);
  }

  Future<void> eliminarProducto(String id) async {
    await _supabase.from(tabla).delete().eq('id', id);
  }
}
