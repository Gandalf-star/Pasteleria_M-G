import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../proveedores/supabase_proveedor.dart';

final proveedorRepositorioAutenticacion = Provider<RepositorioAutenticacion>((
  ref,
) {
  return RepositorioAutenticacion(ref.read(supabaseProveedor));
});

class RepositorioAutenticacion {
  final SupabaseClient _supabase;

  RepositorioAutenticacion(this._supabase);

  // Permite autenticarse anónimamente (para los clientes finales en la PWA)
  Future<AuthResponse> iniciarSesionAnonima() async {
    return await _supabase.auth.signInAnonymously();
  }

  // Inicio de sesión para dueños de tienda o clientes
  Future<AuthResponse> iniciarSesion(String correo, String contrasena) async {
    return await _supabase.auth.signInWithPassword(
      email: correo,
      password: contrasena,
    );
  }

  // Registro de un nuevo usuario final (cliente) con datos extendidos
  Future<void> registrarUsuario({
    required String correo,
    required String contrasena,
    required String nombre,
    required String cedula,
    required String telefono,
    required String direccion,
    String? fotoUrl,
    String? fotoCedulaUrl,
  }) async {
    final respuesta = await _supabase.auth.signUp(
      email: correo,
      password: contrasena,
    );
    final userId = respuesta.user?.id;
    if (userId == null) throw Exception('Error al crear la cuenta de usuario.');

    // Insertar en tabla clientes con todos los campos nuevos
    await _supabase.from('clientes').insert({
      'id': userId,
      'nombre': nombre,
      'correo': correo,
      'cedula': cedula,
      'telefono': telefono,
      'direccion': direccion,
      if (fotoUrl != null) 'foto_url': fotoUrl,
      if (fotoCedulaUrl != null) 'foto_cedula_url': fotoCedulaUrl,
    });
  }

  // Registro de un nuevo negocio
  Future<void> registrarNegocio({
    required String correo,
    required String contrasena,
    required String nombreNegocio,
    required String telefono,
    required String tipoNegocio,
  }) async {
    // 1. Crear usuario en Supabase Auth
    final respuesta = await _supabase.auth.signUp(
      email: correo,
      password: contrasena,
    );

    final userId = respuesta.user?.id;
    if (userId == null) throw Exception('Error al crear la cuenta de usuario.');

    // 2. Insertar el negocio con estado 'pendiente'
    await _supabase.from('negocios').insert({
      'id_propietario': userId,
      'nombre': nombreNegocio,
      'correo_propietario': correo,
      'telefono': telefono,
      'estado': 'pendiente',
      'tipo_negocio': tipoNegocio,
    });
  }

  // Obtiene el estado del negocio asociado al usuario autenticado
  Future<String?> obtenerEstadoNegocio() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return null;

    try {
      final datos = await _supabase
          .from('negocios')
          .select('estado')
          .eq('id_propietario', usuario.id)
          .maybeSingle();

      return datos?['estado'] as String?;
    } catch (_) {
      return null;
    }
  }

  // Verifica si el usuario autenticado es un cliente (existe en la tabla clientes)
  Future<bool> esCliente() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return false;
    try {
      final datos = await _supabase
          .from('clientes')
          .select('id')
          .eq('id', usuario.id)
          .maybeSingle();
      return datos != null;
    } catch (_) {
      return false;
    }
  }

  // Verifica si el usuario es Super Admin
  Future<bool> esAdmin() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return false;
    try {
      final datos = await _supabase
          .from('clientes')
          .select('es_admin')
          .eq('id', usuario.id)
          .maybeSingle();
      return datos != null && datos['es_admin'] == true;
    } catch (_) {
      return false;
    }
  }

  // Obtiene los datos completos del negocio del usuario autenticado
  Future<Map<String, dynamic>?> obtenerNegocioActual() async {
    final usuario = _supabase.auth.currentUser;
    if (usuario == null) return null;

    try {
      final datos = await _supabase
          .from('negocios')
          .select()
          .eq('id_propietario', usuario.id)
          .maybeSingle();

      return datos;
    } catch (_) {
      return null;
    }
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  User? obtenerUsuarioActual() {
    return _supabase.auth.currentUser;
  }

  // Stream de cambios en autenticación
  Stream<AuthState> escucharCambiosAuth() {
    return _supabase.auth.onAuthStateChange;
  }

  // Actualiza la URL del logo del negocio
  Future<void> actualizarLogoNegocio(String idNegocio, String urlLogo) async {
    await _supabase
        .from('negocios')
        .update({'logo_url': urlLogo})
        .eq('id', idNegocio);
  }

  // Actualiza el perfil del negocio (nombre y descripción)
  Future<void> actualizarPerfilNegocio(
    String idNegocio,
    String nombre,
    String descripcion,
  ) async {
    await _supabase
        .from('negocios')
        .update({'nombre': nombre, 'descripcion': descripcion})
        .eq('id', idNegocio);
  }
}
