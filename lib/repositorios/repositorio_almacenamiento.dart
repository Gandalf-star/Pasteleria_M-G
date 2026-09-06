import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../proveedores/supabase_proveedor.dart';

final proveedorRepositorioAlmacenamiento = Provider<RepositorioAlmacenamiento>((
  ref,
) {
  return RepositorioAlmacenamiento(ref.read(supabaseProveedor));
});

/// Sube archivos a Supabase Storage.
///
/// Trabaja con [XFile] y `uploadBinary` en lugar de `dart:io File`: en Flutter
/// Web no existe el sistema de archivos y cualquier uso de `File` lanza
/// `Unsupported operation: _Namespace`. Los bytes funcionan en las dos
/// plataformas sin ramificar el código.
class RepositorioAlmacenamiento {
  final SupabaseClient _supabase;
  final String _bucket = 'negocios_media';

  RepositorioAlmacenamiento(this._supabase);

  /// Extensión del archivo en minúsculas, con `jpg` como valor por defecto.
  static String _extension(XFile archivo) {
    final nombre = archivo.name.isNotEmpty ? archivo.name : archivo.path;
    final partes = nombre.split('.');
    if (partes.length < 2) return 'jpg';
    final ext = partes.last.toLowerCase().split('?').first;
    return ext.isEmpty || ext.length > 5 ? 'jpg' : ext;
  }

  /// Tipo MIME declarado por el selector o deducido de la extensión.
  /// Sin él, Supabase almacena el objeto como `application/octet-stream`
  /// y el navegador no lo muestra al recuperarlo.
  static String _tipoMime(XFile archivo) {
    final declarado = archivo.mimeType;
    if (declarado != null && declarado.isNotEmpty) return declarado;

    switch (_extension(archivo)) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Sube [archivo] al [bucket] indicado y devuelve su URL pública.
  Future<String> _subir({
    required XFile archivo,
    required String bucket,
    String? ruta,
  }) async {
    final bytes = await archivo.readAsBytes();
    final rutaDestino =
        ruta ?? '${const Uuid().v4()}.${_extension(archivo)}';

    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          rutaDestino,
          bytes,
          fileOptions: FileOptions(contentType: _tipoMime(archivo)),
        );

    return _supabase.storage.from(bucket).getPublicUrl(rutaDestino);
  }

  /// Sube una imagen a Supabase Storage y retorna su URL pública.
  /// [carpeta] puede ser 'productos' o 'logos'.
  Future<String> subirImagen({
    required XFile archivo,
    required String carpeta,
    required String idNegocio,
  }) {
    return _subir(
      archivo: archivo,
      bucket: _bucket,
      ruta: '$idNegocio/$carpeta/${const Uuid().v4()}.${_extension(archivo)}',
    );
  }

  /// Sube una foto de perfil al bucket 'perfiles'.
  Future<String> subirArchivoPerfil(XFile archivo) {
    return _subir(archivo: archivo, bucket: 'perfiles');
  }

  /// Sube una foto de cédula al bucket 'cedulas'.
  Future<String> subirArchivoCedula(XFile archivo) {
    return _subir(archivo: archivo, bucket: 'cedulas');
  }

  /// Sube un comprobante de pago al bucket 'pagos', agrupado por conversación.
  Future<String> subirComprobantePago(
    XFile archivo,
    String idConversacion,
  ) {
    return _subir(
      archivo: archivo,
      bucket: 'pagos',
      ruta: '$idConversacion/${const Uuid().v4()}.${_extension(archivo)}',
    );
  }
}
