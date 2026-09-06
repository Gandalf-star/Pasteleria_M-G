import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nucleo/tema/tokens_app.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../repositorios/repositorio_credito.dart';
import '../../repositorios/repositorio_ordenes.dart';
import '../widgets/componentes.dart';
import 'pantalla_club_mg.dart';

class PantallaPerfil extends ConsumerStatefulWidget {
  const PantallaPerfil({super.key});

  @override
  ConsumerState<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends ConsumerState<PantallaPerfil> {
  bool _tieneCuotasVencidas = false;
  String _nombreUsuario = 'Invitado';
  String _correo = '';
  String? _fotoPerfilUrl;
  bool _cargandoDatos = true;

  int _totalPedidos = 0;
  double _totalGastado = 0.0;
  List<Map<String, dynamic>> _nivelesCredito = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final supabase = ref.read(supabaseProveedor);
    final repoCredito = ref.read(proveedorRepositorioCredito);
    final repoOrdenes = ref.read(proveedorRepositorioOrdenes);

    final usuario = supabase.auth.currentUser;
    if (usuario != null) {
      _correo = usuario.email ?? '';
      _nombreUsuario = usuario.userMetadata?['nombre'] ?? 'Invitado';

      try {
        final clienteRes = await supabase
            .from('clientes')
            .select('foto_url, nombre, correo')
            .eq('id', usuario.id)
            .maybeSingle();

        if (clienteRes != null) {
          if (clienteRes['nombre'] != null &&
              clienteRes['nombre'].toString().isNotEmpty) {
            _nombreUsuario = clienteRes['nombre'];
          }
          if (clienteRes['foto_url'] != null &&
              clienteRes['foto_url'].toString().isNotEmpty) {
            _fotoPerfilUrl = clienteRes['foto_url'];
          }
          if (clienteRes['correo'] != null &&
              clienteRes['correo'].toString().isNotEmpty) {
            _correo = clienteRes['correo'];
          }
        }

        final vencidas = await repoCredito.tieneCuotasVencidas();
        final stats = await repoOrdenes.obtenerEstadisticasUsuario();
        final niveles = await repoCredito.obtenerNivelesCredito();

        if (mounted) {
          setState(() {
            _tieneCuotasVencidas = vencidas;
            _totalPedidos = stats['total_pedidos'];
            _totalGastado = stats['total_gastado'];
            _nivelesCredito = niveles;
            _cargandoDatos = false;
          });
        }
      } catch (e) {
        debugPrint('Error cargando perfil: $e');
        if (mounted) setState(() => _cargandoDatos = false);
      }
    } else {
      if (mounted) setState(() => _cargandoDatos = false);
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

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final repoCredito = ref.watch(proveedorRepositorioCredito);

    return Scaffold(
      body: FondoAtelier(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Tokens.e5,
                  Tokens.e3,
                  Tokens.e5,
                  0,
                ),
                child: Row(
                  children: [
                    BotonCircular(
                      icono: Icons.arrow_back_rounded,
                      tooltip: 'Volver',
                      alPresionar: () => Navigator.maybePop(context),
                    ),
                    const Spacer(),
                    const Antetitulo('Mi cuenta'),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              Expanded(
                child: _cargandoDatos
                    ? const Cargando(mensaje: 'Cargando tu perfil…')
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          Tokens.e5,
                          Tokens.e6,
                          Tokens.e5,
                          Tokens.e12,
                        ),
                        children: [
                          // ── Identidad ──────────────────────────
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Tokens.linea,
                                    width: 1.5,
                                  ),
                                  boxShadow: Tokens.sombraSuave,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: CircleAvatar(
                                  radius: 46,
                                  backgroundColor: Tokens.rosaVelo,
                                  backgroundImage: _fotoPerfilUrl != null
                                      ? NetworkImage(_fotoPerfilUrl!)
                                      : null,
                                  child: _fotoPerfilUrl == null
                                      ? Text(
                                          _obtenerIniciales(),
                                          style: tema.textTheme.displaySmall
                                              ?.copyWith(
                                                color: Tokens.rosaProfundo,
                                              ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: Tokens.e4),
                              Text(
                                _nombreUsuario,
                                textAlign: TextAlign.center,
                                style: tema.textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(_correo, style: tema.textTheme.bodySmall),
                            ],
                          ).animate().fadeIn(duration: 450.ms).slideY(
                            begin: 0.1,
                            curve: Curves.easeOutCubic,
                          ),

                          const SizedBox(height: Tokens.e6),

                          // ── Estado de la cuenta ────────────────
                          Aviso(
                            titulo: _tieneCuotasVencidas
                                ? 'Cuenta suspendida'
                                : 'Cuenta al día',
                            detalle: _tieneCuotasVencidas
                                ? 'Tienes cuotas vencidas. Regularízalas para '
                                      'volver a financiar pedidos.'
                                : 'Puedes financiar tus pedidos con el Club M&G.',
                            icono: _tieneCuotasVencidas
                                ? Icons.error_outline_rounded
                                : Icons.verified_rounded,
                            color: _tieneCuotasVencidas
                                ? Tokens.peligro
                                : Tokens.exito,
                            fondo: _tieneCuotasVencidas
                                ? Tokens.peligroSuave
                                : Tokens.exitoSuave,
                          ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.08),

                          const SizedBox(height: Tokens.e8),

                          // ── Historial de compras ───────────────
                          const EncabezadoSeccion(
                            antetitulo: 'Historial',
                            titulo: 'Tus compras',
                          ),
                          const SizedBox(height: Tokens.e4),
                          Row(
                            children: [
                              _Metrica(
                                etiqueta: 'Pedidos',
                                valor: _totalPedidos.toString(),
                                icono: Icons.receipt_long_outlined,
                                color: Tokens.rosa,
                              ),
                              const SizedBox(width: Tokens.e3),
                              _Metrica(
                                etiqueta: 'Invertido',
                                valor: '\$${_totalGastado.toStringAsFixed(2)}',
                                icono: Icons.savings_outlined,
                                color: Tokens.salviaProfundo,
                              ),
                            ],
                          ).animate().fadeIn(delay: 220.ms).slideY(begin: 0.08),

                          const SizedBox(height: Tokens.e8),

                          // ── Resumen financiero ─────────────────
                          StreamBuilder<Map<String, dynamic>?>(
                            stream: repoCredito.escucharLineaCredito(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: Tokens.e8,
                                  ),
                                  child: Cargando(),
                                );
                              }

                              final linea = snapshot.data;
                              final bool noTieneLinea = linea == null;
                              final disponibleReal = noTieneLinea
                                  ? 5.0
                                  : double.parse(
                                      linea['saldo_disponible'].toString(),
                                    );
                              final limite = noTieneLinea
                                  ? 5.0
                                  : double.parse(
                                      linea['limite_total'].toString(),
                                    );
                              final puntos = noTieneLinea
                                  ? 0
                                  : (linea['puntos'] ?? 0);
                              final nivel = noTieneLinea
                                  ? 1
                                  : (linea['nivel_actual'] ?? 1);

                              final disponibleUI = disponibleReal < 0
                                  ? 0.0
                                  : disponibleReal;
                              final deudaTotal = limite - disponibleReal;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  EncabezadoSeccion(
                                    antetitulo: 'Club M&G',
                                    titulo: 'Resumen financiero',
                                    accion: TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const PantallaClubMg(),
                                        ),
                                      ),
                                      child: const Text('Ver cuotas'),
                                    ),
                                  ),
                                  const SizedBox(height: Tokens.e4),

                                  Row(
                                    children: [
                                      _Metrica(
                                        etiqueta: noTieneLinea
                                            ? 'Nivel inicial'
                                            : 'Nivel actual',
                                        valor: nivel.toString(),
                                        icono: Icons.workspace_premium_outlined,
                                        color: Tokens.arenaProfundo,
                                      ),
                                      const SizedBox(width: Tokens.e3),
                                      _Metrica(
                                        etiqueta: 'Puntos M&G',
                                        valor: puntos.toString(),
                                        icono: Icons.auto_awesome_outlined,
                                        color: Tokens.lavanda,
                                      ),
                                    ],
                                  ),

                                  if (_nivelesCredito.isNotEmpty) ...[
                                    const SizedBox(height: Tokens.e3),
                                    _ProgresoNivel(
                                      niveles: _nivelesCredito,
                                      nivel: nivel,
                                      puntos: puntos,
                                    ),
                                  ],

                                  const SizedBox(height: Tokens.e3),

                                  TarjetaSuave(
                                    padding: const EdgeInsets.all(Tokens.e5),
                                    child: Column(
                                      children: [
                                        _FilaSaldo(
                                          'Línea de compra',
                                          limite,
                                          Tokens.tintaMedia,
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: Tokens.e4,
                                          ),
                                          child: Divider(height: 1),
                                        ),
                                        _FilaSaldo(
                                          'Deuda total',
                                          deudaTotal,
                                          Tokens.peligro,
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            vertical: Tokens.e4,
                                          ),
                                          child: Divider(height: 1),
                                        ),
                                        _FilaSaldo(
                                          'Disponible',
                                          disponibleUI,
                                          Tokens.exito,
                                          esGrande: true,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ).animate().fadeIn(delay: 280.ms).slideY(
                                begin: 0.06,
                              );
                            },
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Piezas ───────────────────────────

/// Tarjeta de métrica: ícono, etiqueta y valor destacado.
class _Metrica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color color;

  const _Metrica({
    required this.etiqueta,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: TarjetaSuave(
        padding: const EdgeInsets.all(Tokens.e4 + 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(Tokens.radioXs),
              ),
              child: Icon(icono, size: 17, color: color),
            ),
            const SizedBox(height: Tokens.e4),
            Text(etiqueta.toUpperCase(), style: tema.textTheme.labelSmall),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(valor, style: tema.textTheme.headlineMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Barra de avance hacia el siguiente nivel del Club.
class _ProgresoNivel extends StatelessWidget {
  final List<Map<String, dynamic>> niveles;
  final int nivel;
  final int puntos;

  const _ProgresoNivel({
    required this.niveles,
    required this.nivel,
    required this.puntos,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    int puntosSiguienteNivel = 0;
    String nombreSiguienteNivel = 'Máximo Nivel';
    double progresoNivel = 1.0;
    int puntosNivelActual = 0;

    for (var n in niveles) {
      if (n['nivel'] == nivel) {
        puntosNivelActual = n['puntos_requeridos'];
      }
      if (n['nivel'] == nivel + 1) {
        puntosSiguienteNivel = n['puntos_requeridos'];
        nombreSiguienteNivel = n['nombre'];
      }
    }

    if (puntosSiguienteNivel > 0) {
      final puntosRango = puntosSiguienteNivel - puntosNivelActual;
      final puntosGanadosEnNivel = puntos - puntosNivelActual;
      progresoNivel = (puntosGanadosEnNivel / puntosRango).clamp(0.0, 1.0);
    }

    return TarjetaSuave(
      padding: const EdgeInsets.all(Tokens.e5),
      color: Tokens.arenaSuave,
      colorBorde: Tokens.arena.withValues(alpha: 0.25),
      sombra: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  puntosSiguienteNivel > 0
                      ? 'Camino al nivel $nombreSiguienteNivel'
                      : '¡Has alcanzado el máximo nivel!',
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: Tokens.arenaProfundo,
                  ),
                ),
              ),
              if (puntosSiguienteNivel > 0)
                Text(
                  '$puntos / $puntosSiguienteNivel',
                  style: tema.textTheme.titleSmall?.copyWith(
                    color: Tokens.arenaProfundo,
                  ),
                ),
            ],
          ),
          if (puntosSiguienteNivel > 0) ...[
            const SizedBox(height: Tokens.e3),
            ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radioPildora),
              child: LinearProgressIndicator(
                value: progresoNivel,
                minHeight: 7,
                backgroundColor: Colors.white.withValues(alpha: 0.7),
                valueColor: const AlwaysStoppedAnimation<Color>(Tokens.arena),
              ),
            ),
            const SizedBox(height: Tokens.e3),
            Text(
              'Paga a tiempo y suma +20 puntos para ampliar tu límite.',
              style: tema.textTheme.bodySmall?.copyWith(
                color: Tokens.arenaProfundo.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaSaldo extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;
  final bool esGrande;

  const _FilaSaldo(
    this.titulo,
    this.monto,
    this.color, {
    this.esGrande = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: esGrande
              ? tema.textTheme.titleMedium
              : tema.textTheme.bodyMedium,
        ),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style:
              (esGrande
                      ? tema.textTheme.headlineSmall
                      : tema.textTheme.titleLarge)
                  ?.copyWith(color: color),
        ),
      ],
    );
  }
}
