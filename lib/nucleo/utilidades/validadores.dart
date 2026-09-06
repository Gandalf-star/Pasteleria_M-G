/// Validaciones de formulario compartidas.
///
/// El registro fallaba con `AuthApiException: Unable to validate email address:
/// invalid format` porque la app solo comprobaba que el texto tuviera una `@`.
/// Correos como `luis@gmail` o `josé@correo.com` pasaban esa comprobación y
/// Supabase los rechazaba después, con un mensaje técnico y sin señalar el
/// campo. Aquí validamos con las mismas reglas que aplica el servidor, para
/// avisar antes de la llamada de red.
class Validadores {
  const Validadores._();

  /// Sintaxis aceptada por GoTrue: ASCII, dominio con al menos un punto y una
  /// terminación de dos letras o más.
  static final RegExp _patronCorreo = RegExp(
    r"^[A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+"
    r'@'
    r'[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?'
    r'(\.[A-Za-z0-9]([A-Za-z0-9-]*[A-Za-z0-9])?)*'
    r'\.[A-Za-z]{2,}$',
  );

  /// Deja el correo como lo guarda Supabase: sin espacios y en minúsculas.
  /// Sin esto, `Luis@Gmail.com ` y `luis@gmail.com` parecerían cuentas
  /// distintas al iniciar sesión.
  static String normalizarCorreo(String valor) => valor.trim().toLowerCase();

  /// Devuelve `null` si el correo es válido, o el motivo concreto del fallo.
  static String? correo(String? valor) {
    final texto = (valor ?? '').trim();

    if (texto.isEmpty) return 'Requerido';
    if (texto.length > 254) return 'El correo es demasiado largo';

    if (texto.contains(' ')) return 'El correo no puede llevar espacios';

    final arrobas = '@'.allMatches(texto).length;
    if (arrobas == 0) return 'Falta la arroba (@)';
    if (arrobas > 1) return 'El correo solo puede llevar una arroba';

    final partes = texto.split('@');
    final usuario = partes.first;
    final dominio = partes.last;

    if (usuario.isEmpty) return 'Falta el nombre antes de la arroba';
    if (dominio.isEmpty) return 'Falta el dominio después de la arroba';

    if (!dominio.contains('.')) {
      return 'Al dominio le falta la terminación, por ejemplo .com';
    }
    if (texto.contains('..')) return 'El correo tiene dos puntos seguidos';
    if (usuario.startsWith('.') || usuario.endsWith('.')) {
      return 'El nombre no puede empezar ni terminar con un punto';
    }

    if (!_patronCorreo.hasMatch(texto)) {
      // Caso típico: tildes o eñes, que Supabase rechaza.
      if (RegExp(r'[^\x00-\x7F]').hasMatch(texto)) {
        return 'El correo no puede llevar tildes ni eñes';
      }
      return 'El correo no tiene un formato válido';
    }

    return null;
  }

  /// Contraseña mínima exigida por Supabase Auth.
  static String? contrasena(String? valor) {
    final texto = valor ?? '';
    if (texto.isEmpty) return 'Requerido';
    if (texto.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  /// Campo de texto obligatorio.
  static String? requerido(String? valor) =>
      (valor ?? '').trim().isEmpty ? 'Requerido' : null;
}
