import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../nucleo/constantes/entorno.dart';
import '../../nucleo/tema/tokens_app.dart';
import '../../nucleo/utilidades/enlaces.dart';
import '../../proveedores/supabase_proveedor.dart';
import '../../repositorios/repositorio_credito.dart';
import '../widgets/componentes.dart';

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
                    const Antetitulo('Programa de clientes'),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    Tokens.e5,
                    Tokens.e5,
                    Tokens.e5,
                    Tokens.e12,
                  ),
                  children: [
                    Text('Club M&G', style: tema.textTheme.displaySmall),
                    const SizedBox(height: Tokens.e2),
                    Text(
                      'Tu línea de compra, tus puntos y las cuotas por pagar.',
                      style: tema.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: Tokens.e6),

                    // ── Tarjeta de crédito ─────────────────────
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: repoCredito.escucharLineaCredito(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Esqueleto(
                            alto: 250,
                            radio: Tokens.radioXl,
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
                            : double.parse(linea['limite_total'].toString());
                        final puntos = noTieneLinea
                            ? 0
                            : (linea['puntos'] ?? 0);
                        final nivel = noTieneLinea
                            ? 1
                            : (linea['nivel_actual'] ?? 1);

                        // Matemática visual
                        final disponibleUI = disponibleReal < 0
                            ? 0.0
                            : disponibleReal;
                        // Deuda real incluyendo montos excedentes
                        final deudaTotal = limite - disponibleReal;
                        final progresoUI = (limite > 0)
                            ? (disponibleUI / limite)
                            : 0.0;

                        return _TarjetaCredito(
                          nivel: nivel,
                          puntos: puntos,
                          disponible: disponibleUI,
                          deuda: deudaTotal,
                          limite: limite,
                          progreso: progresoUI.clamp(0.0, 1.0),
                          niveles: _nivelesCredito,
                        ).animate().fadeIn(duration: 500.ms).slideY(
                          begin: 0.08,
                          curve: Curves.easeOutCubic,
                        );
                      },
                    ),

                    const SizedBox(height: Tokens.e8),

                    const EncabezadoSeccion(
                      antetitulo: 'Calendario',
                      titulo: 'Tus próximas cuotas',
                      descripcion:
                          'Reporta cada pago y súmate +20 puntos por puntualidad.',
                    ),
                    const SizedBox(height: Tokens.e4),

                    // ── Planes activos ─────────────────────────
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: repoCredito.escucharPlanesActivos(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: Tokens.e8),
                            child: Cargando(),
                          );
                        }

                        final planes = snapshot.data ?? [];
                        if (planes.isEmpty) {
                          return const TarjetaSuave(
                            padding: EdgeInsets.symmetric(
                              vertical: Tokens.e8,
                              horizontal: Tokens.e5,
                            ),
                            child: EstadoVacio(
                              icono: Icons.event_available_outlined,
                              titulo: 'Sin cuotas pendientes',
                              mensaje:
                                  'Cuando financies un pedido, aquí verás el '
                                  'calendario completo de pagos.',
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (int i = 0; i < planes.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: Tokens.e4,
                                ),
                                child: _TarjetaPlan(plan: planes[i])
                                    .animate()
                                    .fadeIn(delay: (i.clamp(0, 6) * 60).ms)
                                    .slideY(begin: 0.06),
                              ),
                          ],
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

// ─────────────────────────── Tarjeta de crédito ───────────────────────────

class _TarjetaCredito extends StatelessWidget {
  final int nivel;
  final int puntos;
  final double disponible;
  final double deuda;
  final double limite;
  final double progreso;
  final List<Map<String, dynamic>> niveles;

  const _TarjetaCredito({
    required this.nivel,
    required this.puntos,
    required this.disponible,
    required this.deuda,
    required this.limite,
    required this.progreso,
    required this.niveles,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final blanco70 = Colors.white.withValues(alpha: 0.70);
    final blanco45 = Colors.white.withValues(alpha: 0.45);

    // Progreso de puntos hacia el siguiente nivel
    int puntosSiguienteNivel = 0;
    String nombreSiguienteNivel = 'Máximo Nivel';
    double progresoPuntos = 1.0;
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
      progresoPuntos = (puntosGanadosEnNivel / puntosRango).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.all(Tokens.e6),
      decoration: BoxDecoration(
        gradient: Tokens.degradadoClub,
        borderRadius: BorderRadius.circular(Tokens.radioXl),
        boxShadow: Tokens.haloColor(Tokens.tinta),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado de la tarjeta
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Tokens.e3,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Tokens.arena.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(Tokens.radioPildora),
                  border: Border.all(
                    color: Tokens.arena.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.workspace_premium_rounded,
                      size: 14,
                      color: Tokens.arena,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Nivel $nivel',
                      style: tema.textTheme.labelMedium?.copyWith(
                        color: Tokens.arena,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                '$puntos pts',
                style: tema.textTheme.titleSmall?.copyWith(color: blanco70),
              ),
            ],
          ),

          const SizedBox(height: Tokens.e8),

          Text(
            'DISPONIBLE PARA COMPRAR',
            style: tema.textTheme.labelSmall?.copyWith(
              color: blanco45,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: Tokens.e2),
          Text(
            '\$${disponible.toStringAsFixed(2)}',
            style: tema.textTheme.displayMedium?.copyWith(color: Colors.white),
          ),

          const SizedBox(height: Tokens.e5),

          ClipRRect(
            borderRadius: BorderRadius.circular(Tokens.radioPildora),
            child: LinearProgressIndicator(
              value: progreso,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: Tokens.e4),

          Row(
            children: [
              _DatoTarjeta(
                etiqueta: 'Deuda total',
                valor: '\$${deuda.toStringAsFixed(2)}',
              ),
              const Spacer(),
              _DatoTarjeta(
                etiqueta: 'Límite total',
                valor: '\$${limite.toStringAsFixed(2)}',
                alineadoDerecha: true,
              ),
            ],
          ),

          if (niveles.isNotEmpty && puntosSiguienteNivel > 0) ...[
            const SizedBox(height: Tokens.e5),
            Divider(color: Colors.white.withValues(alpha: 0.12), height: 1),
            const SizedBox(height: Tokens.e4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Para nivel $nombreSiguienteNivel',
                    style: tema.textTheme.bodySmall?.copyWith(color: blanco70),
                  ),
                ),
                Text(
                  '$puntos / $puntosSiguienteNivel pts',
                  style: tema.textTheme.labelMedium?.copyWith(
                    color: Tokens.arena,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Tokens.e3),
            ClipRRect(
              borderRadius: BorderRadius.circular(Tokens.radioPildora),
              child: LinearProgressIndicator(
                value: progresoPuntos,
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: const AlwaysStoppedAnimation<Color>(Tokens.arena),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DatoTarjeta extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final bool alineadoDerecha;

  const _DatoTarjeta({
    required this.etiqueta,
    required this.valor,
    this.alineadoDerecha = false,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: alineadoDerecha
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          etiqueta.toUpperCase(),
          style: tema.textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          valor,
          style: tema.textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

// ─────────────────────────── Plan de cuotas ───────────────────────────

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

    // Si no hay número en DB, usamos uno por defecto
    final numeroFinal = numeroAdmin.isEmpty ? "584240000000" : numeroAdmin;
    final uri = Enlaces.whatsapp(telefono: numeroFinal, mensaje: mensaje);
    if (uri != null) {
      await Enlaces.abrir(uri);
    }

    _cargarCuotas(); // Refrescar

    if (mounted) {
      Avisos.atencion(context, 'Pago reportado. Esperando aprobación.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final montoFinanciado =
        widget.plan['monto_financiado']?.toString() ?? '0.0';

    if (_cargando) {
      return const Esqueleto(alto: 150, radio: Tokens.radioLg);
    }

    final pagadas = _cuotas.where((c) => c['estado'] == 'PAGADA').length;

    return TarjetaSuave(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabecera del plan
          Padding(
            padding: const EdgeInsets.all(Tokens.e5),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan de \$$montoFinanciado',
                        style: tema.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Referencia ${widget.plan['id'].toString().split('-').first.toUpperCase()}',
                        style: tema.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Pildora(
                  texto: '$pagadas de ${_cuotas.length} pagadas',
                  color: pagadas == _cuotas.length
                      ? Tokens.exito
                      : Tokens.tintaMedia,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cuotas
          for (int i = 0; i < _cuotas.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: Tokens.e5 + 44),
            _FilaCuota(
              cuota: _cuotas[i],
              numero: i + 1,
              alPagar: _confirmarPago,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilaCuota extends StatelessWidget {
  final Map<String, dynamic> cuota;
  final int numero;
  final Future<void> Function(String cuotaId, double monto) alPagar;

  const _FilaCuota({
    required this.cuota,
    required this.numero,
    required this.alPagar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    final estado = cuota['estado'];
    final monto = double.parse(cuota['monto'].toString());
    final recargo = double.parse((cuota['cargo_retraso'] ?? 0).toString());
    final total = monto + recargo;
    final vencimiento = DateTime.parse(cuota['fecha_vencimiento']);

    late final Color color;
    late final IconData icono;
    late final String etiqueta;

    switch (estado) {
      case 'PAGADA':
        color = Tokens.exito;
        icono = Icons.check_rounded;
        etiqueta = 'Pagada';
      case 'REPORTADO':
        color = Tokens.arenaProfundo;
        icono = Icons.schedule_rounded;
        etiqueta = 'En revisión';
      case 'VENCIDA':
        color = Tokens.peligro;
        icono = Icons.priority_high_rounded;
        etiqueta = 'Vencida';
      default:
        color = Tokens.tintaMedia;
        icono = Icons.calendar_today_rounded;
        etiqueta = 'Pendiente';
    }

    final pagable = estado == 'PENDIENTE' || estado == 'VENCIDA';

    return Padding(
      padding: const EdgeInsets.all(Tokens.e5),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Icon(icono, size: 17, color: color),
          ),
          const SizedBox(width: Tokens.e3 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Cuota $numero',
                      style: tema.textTheme.titleSmall,
                    ),
                    const SizedBox(width: Tokens.e2),
                    Pildora(texto: etiqueta, color: color, compacta: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Vence el ${DateFormat('d MMM y').format(vencimiento)}'
                  '${recargo > 0 ? ' · recargo \$${recargo.toStringAsFixed(2)}' : ''}',
                  style: tema.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: Tokens.e2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: tema.textTheme.titleLarge,
              ),
              if (pagable) ...[
                const SizedBox(height: Tokens.e2),
                SizedBox(
                  height: 34,
                  width: 96,
                  child: BotonPrincipal(
                    texto: 'Pagar',
                    altura: 34,
                    alPresionar: () => alPagar(cuota['id'], total),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
