import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../nucleo/constantes/entorno.dart';
import '../../nucleo/tema/tokens_app.dart';
import '../../proveedores/proveedor_carrito.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../repositorios/repositorio_productos.dart';
import '../widgets/componentes.dart';
import 'pantalla_carrito.dart';
import 'pantalla_chat.dart';
import 'pantalla_club_mg.dart';
import 'pantalla_perfil.dart';

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
    final partes = _nombreUsuario.trim().split(' ');
    if (partes.length > 1 && partes[1].isNotEmpty) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return _nombreUsuario.substring(0, 1).toUpperCase();
  }

  Future<void> _abrirChat() async {
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
  }

  void _abrirCarrito() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const PantallaCarrito()),
  );

  @override
  Widget build(BuildContext context) {
    final itemsCarrito = ref.watch(proveedorCarrito);
    final cantidadCarrito = itemsCarrito.fold(
      0,
      (sum, item) => sum + item.cantidad,
    );
    final totalCarrito = itemsCarrito.fold(
      0.0,
      (sum, item) => sum + item.subtotal,
    );

    return Scaffold(
      drawer: _CajonNavegacion(
        nombre: _nombreUsuario,
        correo: ref.read(supabaseProveedor).auth.currentUser?.email ?? '',
        fotoUrl: _fotoPerfilUrl,
        iniciales: _obtenerIniciales(),
      ),
      body: FondoAtelier(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Cabecera editorial ───────────────────────────────
            SliverAppBar(
              expandedHeight: 268,
              pinned: true,
              stretch: true,
              backgroundColor: Tokens.lienzo,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: _CabeceraInicio(
                  saludo: _saludo,
                  nombre: _nombreUsuario,
                  fotoUrl: _fotoPerfilUrl,
                  iniciales: _obtenerIniciales(),
                  cantidadCarrito: cantidadCarrito,
                  alAbrirCarrito: _abrirCarrito,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(62),
                child: Container(
                  height: 62,
                  alignment: Alignment.centerLeft,
                  color: Tokens.lienzo,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.e5,
                      vertical: Tokens.e2 + 2,
                    ),
                    itemCount: _categorias.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: Tokens.e2 + 2),
                    itemBuilder: (context, index) {
                      final cat = _categorias[index];
                      return _ChipFiltro(
                        etiqueta: cat,
                        seleccionado: _filtroCategoria == cat,
                        onTap: () => setState(() => _filtroCategoria = cat),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ── Título de la carta ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.e5,
                  Tokens.e5,
                  Tokens.e5,
                  Tokens.e4,
                ),
                child: EncabezadoSeccion(
                  antetitulo: 'Nuestra carta',
                  titulo: _filtroCategoria == 'Todos'
                      ? 'Selección de la casa'
                      : _filtroCategoria,
                  descripcion: 'Horneado esta mañana, en cantidades limitadas.',
                ),
              ),
            ),

            // ── Catálogo ─────────────────────────────────────────
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _productosStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: Tokens.e5),
                    sliver: SliverToBoxAdapter(child: _EsqueletoCatalogo()),
                  );
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: EstadoVacio(
                      icono: Icons.cloud_off_rounded,
                      titulo: 'No pudimos cargar la carta',
                      mensaje: '${snapshot.error}',
                    ),
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
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EstadoVacio(
                      icono: Icons.bakery_dining_outlined,
                      titulo: 'Nada por aquí, todavía',
                      mensaje:
                          'No hay piezas disponibles en esta categoría. '
                          'Vuelve a mirar en un rato.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    Tokens.e5,
                    0,
                    Tokens.e5,
                    cantidadCarrito > 0 ? 140 : 110,
                  ),
                  sliver: SliverList.separated(
                    itemCount: productosFiltrados.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Tokens.e6),
                    itemBuilder: (context, index) {
                      return _TarjetaProducto(
                            producto: productosFiltrados[index],
                          )
                          .animate()
                          .fadeIn(
                            duration: 450.ms,
                            delay: (index.clamp(0, 6) * 70).ms,
                          )
                          .slideY(begin: 0.08, curve: Curves.easeOutCubic);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),

      floatingActionButton: _BotonChat(
        cargando: _cargandoChat,
        alPresionar: _abrirChat,
      ),

      bottomNavigationBar: _BarraCarrito(
        cantidad: cantidadCarrito,
        total: totalCarrito,
        alPresionar: _abrirCarrito,
      ),
    );
  }
}

// ─────────────────────────── Cabecera ───────────────────────────

class _CabeceraInicio extends StatelessWidget {
  final String saludo;
  final String nombre;
  final String? fotoUrl;
  final String iniciales;
  final int cantidadCarrito;
  final VoidCallback alAbrirCarrito;

  const _CabeceraInicio({
    required this.saludo,
    required this.nombre,
    required this.fotoUrl,
    required this.iniciales,
    required this.cantidadCarrito,
    required this.alAbrirCarrito,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: Tokens.degradadoAmanecer,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(Tokens.radioXl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.e5,
            Tokens.e3,
            Tokens.e5,
            Tokens.e6,
          ),
          child: Column(
            children: [
              // Barra superior: menú · marca · carrito
              Row(
                children: [
                  Builder(
                    builder: (context) => BotonCircular(
                      icono: Icons.menu_rounded,
                      tooltip: 'Menú',
                      alPresionar: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'PASTELERÍA',
                          style: tema.textTheme.labelSmall?.copyWith(
                            letterSpacing: 3,
                            color: Tokens.rosaProfundo,
                          ),
                        ),
                        Text(
                          'M&G',
                          style: tema.textTheme.headlineMedium?.copyWith(
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _BotonCarritoCabecera(
                    cantidad: cantidadCarrito,
                    alPresionar: alAbrirCarrito,
                  ),
                ],
              ),

              const Spacer(),

              // Saludo personalizado
              TarjetaSuave(
                padding: const EdgeInsets.all(Tokens.e4),
                sombra: Tokens.sombraMedia,
                colorBorde: Colors.white,
                child: Row(
                  children: [
                    _Retrato(
                      fotoUrl: fotoUrl,
                      iniciales: iniciales,
                      radio: 26,
                    ),
                    const SizedBox(width: Tokens.e4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            saludo,
                            style: tema.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                    const Pildora(
                      texto: 'Club M&G',
                      icono: Icons.workspace_premium_rounded,
                      color: Tokens.arenaProfundo,
                      compacta: true,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(
                begin: 0.16,
                curve: Curves.easeOutCubic,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BotonCarritoCabecera extends StatelessWidget {
  final int cantidad;
  final VoidCallback alPresionar;

  const _BotonCarritoCabecera({
    required this.cantidad,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        BotonCircular(
          icono: Icons.shopping_bag_outlined,
          tooltip: 'Mi carrito',
          alPresionar: alPresionar,
        ),
        if (cantidad > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Tokens.rosa,
                borderRadius: BorderRadius.circular(Tokens.radioPildora),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$cantidad',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Retrato extends StatelessWidget {
  final String? fotoUrl;
  final String iniciales;
  final double radio;

  const _Retrato({
    required this.fotoUrl,
    required this.iniciales,
    this.radio = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Tokens.linea, width: 1.5),
      ),
      padding: const EdgeInsets.all(2),
      child: CircleAvatar(
        radius: radio,
        backgroundColor: Tokens.rosaVelo,
        backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl!) : null,
        child: fotoUrl == null
            ? Text(
                iniciales,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Tokens.rosaProfundo,
                  fontSize: radio * 0.72,
                ),
              )
            : null,
      ),
    );
  }
}

// ─────────────────────────── Filtros ───────────────────────────

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
        borderRadius: BorderRadius.circular(Tokens.radioPildora),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: Tokens.e5,
            vertical: Tokens.e2 + 2,
          ),
          decoration: BoxDecoration(
            color: seleccionado ? Tokens.tinta : Tokens.superficie,
            borderRadius: BorderRadius.circular(Tokens.radioPildora),
            border: Border.all(
              color: seleccionado ? Tokens.tinta : Tokens.linea,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            etiqueta,
            style: tema.textTheme.labelMedium?.copyWith(
              color: seleccionado ? Colors.white : Tokens.tintaMedia,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Tarjeta de producto ───────────────────────────

class _TarjetaProducto extends ConsumerWidget {
  final Map<String, dynamic> producto;

  const _TarjetaProducto({required this.producto});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final nombre = producto['nombre'] ?? 'Sin nombre';
    final descripcion =
        producto['descripcion'] ?? 'Delicioso postre horneado con amor.';
    final precio = producto['precio']?.toString() ?? '0.0';
    final precioD = double.tryParse(precio) ?? 0.0;
    final urlImagen = producto['url_imagen'];

    return TarjetaSuave(
      padding: EdgeInsets.zero,
      radio: Tokens.radioXl,
      sombra: Tokens.sombraMedia,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Fotografía
          Stack(
            children: [
              Hero(
                tag: 'postre_${producto['id']}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(Tokens.radioXl - 1),
                  ),
                  child: SizedBox(
                    height: 236,
                    width: double.infinity,
                    child: urlImagen != null
                        ? Image.network(
                            urlImagen,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progreso) =>
                                progreso == null
                                ? child
                                : const Esqueleto(alto: 236, radio: 0),
                            errorBuilder: (_, _, _) => const _ImagenAusente(),
                          )
                        : const _ImagenAusente(),
                  ),
                ),
              ),
              // Precio sobre la foto
              Positioned(
                right: Tokens.e4,
                bottom: Tokens.e4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Tokens.e4,
                    vertical: Tokens.e2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Tokens.radioPildora),
                    boxShadow: Tokens.sombraSuave,
                  ),
                  child: Text(
                    '\$$precio',
                    style: tema.textTheme.titleLarge?.copyWith(
                      color: Tokens.rosaProfundo,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(Tokens.e5 + 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: tema.textTheme.headlineSmall),
                const SizedBox(height: Tokens.e2),
                Text(
                  descripcion,
                  style: tema.textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                if (precioD >= 5.0) ...[
                  const SizedBox(height: Tokens.e4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Tokens.e3 + 2,
                      vertical: Tokens.e3,
                    ),
                    decoration: BoxDecoration(
                      color: Tokens.arenaSuave,
                      borderRadius: BorderRadius.circular(Tokens.radioSm),
                      border: Border.all(
                        color: Tokens.arena.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.workspace_premium_rounded,
                          size: 17,
                          color: Tokens.arenaProfundo,
                        ),
                        const SizedBox(width: Tokens.e2 + 2),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: tema.textTheme.bodySmall?.copyWith(
                                color: Tokens.arenaProfundo,
                                height: 1.4,
                              ),
                              children: [
                                const TextSpan(text: 'Club M&G · 3 cuotas de '),
                                TextSpan(
                                  text:
                                      '\$${(precioD / 3).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
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

                const SizedBox(height: Tokens.e5),

                BotonPrincipal(
                  texto: 'Añadir al pedido',
                  icono: Icons.add_rounded,
                  altura: 52,
                  alPresionar: () {
                    ref
                        .read(proveedorCarrito.notifier)
                        .agregarProducto(producto);
                    Avisos.exito(context, '$nombre se añadió a tu pedido');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagenAusente extends StatelessWidget {
  const _ImagenAusente();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Tokens.rosaVelo,
      alignment: Alignment.center,
      child: const Icon(Icons.cake_rounded, size: 46, color: Tokens.rosaSuave),
    );
  }
}

class _EsqueletoCatalogo extends StatelessWidget {
  const _EsqueletoCatalogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: Tokens.e6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Esqueleto(alto: 236, radio: Tokens.radioXl),
              SizedBox(height: Tokens.e4),
              Esqueleto(alto: 20, ancho: 180),
              SizedBox(height: Tokens.e3),
              Esqueleto(alto: 14),
              SizedBox(height: Tokens.e2),
              Esqueleto(alto: 14, ancho: 220),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Acciones flotantes ───────────────────────────

class _BotonChat extends StatelessWidget {
  final bool cargando;
  final VoidCallback alPresionar;

  const _BotonChat({required this.cargando, required this.alPresionar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Tokens.radioPildora),
        boxShadow: Tokens.haloColor(Tokens.tinta),
      ),
      child: Material(
        color: Tokens.tinta,
        borderRadius: BorderRadius.circular(Tokens.radioPildora),
        child: InkWell(
          onTap: alPresionar,
          borderRadius: BorderRadius.circular(Tokens.radioPildora),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.e5,
              vertical: Tokens.e4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cargando)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: Tokens.arena,
                  ),
                const SizedBox(width: Tokens.e2 + 2),
                Text(
                  'Asistente',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).scale(
      curve: Curves.easeOutBack,
      duration: 400.ms,
      begin: const Offset(0.85, 0.85),
    );
  }
}

/// Barra inferior con el resumen del pedido; aparece sólo con artículos.
class _BarraCarrito extends StatelessWidget {
  final int cantidad;
  final double total;
  final VoidCallback alPresionar;

  const _BarraCarrito({
    required this.cantidad,
    required this.total,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    if (cantidad == 0) return const SizedBox.shrink();
    final tema = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Tokens.superficie,
        border: const Border(top: BorderSide(color: Tokens.linea)),
        boxShadow: Tokens.sombraMedia,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.e5,
            Tokens.e3,
            Tokens.e5,
            Tokens.e3,
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cantidad == 1 ? '1 artículo' : '$cantidad artículos',
                    style: tema.textTheme.labelSmall,
                  ),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: tema.textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(width: Tokens.e5),
              Expanded(
                child: BotonPrincipal(
                  texto: 'Ver mi pedido',
                  icono: Icons.arrow_forward_rounded,
                  altura: 50,
                  alPresionar: alPresionar,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, duration: 350.ms, curve: Curves.easeOutCubic);
  }
}

// ─────────────────────────── Cajón lateral ───────────────────────────

class _CajonNavegacion extends ConsumerWidget {
  final String nombre;
  final String correo;
  final String? fotoUrl;
  final String iniciales;

  const _CajonNavegacion({
    required this.nombre,
    required this.correo,
    required this.fotoUrl,
    required this.iniciales,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);

    return Drawer(
      width: 312,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(Tokens.e6),
              decoration: const BoxDecoration(
                gradient: Tokens.degradadoAmanecer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Retrato(fotoUrl: fotoUrl, iniciales: iniciales, radio: 30),
                  const SizedBox(height: Tokens.e4),
                  Text(
                    nombre,
                    style: tema.textTheme.headlineSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (correo.isNotEmpty)
                    Text(
                      correo,
                      style: tema.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(height: Tokens.e5),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Tokens.e5),
              child: const Antetitulo('Mi cuenta'),
            ),
            const SizedBox(height: Tokens.e3),
            _OpcionCajon(
              icono: Icons.person_outline_rounded,
              titulo: 'Mi perfil',
              detalle: 'Datos, estadísticas y crédito',
              color: Tokens.rosa,
              alTocar: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaPerfil()),
                );
              },
            ),
            _OpcionCajon(
              icono: Icons.workspace_premium_outlined,
              titulo: 'Club M&G',
              detalle: 'Tus cuotas y beneficios',
              color: Tokens.arenaProfundo,
              alTocar: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PantallaClubMg()),
                );
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(Tokens.e5),
              child: BotonContorno(
                texto: 'Cerrar sesión',
                icono: Icons.logout_rounded,
                altura: 50,
                color: Tokens.peligro,
                alPresionar: () async {
                  await ref.read(supabaseProveedor).auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpcionCajon extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String detalle;
  final Color color;
  final VoidCallback alTocar;

  const _OpcionCajon({
    required this.icono,
    required this.titulo,
    required this.detalle,
    required this.color,
    required this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Tokens.e4, 0, Tokens.e4, Tokens.e2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(Tokens.radioSm),
        child: InkWell(
          onTap: alTocar,
          borderRadius: BorderRadius.circular(Tokens.radioSm),
          child: Padding(
            padding: const EdgeInsets.all(Tokens.e3),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(Tokens.radioXs),
                  ),
                  child: Icon(icono, size: 18, color: color),
                ),
                const SizedBox(width: Tokens.e3 + 2),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: tema.textTheme.titleMedium),
                      Text(detalle, style: tema.textTheme.bodySmall),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Tokens.tintaSuave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
