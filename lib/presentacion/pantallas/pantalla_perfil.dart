import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../repositorios/repositorio_credito.dart';
import '../../repositorios/repositorio_ordenes.dart';
import '../../proveedores/supabase_proveedor.dart';

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
          if (clienteRes['nombre'] != null && clienteRes['nombre'].toString().isNotEmpty) {
            _nombreUsuario = clienteRes['nombre'];
          }
          if (clienteRes['foto_url'] != null && clienteRes['foto_url'].toString().isNotEmpty) {
            _fotoPerfilUrl = clienteRes['foto_url'];
          }
          if (clienteRes['correo'] != null && clienteRes['correo'].toString().isNotEmpty) {
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
    final partes = _nombreUsuario.split(' ');
    if (partes.length > 1) {
      return '${partes[0][0]}${partes[1][0]}'.toUpperCase();
    }
    return _nombreUsuario.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final repoCredito = ref.watch(proveedorRepositorioCredito);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Mi Perfil',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _cargandoDatos
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Avatar y Nombre
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: tema.colorScheme.primary.withAlpha(40),
                          backgroundImage: _fotoPerfilUrl != null ? NetworkImage(_fotoPerfilUrl!) : null,
                          child: _fotoPerfilUrl == null
                              ? Text(
                                  _obtenerIniciales(),
                                  style: GoogleFonts.outfit(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: tema.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 16),
                        Text(
                          _nombreUsuario,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _correo,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Indicador de Estatus
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: _tieneCuotasVencidas 
                          ? Colors.red.withAlpha(20) 
                          : Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _tieneCuotasVencidas ? Colors.red.withAlpha(100) : Colors.green.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _tieneCuotasVencidas ? Colors.red : Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _tieneCuotasVencidas ? Icons.warning_rounded : Icons.check_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estado de tu cuenta',
                                style: GoogleFonts.inter(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
                              ),
                              Text(
                                _tieneCuotasVencidas 
                                    ? 'Suspendida por cuotas pendientes' 
                                    : 'Lista para compras financiadas',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _tieneCuotasVencidas ? Colors.red[700] : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  // Estadísticas Generales
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Estadísticas de Compras',
                          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _TarjetaEstadistica(
                              titulo: 'Pedidos Realizados',
                              valor: _totalPedidos.toString(),
                              icono: Icons.shopping_bag_outlined,
                              colorIcono: tema.colorScheme.primary,
                            ),
                            const SizedBox(width: 16),
                            _TarjetaEstadistica(
                              titulo: 'Total Invertido',
                              valor: '\$${_totalGastado.toStringAsFixed(2)}',
                              icono: Icons.payments_outlined,
                              colorIcono: Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),
                  
                  // StreamBuilder para las estadísticas en vivo
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: repoCredito.escucharLineaCredito(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final linea = snapshot.data;
                      final bool noTieneLinea = linea == null;
                      final disponibleReal = noTieneLinea ? 5.0 : double.parse(linea['saldo_disponible'].toString());
                      final limite = noTieneLinea ? 5.0 : double.parse(linea['limite_total'].toString());
                      final puntos = noTieneLinea ? 0 : (linea['puntos'] ?? 0);
                      final nivel = noTieneLinea ? 1 : (linea['nivel_actual'] ?? 1);
                      
                      final disponibleUI = disponibleReal < 0 ? 0.0 : disponibleReal;
                      final deudaTotal = limite - disponibleReal;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Resumen Financiero',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            
                            // Tarjetas de Estadísticas
                            Row(
                              children: [
                                _TarjetaEstadistica(
                                  titulo: noTieneLinea ? 'Nivel Inicial' : 'Nivel Actual',
                                  valor: nivel.toString(),
                                  icono: Icons.star_rounded,
                                  colorIcono: Colors.amber,
                                ),
                                const SizedBox(width: 16),
                                _TarjetaEstadistica(
                                  titulo: 'Puntos M&G',
                                  valor: puntos.toString(),
                                  icono: Icons.local_activity_rounded,
                                  colorIcono: tema.colorScheme.primary,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Progreso de Nivel (Estilo Cashea)
                            if (_nivelesCredito.isNotEmpty)
                              Builder(
                                builder: (context) {
                                  int puntosSiguienteNivel = 0;
                                  String nombreSiguienteNivel = 'Máximo Nivel';
                                  double progresoNivel = 1.0;
                                  int puntosNivelActual = 0;
                                  
                                  for (var n in _nivelesCredito) {
                                    if (n['nivel'] == nivel) {
                                      puntosNivelActual = n['puntos_requeridos'];
                                    }
                                    if (n['nivel'] == nivel + 1) {
                                      puntosSiguienteNivel = n['puntos_requeridos'];
                                      nombreSiguienteNivel = n['nombre'];
                                    }
                                  }
                                  
                                  if (puntosSiguienteNivel > 0) {
                                    int puntosRango = puntosSiguienteNivel - puntosNivelActual;
                                    int puntosGanadosEnNivel = puntos - puntosNivelActual;
                                    progresoNivel = (puntosGanadosEnNivel / puntosRango).clamp(0.0, 1.0);
                                  }
                                  
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: tema.colorScheme.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: tema.colorScheme.primary.withAlpha(50)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              puntosSiguienteNivel > 0 
                                                  ? 'Progreso a Nivel $nombreSiguienteNivel'
                                                  : '¡Has alcanzado el máximo nivel!',
                                              style: GoogleFonts.inter(
                                                fontSize: 12, 
                                                fontWeight: FontWeight.bold,
                                                color: tema.colorScheme.primary,
                                              ),
                                            ),
                                            if (puntosSiguienteNivel > 0)
                                              Text(
                                                '$puntos / $puntosSiguienteNivel pts',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (puntosSiguienteNivel > 0) ...[
                                          const SizedBox(height: 12),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(10),
                                            child: LinearProgressIndicator(
                                              value: progresoNivel,
                                              minHeight: 8,
                                              backgroundColor: tema.colorScheme.primary.withAlpha(40),
                                              valueColor: AlwaysStoppedAnimation<Color>(tema.colorScheme.primary),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Paga a tiempo y obtén +20 pts para más límite',
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              color: tema.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ]
                                      ],
                                    ),
                                  ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1);
                                }
                              ),
                            const SizedBox(height: 16),
                            
                            // Detalle de saldos
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: tema.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: tema.colorScheme.outlineVariant.withAlpha(50)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _FilaSaldo('Línea de Compra', limite, Colors.grey[700]!),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                                  _FilaSaldo('Deuda Total', deudaTotal, Colors.red[600]!),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Divider(height: 1),
                                  ),
                                  _FilaSaldo('Disponible', disponibleUI, Colors.green[600]!, esGrande: true),
                                ],
                              ),
                            )
                          ],
                        ),
                      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
                    },
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }
}

class _TarjetaEstadistica extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color colorIcono;

  const _TarjetaEstadistica({
    required this.titulo,
    required this.valor,
    required this.icono,
    required this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tema.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: tema.colorScheme.outlineVariant.withAlpha(50)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: colorIcono, size: 28),
            const SizedBox(height: 12),
            Text(
              titulo,
              style: GoogleFonts.inter(fontSize: 12, color: tema.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              valor,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaSaldo extends StatelessWidget {
  final String titulo;
  final double monto;
  final Color color;
  final bool esGrande;

  const _FilaSaldo(this.titulo, this.monto, this.color, {this.esGrande = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          titulo,
          style: GoogleFonts.inter(
            fontWeight: esGrande ? FontWeight.bold : FontWeight.normal,
            color: esGrande ? Colors.black87 : Colors.grey[700],
          ),
        ),
        Text(
          '\$${monto.toStringAsFixed(2)}',
          style: GoogleFonts.outfit(
            fontSize: esGrande ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
