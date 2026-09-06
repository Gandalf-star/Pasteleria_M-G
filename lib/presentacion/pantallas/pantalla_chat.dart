import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../nucleo/tema/tokens_app.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../repositorios/repositorio_almacenamiento.dart';
import '../../servicios/servicio_chat.dart';
import '../widgets/componentes.dart';

const String idNegocioDemo =
    '00000000-0000-0000-0000-000000000000'; // Requiere un UUID válido en tu BD

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
          'estado_pedido': 'pagado',
        });
      } else {
        await supabase
            .from('conversaciones')
            .update({'estado_pedido': 'pagado'})
            .eq('id', widget.idConversacion);
      }

      await supabase.from('mensajes_chat').insert({
        'id_negocio': widget.idNegocio,
        'id_conversacion': widget.idConversacion,
        'enviado_por': 'humano',
        'contenido':
            '¡Tu pago ha sido confirmado exitosamente! Estamos procesando tu pedido.',
        'es_imagen': false,
      });

      // Enviar a WhatsApp
      final negocioRes = await supabase
          .from('negocios')
          .select('telefono')
          .eq('id', widget.idNegocio)
          .maybeSingle();
      final telefonoDb = negocioRes?['telefono'] as String? ?? '';
      final telefonoLimpio = telefonoDb.replaceAll(RegExp(r'[^\d]'), '');

      final text = Uri.encodeComponent(
        'Hola, acabo de confirmar el pago de mi pedido. El ID de mi conversación es: ${widget.idConversacion}',
      );
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
        Avisos.exito(context, 'Pago confirmado y chat reiniciado');
      }
    } catch (e) {
      if (mounted) Avisos.error(context, 'Error al confirmar pago: $e');
    }
  }

  Future<void> _subirImagenPago() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile == null) return;

    setState(() => _enviandoMensaje = true);

    try {
      final supabase = ref.read(supabaseProveedor);
      final repoAlmacenamiento = ref.read(proveedorRepositorioAlmacenamiento);

      // Subir imagen al bucket pagos (bytes, compatible con Web y móvil)
      final urlPublica = await repoAlmacenamiento.subirComprobantePago(
        pickedFile,
        widget.idConversacion,
      );

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
          'estado_pedido': 'pendiente',
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
      if (mounted) Avisos.error(context, 'Error al subir imagen: $e');
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
          'estado_pedido': 'pendiente',
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

    return Scaffold(
      backgroundColor: Tokens.lienzo,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(76),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                color: Tokens.lienzo.withValues(alpha: 0.82),
                border: const Border(
                  bottom: BorderSide(color: Tokens.linea),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: 76,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.e4,
                    ),
                    child: Row(
                      children: [
                        BotonCircular(
                          icono: Icons.arrow_back_rounded,
                          tooltip: 'Volver',
                          alPresionar: () => Navigator.maybePop(context),
                        ),
                        const SizedBox(width: Tokens.e3),
                        const _InsigniaAsistente(),
                        const SizedBox(width: Tokens.e3),
                        const Expanded(child: _TituloAsistente()),
                        if (widget.esAdmin)
                          StreamBuilder<List<Map<String, dynamic>>>(
                            stream: supabase
                                .from('conversaciones')
                                .stream(primaryKey: ['id'])
                                .eq('id', widget.idConversacion),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final conversacion = snapshot.data!.first;
                              final esperandoPago =
                                  conversacion['estado_pedido'] ==
                                  'esperando_pago';

                              if (!esperandoPago) return const SizedBox.shrink();

                              return SizedBox(
                                width: 150,
                                child: BotonPrincipal(
                                  texto: 'Confirmar pago',
                                  altura: 42,
                                  colorHalo: Tokens.exito,
                                  degradado: const LinearGradient(
                                    colors: [
                                      Color(0xFF7FB894),
                                      Color(0xFF5C8471),
                                    ],
                                  ),
                                  alPresionar: _confirmarPago,
                                ),
                              ).animate().scale(
                                curve: Curves.easeOutBack,
                                duration: 400.ms,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Mensajes ─────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _mensajesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Cargando(mensaje: 'Abriendo la conversación…');
                }
                if (snapshot.hasError) {
                  return EstadoVacio(
                    icono: Icons.cloud_off_rounded,
                    titulo: 'No pudimos cargar el chat',
                    mensaje: '${snapshot.error}',
                  );
                }

                final mensajes = snapshot.data ?? [];

                // Hacemos scroll abajo cuando llegan mensajes nuevos
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => _hacerScrollAlFinal(),
                );

                final relleno = EdgeInsets.fromLTRB(
                  Tokens.e5,
                  MediaQuery.of(context).padding.top + 96,
                  Tokens.e5,
                  Tokens.e5,
                );

                if (mensajes.isEmpty) {
                  return ListView(
                    controller: _controladorScroll,
                    padding: relleno,
                    children: const [_Bienvenida()],
                  );
                }

                return ListView.builder(
                  controller: _controladorScroll,
                  padding: relleno,
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
                    ).animate().fadeIn(duration: 320.ms).slideY(
                      begin: 0.12,
                      curve: Curves.easeOutCubic,
                    );
                  },
                );
              },
            ),
          ),

          // ── Indicador de escritura ───────────────────────────
          if (_enviandoMensaje)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Tokens.e6,
                0,
                Tokens.e6,
                Tokens.e2,
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: Tokens.e3),
                  Text(
                        'El asistente está escribiendo…',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                      .animate(
                        onPlay: (controller) => controller.repeat(reverse: true),
                      )
                      .fade(duration: 700.ms, begin: 0.45),
                ],
              ),
            ),

          // ── Redacción ────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Tokens.superficie,
              border: Border(top: BorderSide(color: Tokens.linea)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.e4,
                  Tokens.e3,
                  Tokens.e4,
                  Tokens.e3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (!widget.esAdmin) ...[
                      BotonCircular(
                        icono: Icons.attach_file_rounded,
                        tooltip: 'Enviar comprobante',
                        alPresionar: _enviandoMensaje ? null : _subirImagenPago,
                      ),
                      const SizedBox(width: Tokens.e3),
                    ],
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _controladorTexto,
                          minLines: 1,
                          maxLines: 4,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Tokens.tinta),
                          decoration: InputDecoration(
                            hintText: 'Escribe tu mensaje…',
                            filled: true,
                            fillColor: Tokens.superficieSuave,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: Tokens.e5,
                              vertical: Tokens.e3 + 2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Tokens.radioLg,
                              ),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Tokens.radioLg,
                              ),
                              borderSide: const BorderSide(color: Tokens.linea),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                Tokens.radioLg,
                              ),
                              borderSide: const BorderSide(
                                color: Tokens.rosa,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _enviarMensaje(),
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                    ),
                    const SizedBox(width: Tokens.e3),
                    _BotonEnviar(
                      habilitado: !_enviandoMensaje,
                      alPresionar: _enviarMensaje,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Cabecera ───────────────────────────

class _InsigniaAsistente extends StatelessWidget {
  const _InsigniaAsistente();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: Tokens.degradadoMarca,
        shape: BoxShape.circle,
        boxShadow: Tokens.haloColor(Tokens.rosa),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}

class _TituloAsistente extends StatelessWidget {
  const _TituloAsistente();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Asistente M&G', style: tema.textTheme.titleLarge),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Tokens.exito,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text('En línea', style: tema.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta introductoria cuando aún no hay mensajes en la conversación.
class _Bienvenida extends StatelessWidget {
  const _Bienvenida();

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return TarjetaSuave(
      padding: const EdgeInsets.all(Tokens.e6),
      sombra: Tokens.sombraMedia,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Antetitulo('Atención al cliente'),
          const SizedBox(height: Tokens.e3),
          Text('¿En qué te ayudamos?', style: tema.textTheme.headlineSmall),
          const SizedBox(height: Tokens.e3),
          Text(
            'Pregúntanos por sabores, tamaños, tiempos de entrega o el estado '
            'de tu pedido. También puedes adjuntar el comprobante de pago con '
            'el clip.',
            style: tema.textTheme.bodyMedium,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms);
  }
}

class _BotonEnviar extends StatelessWidget {
  final bool habilitado;
  final VoidCallback alPresionar;

  const _BotonEnviar({required this.habilitado, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: habilitado ? 1 : 0.5,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: Tokens.degradadoMarca,
          shape: BoxShape.circle,
          boxShadow: habilitado ? Tokens.haloColor(Tokens.rosa) : null,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: habilitado ? alPresionar : null,
            customBorder: const CircleBorder(),
            child: const Icon(
              Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Burbujas ───────────────────────────

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
      padding: const EdgeInsets.only(bottom: Tokens.e4),
      child: Row(
        mainAxisAlignment: esCliente
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!esCliente) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: esHumano ? Tokens.salviaSuave : Tokens.rosaSuave,
                shape: BoxShape.circle,
                border: Border.all(
                  color: (esHumano ? Tokens.salvia : Tokens.rosa).withValues(
                    alpha: 0.25,
                  ),
                ),
              ),
              child: Icon(
                esHumano
                    ? Icons.support_agent_rounded
                    : Icons.auto_awesome_rounded,
                size: 14,
                color: esHumano ? Tokens.salviaProfundo : Tokens.rosaProfundo,
              ),
            ),
            const SizedBox(width: Tokens.e2 + 2),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: EdgeInsets.all(esImagen ? 5 : Tokens.e4),
              decoration: BoxDecoration(
                gradient: esCliente ? Tokens.degradadoMarca : null,
                color: esCliente ? null : Tokens.superficie,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(Tokens.radioMd),
                  topRight: const Radius.circular(Tokens.radioMd),
                  bottomLeft: Radius.circular(esCliente ? Tokens.radioMd : 6),
                  bottomRight: Radius.circular(esCliente ? 6 : Tokens.radioMd),
                ),
                border: esCliente
                    ? null
                    : Border.all(color: Tokens.linea),
                boxShadow: esCliente
                    ? Tokens.haloColor(Tokens.rosa)
                    : Tokens.sombraSuave,
              ),
              child: esImagen
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(Tokens.radioSm),
                      child: Image.network(
                        contenido,
                        width: 230,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Esqueleto(alto: 200, ancho: 230);
                        },
                        errorBuilder: (_, _, _) => Padding(
                          padding: const EdgeInsets.all(Tokens.e6),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.broken_image_outlined,
                                color: Tokens.tintaSuave,
                                size: 28,
                              ),
                              const SizedBox(height: Tokens.e2),
                              Text(
                                'Imagen no disponible',
                                style: tema.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Text(
                      contenido,
                      style: tema.textTheme.bodyLarge?.copyWith(
                        fontSize: 15,
                        height: 1.5,
                        color: esCliente ? Colors.white : Tokens.tinta,
                      ),
                    ),
            ),
          ),
          if (esCliente) const SizedBox(width: Tokens.e6),
        ],
      ),
    );
  }
}
