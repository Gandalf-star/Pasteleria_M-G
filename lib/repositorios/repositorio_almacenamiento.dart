import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../proveedores/supabase_proveedor.dart';

final proveedorRepositorioAlmacenamiento = Provider<RepositorioAlmacenamiento>((ref) {
  return RepositorioAlmacenamiento(ref.read(supabaseProveedor));
});

class RepositorioAlmacenamiento {
  final SupabaseClient _supabase;
  final String _bucket = 'negocios_media';

  RepositorioAlmacenamiento(this._supabase);

  /// Sube una imagen a Supabase Storage y retorna su URL pública
  /// [carpeta] puede ser 'productos' o 'logos'
  Future<String> subirImagen({
    required File archivo,
    required String carpeta,
    required String idNegocio,
  }) async {
    final extension = archivo.path.split('.').last;
    final nombreArchivo = '${const Uuid().v4()}.$extension';
    final rutaDestino = '$idNegocio/$carpeta/$nombreArchivo';

    await _supabase.storage.from(_bucket).upload(rutaDestino, archivo);
    
    return _supabase.storage.from(_bucket).getPublicUrl(rutaDestino);
  }

  /// Sube una foto de perfil al bucket 'perfiles'
  Future<String> subirArchivoPerfil(File archivo) async {
    final extension = archivo.path.split('.').last;
    final nombreArchivo = '${const Uuid().v4()}.$extension';
    
    await _supabase.storage.from('perfiles').upload(nombreArchivo, archivo);
    
    return _supabase.storage.from('perfiles').getPublicUrl(nombreArchivo);
  }

  /// Sube una foto de cédula al bucket 'cedulas'
  Future<String> subirArchivoCedula(File archivo) async {
    final extension = archivo.path.split('.').last;
    final nombreArchivo = '${const Uuid().v4()}.$extension';
    
    await _supabase.storage.from('cedulas').upload(nombreArchivo, archivo);
    
    return _supabase.storage.from('cedulas').getPublicUrl(nombreArchivo);
  }
}
