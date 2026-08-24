import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../servicios/servicio_chat.dart';

const String idNegocioDemo = '00000000-0000-0000-0000-000000000000'; // Requiere un UUID válido en tu BD

class PantallaChat extends ConsumerStatefulWidget {
  final String idNegocio;
  final String idConversacion;
  final bool esAdmin;

  const PantallaChat({
    super.key,
    required this.idNegocio,
    required this.idConversacion,
    this.esAdmin = false,
  });

  @override
  ConsumerState<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends ConsumerState<PantallaChat> {
  final _controladorTexto = TextEditingController();
  final _controladorScroll = ScrollController();
  bool _enviandoMensaje = false;
  late final Stream<List<Map<String, dynamic>>> _mensajesStream;

  @override
  void initState() {
    super.initState();
    final supabase = ref.read(supabaseProveedor);
    _mensajesStream = supabase
        .from('mensajes_chat')
        .stream(primaryKey: ['id'])
        .eq('id_conversacion', widget.idConversacion)
        .order('fecha_creacion', ascending: true);
  }

  @override
  void dispose() {
    _controladorTexto.dispose();
    _controladorScroll.dispose();
    super.dispose();
  }

  void _hacerScrollAlFinal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controladorScroll.hasClients) {
        _controladorScroll.animateTo(
          _controladorScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _confirmarPago() async {
    final supabase = ref.read(supabaseProveedor);
    try {
      // Asegurar que la conversación exista
      final conversacionResult = await supabase
          .from('conversaciones')
          .select('id')
          .eq('id', widget.idConversacion)
          .maybeSingle();

      if (conversacionResult == null) {
        await supabase.from('conversaciones').insert({
          'id': widget.idConversacion,
          'id_negocio': widget.idNegocio,
          'id_cliente': supabase.auth.currentUser?.id ?? 'anonimo',
          'ia_pausada': false,
          'estado_pedido': 'pagado'
        });
      } else {
        await supabase.from('conversaciones').update({
          'estado_pedido': 'pagado'
        }).eq('id', widget.idConversacion);
      }

      await supabase.from('mensajes_chat').insert({
        'id_negocio': widget.idNegocio,
        'id_conversacion': widget.idConversacion,
        'enviado_por': 'humano',
        'contenido': '¡Tu pago ha sido confirmado exitosamente! Estamos procesando tu pedido.',
        'es_imagen': false,
      });

      // Enviar a WhatsApp
      final negocioRes = await supabase.from('negocios').select('telefono').eq('id', widget.idNegocio).maybeSingle();
      final telefonoDb = negocioRes?['telefono'] as String? ?? '';
      final telefonoLimpio = telefonoDb.replaceAll(RegExp(r'[^\d]'), '');
      
      final text = Uri.encodeComponent('Hola, acabo de confirmar el pago de mi pedido. El ID de mi conversación es: ${widget.idConversacion}');
      final url = Uri.parse('whatsapp://send?phone=$telefonoLimpio&text=$text');
      
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback a web si no tiene WhatsApp instalado
        final webUrl = Uri.parse('https://wa.me/$telefonoLimpio?text=$text');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl);
        }
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pago confirmado y chat reiniciado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar pago: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _subirImagenPago() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile == null) return;

    setState(() => _enviandoMensaje = true);

    try {
      final supabase = ref.read(supabaseProveedor);
      final archivo = File(pickedFile.path);
      final nombreArchivo = '${widget.idConversacion}/${const Uuid().v4()}.jpg';

      // Subir imagen al bucket pagos
      await supabase.storage.from('pagos').upload(nombreArchivo, archivo);
      final urlPublica = supabase.storage.from('pagos').getPublicUrl(nombreArchivo);

      // Asegurar que la conversación exista
      final conversacionResult = await supabase
          .from('conversaciones')
          .select('id')
          .eq('id', widget.idConversacion)
          .maybeSingle();

      if (conversacionResult == null) {
        await supabase.from('conversaciones').insert({
          'id': widget.idConversacion,
          'id_negocio': widget.idNegocio,
          'id_cliente': supabase.auth.currentUser?.id ?? 'anonimo',
          'ia_pausada': false,
          'estado_pedido': 'pendiente'
        });
      }

      // Guardar mensaje de tipo imagen
      await supabase.from('mensajes_chat').insert({
        'id_negocio': widget.idNegocio,
        'id_conversacion': widget.idConversacion,
        'enviado_por': 'cliente',
        'contenido': urlPublica,
        'es_imagen': true,
      });

      _hacerScrollAlFinal();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _enviandoMensaje = false);
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _controladorTexto.text.trim();
    if (texto.isEmpty) return;

    setState(() {
      _enviandoMensaje = true;
    });

    _controladorTexto.clear();
    final supabase = ref.read(supabaseProveedor);
    final servicioChat = ref.read(proveedorServicioChat);

    try {
      // 1. Asegurar que la conversación exista
      final conversacionResult = await supabase
          .from('conversaciones')
          .select('ia_pausada, estado_pedido')
          .eq('id', widget.idConversacion)
          .maybeSingle();

      bool iaPausada = false;

      if (conversacionResult == null) {
        // Crear la conversación si no existe
        await supabase.from('conversaciones').insert({
          'id': widget.idConversacion,
          'id_negocio': widget.idNegocio,
          'id_cliente': supabase.auth.currentUser?.id ?? 'anonimo',
          'ia_pausada': false,
          'estado_pedido': 'pendiente'
        });
      } else {
        iaPausada = conversacionResult['ia_pausada'] ?? false;
      }

      // 2. Guardar mensaje del cliente en Supabase
      await supabase.from('mensajes_chat').insert({
        'id_negocio': widget.idNegocio,
        'id_conversacion': widget.idConversacion,
        'enviado_por': 'cliente',
        'contenido': texto,
        'es_imagen': false,
      });

      // 3. Si la IA no está pausada, llamar a la Edge Function
      if (!iaPausada) {
        final respuestaChat = await servicioChat.enviarMensaje(
          pregunta: texto,
          idNegocio: widget.idNegocio,
          idConversacion: widget.idConversacion,
        );

        // 4. Guardar respuesta de la IA en Supabase
        await supabase.from('mensajes_chat').insert({
          'id_negocio': widget.idNegocio,
          'id_conversacion': widget.idConversacion,
          'enviado_por': 'ia',
          'contenido': respuestaChat['respuesta'],
          'es_imagen': false,
        });
      }
    } catch (e) {
      // Mostrar error como burbuja de chat en vez de SnackBar
      if (mounted) {
        await supabase.from('mensajes_chat').insert({
          'id_negocio': widget.idNegocio,
          'id_conversacion': widget.idConversacion,
          'enviado_por': 'ia',
          'contenido': 'Error (debug): $e',
          'es_imagen': false,
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _enviandoMensaje = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = ref.watch(supabaseProveedor);
    final tema = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: tema.colorScheme.surface.withValues(alpha: 0.65),
              elevation: 0,
              centerTitle: true,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tema.colorScheme.primary, tema.colorScheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tema.colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente M&G',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: tema.colorScheme.onSurface,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'En línea',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                if (widget.esAdmin)
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: supabase
                        .from('conversaciones')
                        .stream(primaryKey: ['id'])
                        .eq('id', widget.idConversacion),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                      final conversacion = snapshot.data!.first;
                      final esperandoPago = conversacion['estado_pedido'] == 'esperando_pago';
                      
                      if (esperandoPago) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Confirmar Pago'),
                            onPressed: _confirmarPago,
                          ).animate().scale(curve: Curves.easeOutBack, duration: 400.ms),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              tema.colorScheme.surface,
              tema.colorScheme.surfaceContainerLow,
            ],
          ),
        ),
        child: Column(
          children: [
            // Área de Mensajes con StreamBuilder
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _mensajesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final mensajes = snapshot.data ?? [];
                  
                  // Hacemos scroll abajo cuando llegan mensajes nuevos
                  WidgetsBinding.instance.addPostFrameCallback((_) => _hacerScrollAlFinal());

                  return ListView.builder(
                    controller: _controladorScroll,
                    padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 80, 16, 16),
                    itemCount: mensajes.length,
                    itemBuilder: (context, index) {
                      final msg = mensajes[index];
                      final esCliente = msg['enviado_por'] == 'cliente';
                      final esHumano = msg['enviado_por'] == 'humano';
                      final esImagen = msg['es_imagen'] ?? false;

                      return BurbujaMensaje(
                        contenido: msg['contenido'],
                        esCliente: esCliente,
                        esHumano: esHumano,
                        esImagen: esImagen,
                      ).animate().slideY(begin: 0.1, duration: 400.ms, curve: Curves.easeOutCubic).fadeIn();
                    },
                  );
                },
              ),
            ),

            // Indicador de escribiendo
            if (_enviandoMensaje)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: tema.colorScheme.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Escribiendo...',
                        style: GoogleFonts.inter(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(duration: 600.ms),
                    ],
                  ),
                ),
              ),

            // Área de Entrada de Texto
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surface.withValues(alpha: 0.7),
                    border: Border(top: BorderSide(color: tema.colorScheme.outlineVariant.withValues(alpha: 0.2))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        if (!widget.esAdmin)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: tema.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(Icons.add_photo_alternate_rounded, color: tema.colorScheme.primary),
                              onPressed: _enviandoMensaje ? null : _subirImagenPago,
                              tooltip: 'Enviar comprobante',
                            ),
                          ),
                        Expanded(
                          child: TextField(
                            controller: _controladorTexto,
                            style: GoogleFonts.inter(),
                            decoration: InputDecoration(
                              hintText: 'Escribe un mensaje...',
                              hintStyle: GoogleFonts.inter(color: tema.colorScheme.onSurfaceVariant),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: tema.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            onSubmitted: (_) => _enviarMensaje(),
                            textInputAction: TextInputAction.send,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [tema.colorScheme.primary, tema.colorScheme.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tema.colorScheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send_rounded, color: Colors.white),
                            onPressed: _enviandoMensaje ? null : _enviarMensaje,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().slideY(begin: 0.5, duration: 600.ms, curve: Curves.easeOut).fadeIn(),
          ],
        ),
      ),
    );
  }
}

class BurbujaMensaje extends StatelessWidget {
  final String contenido;
  final bool esCliente;
  final bool esHumano;
  final bool esImagen;

  const BurbujaMensaje({
    super.key,
    required this.contenido,
    required this.esCliente,
    this.esHumano = false,
    this.esImagen = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: esCliente ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esCliente) ...[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    esHumano ? tema.colorScheme.secondary : tema.colorScheme.tertiary,
                    esHumano ? tema.colorScheme.secondaryContainer : tema.colorScheme.tertiaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: Colors.transparent,
                child: Icon(
                  esHumano ? Icons.support_agent_rounded : Icons.smart_toy_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(esImagen ? 4 : 14),
              decoration: BoxDecoration(
                gradient: esCliente
                    ? LinearGradient(
                        colors: [
                          tema.colorScheme.primary,
                          tema.colorScheme.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: esCliente ? null : tema.colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(esCliente ? 20 : 6),
                  bottomRight: Radius.circular(esCliente ? 6 : 20),
                ),
                border: !esCliente ? Border.all(color: tema.colorScheme.outlineVariant.withValues(alpha: 0.2)) : null,
                boxShadow: [
                  BoxShadow(
                    color: esCliente 
                        ? tema.colorScheme.primary.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.04),
                    offset: const Offset(0, 4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: esImagen
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      contenido,
                      width: 220,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: 220,
                          height: 220,
                          color: tema.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: CircularProgressIndicator(color: tema.colorScheme.primary),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Icon(Icons.broken_image_rounded, color: tema.colorScheme.onSurfaceVariant, size: 32),
                            const SizedBox(height: 8),
                            Text('Imagen no disponible', style: TextStyle(color: tema.colorScheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ),
                  )
                : Text(
                    contenido,
                    style: GoogleFonts.inter(
                      color: esCliente ? Colors.white : tema.colorScheme.onSurface,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
            ),
          ),
          if (esCliente) const SizedBox(width: 32),
        ],
      ),
    );
  }
}
