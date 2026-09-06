import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';

/// Apertura de enlaces externos, con el cuidado que exige la web.
///
/// En iOS/Safari `launchUrl` abre una pestaña nueva mediante `window.open()`,
/// y el navegador solo lo permite mientras dura el gesto del usuario. Como
/// antes de abrir WhatsApp hacemos varias llamadas de red (verificar el
/// cliente, crear la orden, leer el teléfono del negocio), ese permiso ya se
/// perdió y la pestaña se bloqueaba en silencio: el usuario tocaba "Confirmar"
/// y no pasaba nada.
///
/// La solución es navegar en la pestaña actual (`_self`) en lugar de abrir una
/// nueva. Esa navegación no la bloquea ningún navegador, y en iOS el enlace
/// `wa.me` es un universal link, así que abre la app de WhatsApp igualmente.
class Enlaces {
  const Enlaces._();

  /// Construye el enlace `wa.me` a partir de un teléfono en cualquier formato.
  /// Devuelve `null` si el número no tiene dígitos utilizables.
  static Uri? whatsapp({required String telefono, required String mensaje}) {
    final numero = telefono.replaceAll(RegExp(r'[^\d]'), '');
    if (numero.isEmpty) return null;

    return Uri.parse(
      'https://wa.me/$numero?text=${Uri.encodeComponent(mensaje)}',
    );
  }

  /// Abre [uri] fuera de la app. Devuelve `false` si no se pudo abrir, para
  /// que la pantalla ofrezca un botón de reintento (un toque nuevo sí tiene
  /// permiso del navegador).
  ///
  /// No usa `canLaunchUrl`: en web devuelve resultados poco fiables y además
  /// añade otra espera asíncrona, que es justo lo que rompe el permiso.
  static Future<bool> abrir(Uri uri) async {
    try {
      if (kIsWeb) {
        return await launchUrl(uri, webOnlyWindowName: '_self');
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
