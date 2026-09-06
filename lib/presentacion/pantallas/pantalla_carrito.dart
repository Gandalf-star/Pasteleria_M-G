import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nucleo/constantes/entorno.dart';
import '../../nucleo/tema/tokens_app.dart';
import '../../nucleo/utilidades/enlaces.dart';
import '../../proveedores/proveedor_carrito.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../repositorios/repositorio_autenticacion.dart';
import '../../repositorios/repositorio_ordenes.dart';
import '../widgets/componentes.dart';

class PantallaCarrito extends ConsumerStatefulWidget {
  const PantallaCarrito({super.key});

  @override
  ConsumerState<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends ConsumerState<PantallaCarrito> {
  bool _procesando = false;

  /// Teléfono del negocio, cargado al entrar a la pantalla para no tener que
  /// consultarlo justo antes de abrir WhatsApp.
  String? _telefonoNegocio;

  @override
  void initState() {
    super.initState();
    _cargarTelefonoNegocio();
  }

  Future<void> _cargarTelefonoNegocio() async {
    try {
      final res = await ref
          .read(supabaseProveedor)
          .from('negocios')
          .select('telefono')
          .eq('id', Entorno.idSweetBites)
          .maybeSingle();
      if (mounted) {
        setState(() => _telefonoNegocio = res?['telefono'] as String? ?? '');
      }
    } catch (e) {
      debugPrint('Error cargando el teléfono del negocio: $e');
    }
  }

  /// Diálogo de registro requerido, compartido por ambos flujos de pedido.
  Future<bool> _verificarCliente(String motivo) async {
    final repoAuth = ref.read(proveedorRepositorioAutenticacion);
    final esCliente = await repoAuth.esCliente();
    if (esCliente) return true;

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.lock_outline_rounded,
            color: Tokens.rosa,
            size: 28,
          ),
          title: const Text('Necesitas una cuenta'),
          content: Text(motivo),
          actionsPadding: const EdgeInsets.fromLTRB(
            Tokens.e5,
            0,
            Tokens.e5,
            Tokens.e5,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/registro_usuario');
              },
              child: const Text('Crear cuenta'),
            ),
          ],
        ),
      );
    }
    return false;
  }

  /// Abre WhatsApp con el mensaje ya redactado.
  ///
  /// Si el navegador impide la apertura automática, en lugar de fallar en
  /// silencio mostramos un diálogo con un botón: ese toque es un gesto nuevo
  /// del usuario y sí tiene permiso para navegar.
  Future<void> _abrirWhatsapp(String mensaje) async {
    var telefono = _telefonoNegocio;
    if (telefono == null || telefono.isEmpty) {
      final res = await ref
          .read(supabaseProveedor)
          .from('negocios')
          .select('telefono')
          .eq('id', Entorno.idSweetBites)
          .maybeSingle();
      telefono = res?['telefono'] as String? ?? '';
    }

    final uri = Enlaces.whatsapp(telefono: telefono, mensaje: mensaje);
    if (uri == null) {
      throw Exception(
        'El negocio no tiene un número de WhatsApp configurado.',
      );
    }

    final abierto = await Enlaces.abrir(uri);
    if (!abierto && mounted) {
      await _ofrecerAperturaManual(uri);
    }
  }

  /// Último recurso: el usuario abre WhatsApp con un toque explícito.
  Future<void> _ofrecerAperturaManual(Uri uri) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.open_in_new_rounded,
          color: Tokens.whatsapp,
          size: 28,
        ),
        title: const Text('Abre WhatsApp para enviarlo'),
        content: const Text(
          'Tu pedido quedó registrado. Toca el botón para enviarnos el '
          'resumen por WhatsApp.',
          textAlign: TextAlign.center,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          Tokens.e5,
          0,
          Tokens.e5,
          Tokens.e5,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Tokens.whatsapp,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
              label: const Text('Abrir WhatsApp'),
              onPressed: () {
                Navigator.pop(context);
                Enlaces.abrir(uri);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _detalleItems(List<ItemCarrito> items) {
    final buffer = StringBuffer();
    for (final item in items) {
      final nombre = item.producto['nombre'];
      final precio =
          double.tryParse(item.producto['precio'].toString()) ?? 0.0;
      buffer.writeln(
        '• ${item.cantidad}x $nombre - \$${(precio * item.cantidad).toStringAsFixed(2)}',
      );
    }
    return buffer.toString();
  }

  Future<void> _confirmarPedido(List<ItemCarrito> items, double total) async {
    if (items.isEmpty) return;

    final autorizado = await _verificarCliente(
      'Inicia sesión o regístrate para confirmar tu pedido y contactar a la tienda.',
    );
    if (!autorizado) return;

    setState(() => _procesando = true);

    try {
      final repoOrdenes = ref.read(proveedorRepositorioOrdenes);

      // 1. Guardar orden en BD
      final idOrden = await repoOrdenes.crearOrden(items, total);

      // 2. Construir mensaje de WhatsApp
      final buffer = StringBuffer();
      buffer.writeln('👋 *¡Hola Pasteleria M&G!*');
      buffer.writeln('Quiero realizar el siguiente pedido:');
      buffer.writeln('');
      buffer.writeln(
        '💳 *Orden ID:* ${idOrden.split('-').first.toUpperCase()}',
      );
      buffer.writeln('\n*Resumen de mi pedido:*');
      buffer.write(_detalleItems(items));
      buffer.writeln('\n💰 *Total a pagar:* \$${total.toStringAsFixed(2)}');
      buffer.writeln('\n¡Quedo a la espera de confirmación!');

      // 3. Abrir WhatsApp
      await _abrirWhatsapp(buffer.toString());

      // 4. Limpiar carrito y cerrar
      ref.read(proveedorCarrito.notifier).limpiarCarrito();
      if (mounted) {
        Navigator.pop(context);
        Avisos.exito(context, '¡Pedido enviado exitosamente!');
      }
    } catch (e) {
      if (mounted) Avisos.error(context, 'Error al procesar el pedido: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  Future<void> _confirmarPedidoFinanciado(
    List<ItemCarrito> items,
    double total,
  ) async {
    if (items.isEmpty) return;

    final autorizado = await _verificarCliente(
      'Inicia sesión o regístrate para solicitar financiamiento con el Club M&G.',
    );
    if (!autorizado) return;

    setState(() => _procesando = true);

    try {
      final repoOrdenes = ref.read(proveedorRepositorioOrdenes);

      // 1. Guardar orden en BD
      final idOrden = await repoOrdenes.crearOrden(
        items,
        total,
        esFinanciamiento: true,
      );

      // 2. Construir mensaje de WhatsApp para Financiamiento
      final cuota = (total / 3).toStringAsFixed(2);

      final buffer = StringBuffer();
      buffer.writeln('🌟 *¡Hola Pasteleria M&G!*');
      buffer.writeln(
        'Quiero solicitar financiamiento con el *Club M&G* para este pedido:',
      );
      buffer.writeln('');
      buffer.writeln(
        '💳 *Orden ID:* ${idOrden.split('-').first.toUpperCase()}',
      );
      buffer.writeln('\n*Resumen de mi pedido:*');
      buffer.write(_detalleItems(items));
      buffer.writeln('\n💰 *Total:* \$${total.toStringAsFixed(2)}');
      buffer.writeln(
        '🍰 *Plan Sugerido:* 1 pago inicial de \$$cuota y 2 cuotas de \$$cuota',
      );
      buffer.writeln('\n¡Quedo a la espera de aprobación!');

      // 3. Abrir WhatsApp
      await _abrirWhatsapp(buffer.toString());

      // 4. Limpiar carrito y cerrar
      ref.read(proveedorCarrito.notifier).limpiarCarrito();
      if (mounted) {
        Navigator.pop(context);
        Avisos.atencion(context, '¡Solicitud de financiamiento enviada!');
      }
    } catch (e) {
      if (mounted) Avisos.error(context, 'Error al procesar la solicitud: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final items = ref.watch(proveedorCarrito);
    final total = items.fold(0.0, (sum, item) => sum + item.subtotal);
    final unidades = items.fold(0, (sum, item) => sum + item.cantidad);
    final notifier = ref.read(proveedorCarrito.notifier);

    return Scaffold(
      body: FondoAtelier(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Cabecera ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.e5,
                  Tokens.e3,
                  Tokens.e5,
                  Tokens.e4,
                ),
                child: Row(
                  children: [
                    BotonCircular(
                      icono: Icons.arrow_back_rounded,
                      tooltip: 'Volver',
                      alPresionar: () => Navigator.maybePop(context),
                    ),
                    const SizedBox(width: Tokens.e4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Antetitulo('Tu pedido'),
                          Text('Mi carrito', style: tema.textTheme.headlineSmall),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      Pildora(
                        texto: unidades == 1
                            ? '1 artículo'
                            : '$unidades artículos',
                        color: Tokens.tintaMedia,
                      ),
                  ],
                ),
              ),

              Expanded(
                child: items.isEmpty
                    ? EstadoVacio(
                        icono: Icons.shopping_bag_outlined,
                        titulo: 'Tu carrito está vacío',
                        mensaje:
                            'Explora la carta y añade las piezas que quieras '
                            'llevarte hoy.',
                        accion: SizedBox(
                          width: 220,
                          child: BotonPrincipal(
                            texto: 'Ver la carta',
                            icono: Icons.restaurant_menu_rounded,
                            altura: 50,
                            alPresionar: () => Navigator.pop(context),
                          ),
                        ),
                      ).animate().fadeIn()
                    : ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          Tokens.e5,
                          0,
                          Tokens.e5,
                          Tokens.e6,
                        ),
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: Tokens.e3),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _FilaItem(
                                item: item,
                                alSumar: () =>
                                    notifier.agregarProducto(item.producto),
                                alRestar: () => notifier.reducirCantidad(
                                  item.producto['id'],
                                ),
                                alEliminar: () => notifier.eliminarProducto(
                                  item.producto['id'],
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: 350.ms,
                                delay: (index.clamp(0, 8) * 45).ms,
                              )
                              .slideY(begin: 0.08, curve: Curves.easeOutCubic);
                        },
                      ),
              ),

              // ── Resumen y acciones ───────────────────────────
              if (items.isNotEmpty)
                _PanelResumen(
                  total: total,
                  procesando: _procesando,
                  alConfirmar: () => _confirmarPedido(items, total),
                  alFinanciar: total >= 5.0
                      ? () => _confirmarPedidoFinanciado(items, total)
                      : null,
                ).animate().slideY(
                  begin: 0.4,
                  duration: 450.ms,
                  curve: Curves.easeOutCubic,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Item del carrito ───────────────────────────

class _FilaItem extends StatelessWidget {
  final ItemCarrito item;
  final VoidCallback alSumar;
  final VoidCallback alRestar;
  final VoidCallback alEliminar;

  const _FilaItem({
    required this.item,
    required this.alSumar,
    required this.alRestar,
    required this.alEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final prod = item.producto;
    final urlImagen = prod['url_imagen'] as String?;

    return TarjetaSuave(
      padding: const EdgeInsets.all(Tokens.e3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radioSm),
            child: SizedBox(
              width: 86,
              height: 86,
              child: urlImagen != null && urlImagen.isNotEmpty
                  ? Image.network(
                      urlImagen,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _MiniaturaAusente(),
                    )
                  : const _MiniaturaAusente(),
            ),
          ),
          const SizedBox(width: Tokens.e4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        prod['nombre'] ?? 'Producto',
                        style: tema.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: alEliminar,
                      borderRadius: BorderRadius.circular(Tokens.radioXs),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 17,
                          color: Tokens.tintaSuave,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${item.subtotal.toStringAsFixed(2)}',
                  style: tema.textTheme.titleLarge?.copyWith(
                    color: Tokens.rosaProfundo,
                  ),
                ),
                const SizedBox(height: Tokens.e3),
                _Contador(
                  cantidad: item.cantidad,
                  alSumar: alSumar,
                  alRestar: alRestar,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniaturaAusente extends StatelessWidget {
  const _MiniaturaAusente();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Tokens.rosaVelo,
      alignment: Alignment.center,
      child: const Icon(Icons.cake_rounded, color: Tokens.rosaSuave, size: 26),
    );
  }
}

/// Contador segmentado — / cantidad / +
class _Contador extends StatelessWidget {
  final int cantidad;
  final VoidCallback alSumar;
  final VoidCallback alRestar;

  const _Contador({
    required this.cantidad,
    required this.alSumar,
    required this.alRestar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Tokens.superficieSuave,
        borderRadius: BorderRadius.circular(Tokens.radioPildora),
        border: Border.all(color: Tokens.linea),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BotonPaso(icono: Icons.remove_rounded, alTocar: alRestar),
          SizedBox(
            width: 30,
            child: Text(
              '$cantidad',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          _BotonPaso(icono: Icons.add_rounded, alTocar: alSumar),
        ],
      ),
    );
  }
}

class _BotonPaso extends StatelessWidget {
  final IconData icono;
  final VoidCallback alTocar;

  const _BotonPaso({required this.icono, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTocar,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icono, size: 16, color: Tokens.tinta),
      ),
    );
  }
}

// ─────────────────────────── Resumen ───────────────────────────

class _PanelResumen extends StatelessWidget {
  final double total;
  final bool procesando;
  final VoidCallback alConfirmar;
  final VoidCallback? alFinanciar;

  const _PanelResumen({
    required this.total,
    required this.procesando,
    required this.alConfirmar,
    required this.alFinanciar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Tokens.superficie,
        border: Border(top: BorderSide(color: Tokens.linea)),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Tokens.radioXl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.e6,
            Tokens.e5,
            Tokens.e6,
            Tokens.e4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Antetitulo('Total a pagar'),
                        const SizedBox(height: 2),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: tema.textTheme.displaySmall,
                        ),
                      ],
                    ),
                  ),
                  if (alFinanciar != null)
                    Pildora(
                      texto: '3 x \$${(total / 3).toStringAsFixed(2)}',
                      icono: Icons.workspace_premium_rounded,
                      color: Tokens.arenaProfundo,
                    ),
                ],
              ),
              const SizedBox(height: Tokens.e5),

              BotonPrincipal(
                texto: procesando ? 'Procesando…' : 'Confirmar por WhatsApp',
                icono: Icons.chat_bubble_outline_rounded,
                cargando: procesando,
                colorHalo: Tokens.whatsapp,
                degradado: const LinearGradient(
                  colors: [Color(0xFF4CBB7B), Color(0xFF2F9459)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                alPresionar: procesando ? null : alConfirmar,
              ),

              if (alFinanciar != null) ...[
                const SizedBox(height: Tokens.e3),
                BotonContorno(
                  texto: 'Financiar con Club M&G',
                  icono: Icons.workspace_premium_rounded,
                  color: Tokens.arenaProfundo,
                  colorFondo: Tokens.arenaSuave,
                  alPresionar: procesando ? null : alFinanciar,
                ),
              ],

              const SizedBox(height: Tokens.e3),
              Text(
                'Confirmamos disponibilidad y entrega por WhatsApp.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
