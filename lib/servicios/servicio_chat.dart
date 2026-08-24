import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../nucleo/constantes/entorno.dart';

final proveedorServicioChat = Provider<ServicioChat>((ref) {
  return ServicioChat(supabaseUrl: Entorno.supabaseUrl);
});

class ServicioChat {
  final String _supabaseUrl;

  ServicioChat({required String supabaseUrl}) : _supabaseUrl = supabaseUrl;

  /// Envía un mensaje a la Edge Function chat-ventas en Supabase.
  ///
  /// [pregunta] es el mensaje del usuario.
  /// [idNegocio] identifica el negocio para consultar sus productos.
  Future<Map<String, dynamic>> enviarMensaje({
    required String pregunta,
    required String idNegocio,
    required String idConversacion,
  }) async {
    final response = await http.post(
      Uri.parse('$_supabaseUrl/functions/v1/chat-ventas'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "pregunta": pregunta,
        "id_negocio": idNegocio,
        "id_conversacion": idConversacion,
      }),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return {
        'respuesta': jsonResponse['respuesta'] ?? '',
      };
    } else {
      final jsonResponse = jsonDecode(response.body);
      throw Exception(jsonResponse['error'] ?? 'Error desconocido');
    }
  }
}
