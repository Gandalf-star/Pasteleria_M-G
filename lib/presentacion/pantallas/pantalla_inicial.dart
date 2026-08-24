import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../repositorios/repositorio_productos.dart';
import '../../proveedores/proveedor_carrito.dart';
import 'pantalla_carrito.dart';
import 'pantalla_chat.dart';
import '../../nucleo/constantes/entorno.dart';
import 'package:uuid/uuid.dart';

class PantallaInicial extends ConsumerStatefulWidget {
  const PantallaInicial({super.key});

  @override
  ConsumerState<PantallaInicial> createState() => _PantallaInicialState();
}

class _PantallaInicialState extends ConsumerState<PantallaInicial> {
  String _filtroCategoria = 'Todos';
  String _saludo = 'Buenos días';
  String _nombreUsuario = 'Invitado';

  final List<String> _categorias = ['Todos', 'Pastelería', 'Postres'];

  String? _fotoPerfilUrl;
  String? _idConversacion;
  bool _cargandoChat = false;
  late final Stream<List<Map<String, dynamic>>> _productosStream;

  @override
  void initState() {
    super.initState();
    _determinarSaludo();
    _obtenerNombreUsuario();
    _cargarConversacionActiva();
    _productosStream = ref
        .read(proveedorRepositorioProductos)
        .escucharTodosLosProductos();
  }

  Future<void> _cargarConversacionActiva() async {
    final supabase = ref.read(supabaseProveedor);
    final idCliente = supabase.auth.currentUser?.id ?? 'anonimo';

    try {
      final res = await supabase
          .from('conversaciones')
          .select('id')
          .eq('id_negocio', Entorno.idSweetBites)
          .eq('id_cliente', idCliente)
          .neq('estado_pedido', 'pagado')
          .order('fecha_creacion', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        _idConversacion = res['id'];
      }
    } catch (e) {
      debugPrint('Error cargando conversación activa: $e');
    }
  }

  void _determinarSaludo() {
    final hora = DateTime.now().hour;
    if (hora < 12) {
      _saludo = 'Buenos días';
    } else if (hora < 19) {
      _saludo = 'Buenas tardes';
    } else {
      _saludo = 'Buenas noches';
    }
  }

  Future<void> _obtenerNombreUsuario() async {
    final supabase = ref.read(supabaseProveedor);
    final usuario = supabase.auth.currentUser;
    if (usuario != null) {
      if (mounted) {
        setState(() {
          _nombreUsuario = usuario.userMetadata?['nombre'] ?? 'Invitado';
        });
      }

      // Buscar el nombre y foto en la tabla clientes
      try {
        final cliente = await supabase
            .from('clientes')
            .select('foto_url, nombre')
            .eq('id', usuario.id)
            .maybeSingle();

        if (cliente != null) {
          if (mounted) {
            setState(() {
              if (cliente['nombre'] != null &&
                  cliente['nombre'].toString().isNotEmpty) {
                _nombreUsuario = cliente['nombre'];
              }
              if (cliente['foto_url'] != null &&
                  cliente['foto_url'].toString().isNotEmpty) {
                _fotoPerfilUrl = cliente['foto_url'];
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Error obteniendo datos del cliente: $e');
      }
    }
  }

  String _obtenerIniciales() {
    if (_nombreUsuario.isEmpty || _nombreUsuario == 'Invitado') return 'I';
    final partes = _nombreUsuario.split(' ');
    if (partes.length > 1) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return _nombreUsuario.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final itemsCarrito = ref.watch(proveedorCarrito);
    final cantidadCarrito = itemsCarrito.fold(
      0,
      (sum, item) => sum + item.cantidad,
    );

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: tema.colorScheme.primary),
              accountName: Text(
                _nombreUsuario,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                ref.read(supabaseProveedor).auth.currentUser?.email ?? '',
                style: GoogleFonts.inter(),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: tema.colorScheme.surface,
                backgroundImage: _fotoPerfilUrl != null
                    ? NetworkImage(_fotoPerfilUrl!)
                    : null,
                child: _fotoPerfilUrl == null
                    ? Text(
                        _obtenerIniciales(),
                        style: GoogleFonts.outfit(
                          color: tema.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : null,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Cerrar sesión',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await ref.read(supabaseProveedor).auth.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Cabecera Macaron Theme
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: tema.scaffoldBackgroundColor,
            elevation: 0,
            // Quitamos el title estático para que no se superponga con el contenido
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tema.colorScheme.primaryContainer,
                      tema.colorScheme.tertiaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Título centralizado
                      Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cake_rounded,
                                size: 28,
                                color: tema.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pasteleria M&G',
                                style: GoogleFonts.outfit(
                                  fontSize: 28,
                                  color: tema.colorScheme.primary,
                                  letterSpacing: -0.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .slideY(begin: -0.2, duration: 600.ms)
                          .fadeIn(),
                      const Spacer(),
                      // Tarjeta de bienvenida
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: tema.colorScheme.surface.withAlpha(200),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(10),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: tema.colorScheme.primary,
                              backgroundImage: _fotoPerfilUrl != null
                                  ? NetworkImage(_fotoPerfilUrl!)
                                  : null,
                              child: _fotoPerfilUrl == null
                                  ? Text(
                                      _obtenerIniciales(),
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_saludo,',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: tema.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    _nombreUsuario,
                                    style: GoogleFonts.outfit(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: tema.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(
                        duration: 800.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Container(
                height: 70,
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: BoxDecoration(
                  color: tema.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categorias.length,
                  itemBuilder: (context, index) {
                    final cat = _categorias[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _ChipFiltro(
                        etiqueta: cat,
                        seleccionado: _filtroCategoria == cat,
                        onTap: () => setState(() => _filtroCategoria = cat),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Catálogo de Productos
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _productosStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final productos = snapshot.data ?? [];

              final productosFiltrados = _filtroCategoria == 'Todos'
                  ? productos
                  : productos
                        .where(
                          (p) =>
                              p['categoria']?.toString().toLowerCase() ==
                              _filtroCategoria.toLowerCase(),
                        )
                        .toList();

              if (productosFiltrados.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cookie_outlined,
                          size: 80,
                          color: tema.colorScheme.primary.withAlpha(100),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay postres en esta categoría',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: tema.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final producto = productosFiltrados[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: _TarjetaProductoIrresistible(producto: producto)
                          .animate()
                          .slideY(
                            begin: 0.1,
                            duration: 500.ms,
                            delay: (index * 100).ms,
                          )
                          .fadeIn(),
                    );
                  }, childCount: productosFiltrados.length),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Botón del Chat IA (Siempre visible)
          FloatingActionButton.extended(
            heroTag: 'chat_ia',
            onPressed: () async {
              setState(() => _cargandoChat = true);
              _idConversacion ??= const Uuid().v4();
              setState(() => _cargandoChat = false);

              if (!mounted) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PantallaChat(
                    idNegocio: Entorno.idSweetBites,
                    idConversacion: _idConversacion!,
                  ),
                ),
              );
              _cargarConversacionActiva();
            },
            backgroundColor: tema.colorScheme.tertiary,
            foregroundColor: tema.colorScheme.onTertiary,
            icon: _cargandoChat
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(
              'Atención al Cliente',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

          if (cantidadCarrito > 0) const SizedBox(height: 16),

          // Botón del Carrito (Solo si hay items)
          if (cantidadCarrito > 0)
            FloatingActionButton.extended(
              heroTag: 'carrito',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaCarrito()),
                );
              },
              backgroundColor: tema.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                '$cantidadCarrito items',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

class _ChipFiltro extends StatelessWidget {
  final String etiqueta;
  final bool seleccionado;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.etiqueta,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: seleccionado ? tema.colorScheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: seleccionado
                  ? tema.colorScheme.primary
                  : tema.colorScheme.primary.withAlpha(30),
              width: 1.5,
            ),
            boxShadow: seleccionado
                ? [
                    BoxShadow(
                      color: tema.colorScheme.primary.withAlpha(60),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              etiqueta,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w600,
                color: seleccionado ? Colors.white : tema.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TarjetaProductoIrresistible extends ConsumerWidget {
  final Map<String, dynamic> producto;

  const _TarjetaProductoIrresistible({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final nombre = producto['nombre'] ?? 'Sin nombre';
    final descripcion =
        producto['descripcion'] ?? 'Delicioso postre horneado con amor.';
    final precio = producto['precio']?.toString() ?? '0.0';
    final urlImagen = producto['url_imagen'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: tema.colorScheme.primary.withAlpha(15),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gran Foto del Postre
          Hero(
            tag: 'postre_${producto['id']}',
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: tema.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: urlImagen != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Image.network(urlImagen, fit: BoxFit.cover),
                    )
                  : Icon(
                      Icons.cake_rounded,
                      size: 80,
                      color: tema.colorScheme.primary.withAlpha(100),
                    ),
            ),
          ),

          // Información y Botón de Acción
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        nombre,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: tema.textTheme.displayLarge?.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '\$$precio',
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  descripcion,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: tema.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 24),

                // Botón "Pedir Ahora" muy vibrante
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      ref
                          .read(proveedorCarrito.notifier)
                          .agregarProducto(producto);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text('¡$nombre añadido al carrito!'),
                              ),
                            ],
                          ),
                          backgroundColor: tema.colorScheme.secondary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tema.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: tema.colorScheme.primary.withAlpha(150),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.shopping_bag_rounded, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Pedir Ahora',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
