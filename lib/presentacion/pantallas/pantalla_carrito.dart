import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../proveedores/proveedor_carrito.dart';
import '../../repositorios/repositorio_ordenes.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../nucleo/constantes/entorno.dart';
import '../../repositorios/repositorio_autenticacion.dart';

class PantallaCarrito extends ConsumerStatefulWidget {
  const PantallaCarrito({super.key});

  @override
  ConsumerState<PantallaCarrito> createState() => _PantallaCarritoState();
}

class _PantallaCarritoState extends ConsumerState<PantallaCarrito> {
  bool _procesando = false;

  Future<void> _confirmarPedido(List<ItemCarrito> items, double total) async {
    if (items.isEmpty) return;

    final repoAuth = ref.read(proveedorRepositorioAutenticacion);
    final esCliente = await repoAuth.esCliente();

    if (!esCliente) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registro Requerido'),
            content: const Text('Debes iniciar sesión o registrarte con una cuenta válida para poder confirmar tu pedido y contactar a la tienda.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/registro_usuario');
                },
                child: const Text('Registrarse / Iniciar Sesión'),
              ),
            ],
          ),
        );
      }
      return;
    }

    setState(() => _procesando = true);

    try {
      final repoOrdenes = ref.read(proveedorRepositorioOrdenes);
      
      // 1. Guardar orden en BD
      final idOrden = await repoOrdenes.crearOrden(items, total);
      
      // 2. Construir mensaje de WhatsApp
      final supabase = ref.read(supabaseProveedor);
      final negocioRes = await supabase.from('negocios').select('telefono').eq('id', Entorno.idSweetBites).maybeSingle();
      final telefonoDb = negocioRes?['telefono'] as String? ?? '';
      final numeroAdmin = telefonoDb.replaceAll(RegExp(r'[^\d]'), '');

      final buffer = StringBuffer();
      buffer.writeln('👋 *¡Hola Pasteleria M&G!*');
      buffer.writeln('Quiero realizar el siguiente pedido:');
      buffer.writeln('');
      buffer.writeln('💳 *Orden ID:* ${idOrden.split('-').first.toUpperCase()}');
      buffer.writeln('\n*Resumen de mi pedido:*');
      
      for (final item in items) {
        final nombre = item.producto['nombre'];
        final precio = double.tryParse(item.producto['precio'].toString()) ?? 0.0;
        buffer.writeln('• ${item.cantidad}x $nombre - \$${(precio * item.cantidad).toStringAsFixed(2)}');
      }
      
      buffer.writeln('\n💰 *Total a pagar:* \$${total.toStringAsFixed(2)}');
      buffer.writeln('\n¡Quedo a la espera de confirmación!');

      final uri = Uri.parse('https://wa.me/$numeroAdmin?text=${Uri.encodeComponent(buffer.toString())}');
      
      // 3. Abrir WhatsApp
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se pudo abrir WhatsApp');
      }

      // 4. Limpiar carrito y cerrar
      ref.read(proveedorCarrito.notifier).limpiarCarrito();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Pedido enviado exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pedido: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final items = ref.watch(proveedorCarrito);
    final total = ref.read(proveedorCarrito.notifier).total;
    final notifier = ref.read(proveedorCarrito.notifier);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mi Carrito', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        backgroundColor: tema.colorScheme.surface,
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_basket_outlined, size: 80, color: tema.colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Tu carrito está vacío',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, color: tema.colorScheme.onSurface),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '¡Agrega algunos postres deliciosos!',
                    style: GoogleFonts.inter(fontSize: 16, color: tema.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Volver al menú'),
                  ),
                ],
              ).animate().fadeIn(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final prod = item.producto;
                      final urlImagen = prod['url_imagen'] as String?;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                              child: urlImagen != null && urlImagen.isNotEmpty
                                  ? Image.network(urlImagen, width: 100, height: 100, fit: BoxFit.cover)
                                  : Container(
                                      width: 100,
                                      height: 100,
                                      color: tema.colorScheme.primaryContainer,
                                      child: Icon(Icons.cake, color: tema.colorScheme.primary),
                                    ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      prod['nombre'],
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '\$${item.subtotal.toStringAsFixed(2)}',
                                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: tema.colorScheme.primary),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        _BotonCantidad(
                                          icono: Icons.remove,
                                          onTap: () => notifier.reducirCantidad(prod['id']),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            '${item.cantidad}',
                                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                                          ),
                                        ),
                                        _BotonCantidad(
                                          icono: Icons.add,
                                          onTap: () => notifier.agregarProducto(prod),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          onPressed: () => notifier.eliminarProducto(prod['id']),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().slideX(begin: 0.2, duration: 400.ms, delay: (index * 50).ms).fadeIn();
                    },
                  ),
                ),
                // Resumen
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: tema.colorScheme.surface.withAlpha(220),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(20),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          )
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total a pagar', style: GoogleFonts.inter(fontSize: 18, color: tema.colorScheme.onSurfaceVariant)),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: tema.colorScheme.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: _procesando ? null : () => _confirmarPedido(items, total),
                                icon: _procesando 
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : const Icon(Icons.send_rounded),
                                label: Text(
                                  _procesando ? 'Procesando...' : 'Confirmar por WhatsApp',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366), // Color de WhatsApp
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().slideY(begin: 1, duration: 600.ms, curve: Curves.easeOutBack),
              ],
            ),
    );
  }
}

class _BotonCantidad extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;

  const _BotonCantidad({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icono, size: 18, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
