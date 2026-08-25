import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../repositorios/repositorio_credito.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../nucleo/constantes/entorno.dart';
import 'package:intl/intl.dart';

class PantallaClubMg extends ConsumerStatefulWidget {
  const PantallaClubMg({super.key});

  @override
  ConsumerState<PantallaClubMg> createState() => _PantallaClubMgState();
}

class _PantallaClubMgState extends ConsumerState<PantallaClubMg> {
  List<Map<String, dynamic>> _nivelesCredito = [];

  @override
  void initState() {
    super.initState();
    _cargarNiveles();
  }

  Future<void> _cargarNiveles() async {
    final repoCredito = ref.read(proveedorRepositorioCredito);
    final niveles = await repoCredito.obtenerNivelesCredito();
    if (mounted) {
      setState(() {
        _nivelesCredito = niveles;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final repoCredito = ref.watch(proveedorRepositorioCredito);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Club M&G',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Resumen de Crédito
            StreamBuilder<Map<String, dynamic>?>(
              stream: repoCredito.escucharLineaCredito(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final linea = snapshot.data;
                final bool noTieneLinea = linea == null;
                final disponibleReal = noTieneLinea
                    ? 5.0
                    : double.parse(linea['saldo_disponible'].toString());
                final limite = noTieneLinea
                    ? 5.0
                    : double.parse(linea['limite_total'].toString());
                final puntos = noTieneLinea ? 0 : (linea['puntos'] ?? 0);
                final nivel = noTieneLinea ? 1 : (linea['nivel_actual'] ?? 1);

                // Matemática visual
                final disponibleUI = disponibleReal < 0 ? 0.0 : disponibleReal;
                final deudaTotal =
                    limite -
                    disponibleReal; // Deuda real incluyendo montos excedentes
                final progresoUI = (limite > 0) ? (disponibleUI / limite) : 0.0;

                return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E293B), // Slate 800
                        Color(0xFF0F172A), // Slate 900
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(50),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Nivel $nivel',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$puntos Puntos',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Cashea-style Progress Bar
                      if (_nivelesCredito.isNotEmpty)
                        Builder(
                          builder: (context) {
                            int puntosSiguienteNivel = 0;
                            String nombreSiguienteNivel = 'Máximo Nivel';
                            double progresoPuntos = 1.0;
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
                              int puntosRango =
                                  puntosSiguienteNivel - puntosNivelActual;
                              int puntosGanadosEnNivel =
                                  puntos - puntosNivelActual;
                              progresoPuntos =
                                  (puntosGanadosEnNivel / puntosRango).clamp(
                                    0.0,
                                    1.0,
                                  );
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      puntosSiguienteNivel > 0
                                          ? 'Para Nivel $nombreSiguienteNivel'
                                          : '¡Máximo nivel alcanzado!',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withAlpha(200),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (puntosSiguienteNivel > 0)
                                      Text(
                                        '$puntos / $puntosSiguienteNivel pts',
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                if (puntosSiguienteNivel > 0) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progresoPuntos,
                                      minHeight: 6,
                                      backgroundColor: Colors.black.withAlpha(
                                        50,
                                      ),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            Colors.amber,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Paga a tiempo y obtén +20 pts',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withAlpha(150),
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),

                      Text(
                        'Disponible para comprar',
                        style: GoogleFonts.inter(
                          color: Colors.white.withAlpha(200),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${disponibleUI.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 42,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LinearProgressIndicator(
                        value: progresoUI.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withAlpha(50),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 8,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deuda Total',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '\$${deudaTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Límite Total',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withAlpha(150),
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '\$${limite.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().slideY(begin: -0.1, duration: 500.ms).fadeIn();
              },
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tus Próximas Cuotas',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            // Lista de Planes y sus Cuotas
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: repoCredito.escucharPlanesActivos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final planes = snapshot.data ?? [];
                if (planes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No tienes planes de financiamiento activos.',
                        style: GoogleFonts.inter(
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: planes.length,
                  itemBuilder: (context, index) {
                    final plan = planes[index];
                    return _TarjetaPlan(plan: plan);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _TarjetaPlan extends ConsumerStatefulWidget {
  final Map<String, dynamic> plan;

  const _TarjetaPlan({required this.plan});

  @override
  ConsumerState<_TarjetaPlan> createState() => _TarjetaPlanState();
}

class _TarjetaPlanState extends ConsumerState<_TarjetaPlan> {
  bool _cargando = true;
  List<Map<String, dynamic>> _cuotas = [];

  @override
  void initState() {
    super.initState();
    _cargarCuotas();
  }

  Future<void> _cargarCuotas() async {
    final repo = ref.read(proveedorRepositorioCredito);
    final cuotas = await repo.obtenerCuotasPlan(widget.plan['id']);
    if (mounted) {
      setState(() {
        _cuotas = cuotas;
        _cargando = false;
      });
    }
  }

  Future<void> _confirmarPago(String cuotaId, double monto) async {
    final repo = ref.read(proveedorRepositorioCredito);
    await repo.reportarPagoCuota(cuotaId);

    // 1. Obtener el número de WhatsApp de la BD
    final supabase = ref.read(supabaseProveedor);
    final negocioRes = await supabase
        .from('negocios')
        .select('telefono')
        .eq('id', Entorno.idSweetBites)
        .maybeSingle();
    final telefonoDb = negocioRes?['telefono'] as String? ?? '';
    final numeroAdmin = telefonoDb.replaceAll(RegExp(r'[^\d]'), '');

    // 2. Construir mensaje
    final mensaje =
        "Hola Pastelería M&G, acabo de realizar el pago de mi cuota por \$${monto.toStringAsFixed(2)}. Adjunto el comprobante.";

    // Si no hay número en DB, usa uno por defecto o no hace nada (lo evitamos usando 584240000000 si está vacío)
    final numeroFinal = numeroAdmin.isEmpty ? "584240000000" : numeroAdmin;
    final uri = Uri.parse(
      "https://wa.me/$numeroFinal?text=${Uri.encodeComponent(mensaje)}",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    _cargarCuotas(); // Refrescar

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pago reportado. Esperando aprobación.'),
          backgroundColor: Colors.amber,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final montoFinanciado =
        widget.plan['monto_financiado']?.toString() ?? '0.0';

    if (_cargando) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: tema.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tema.colorScheme.outlineVariant.withAlpha(40)),
      ),
      child: ExpansionTile(
        title: Text(
          'Plan de \$$montoFinanciado',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'ID: ${widget.plan['id'].toString().split('-').first}',
          style: GoogleFonts.inter(fontSize: 12),
        ),
        initiallyExpanded: true,
        children: _cuotas.map((cuota) {
          final estado = cuota['estado'];
          final monto = double.parse(cuota['monto'].toString());
          final recargo = double.parse(
            (cuota['cargo_retraso'] ?? 0).toString(),
          );
          final total = monto + recargo;
          final vencimiento = DateTime.parse(cuota['fecha_vencimiento']);

          Color colorEstado = Colors.grey;
          IconData iconEstado = Icons.help;

          if (estado == 'PAGADA') {
            colorEstado = Colors.green;
            iconEstado = Icons.check_circle;
          } else if (estado == 'REPORTADO') {
            colorEstado = Colors.amber;
            iconEstado = Icons.access_time_filled;
          } else if (estado == 'VENCIDA') {
            colorEstado = Colors.red;
            iconEstado = Icons.warning;
          } else {
            colorEstado = tema.colorScheme.primary;
            iconEstado = Icons.calendar_today;
          }

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: colorEstado.withAlpha(30),
              child: Icon(iconEstado, color: colorEstado, size: 20),
            ),
            title: Text(
              '\$${total.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Vence: ${DateFormat('dd MMM yyyy').format(vencimiento)}\nEstado: $estado',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            isThreeLine: true,
            trailing: (estado == 'PENDIENTE' || estado == 'VENCIDA')
                ? ElevatedButton(
                    onPressed: () => _confirmarPago(cuota['id'], total),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tema.colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Pagar'),
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }
}
