import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../nucleo/tema/tokens_app.dart';

/// Biblioteca de componentes compartidos del sistema "Atelier Pastel".
/// Todas las pantallas construyen su UI a partir de estas piezas para
/// mantener una sola voz visual.

// ─────────────────────────── Fondo decorativo ───────────────────────────

/// Lienzo con veladuras pastel difuminadas. Sustituye a los círculos
/// planos por manchas suaves que dan profundidad sin ruido.
class FondoAtelier extends StatelessWidget {
  final Widget child;
  final bool intenso;

  const FondoAtelier({super.key, required this.child, this.intenso = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: Tokens.lienzo),
          ),
        ),
        Positioned(
          top: -140,
          right: -110,
          child: _Velo(
            color: Tokens.rosaSuave,
            tamano: 340,
            opacidad: intenso ? 0.95 : 0.7,
          ),
        ),
        Positioned(
          top: 160,
          left: -160,
          child: _Velo(
            color: Tokens.arenaSuave,
            tamano: 300,
            opacidad: intenso ? 0.8 : 0.55,
          ),
        ),
        Positioned(
          bottom: -180,
          right: -60,
          child: _Velo(
            color: Tokens.salviaSuave,
            tamano: 380,
            opacidad: intenso ? 0.8 : 0.5,
          ),
        ),
        child,
      ],
    );
  }
}

class _Velo extends StatelessWidget {
  final Color color;
  final double tamano;
  final double opacidad;

  const _Velo({
    required this.color,
    required this.tamano,
    required this.opacidad,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: tamano,
        height: tamano,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacidad),
              color.withValues(alpha: 0),
            ],
            stops: const [0.35, 1],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Superficies ───────────────────────────

/// Tarjeta base: fondo blanco, borde capilar y sombra muy tenue.
class TarjetaSuave extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double radio;
  final Color? color;
  final Color? colorBorde;
  final List<BoxShadow>? sombra;
  final VoidCallback? alTocar;

  const TarjetaSuave({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Tokens.e5),
    this.margin,
    this.radio = Tokens.radioLg,
    this.color,
    this.colorBorde,
    this.sombra,
    this.alTocar,
  });

  @override
  Widget build(BuildContext context) {
    final contenido = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? Tokens.superficie,
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: colorBorde ?? Tokens.linea),
        boxShadow: sombra ?? Tokens.sombraSuave,
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
    );

    if (alTocar == null) return contenido;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(radio),
        child: contenido,
      ),
    );
  }
}

// ─────────────────────────── Marca ───────────────────────────

/// Monograma de la pastelería: sello circular con el ícono de tarta.
class SelloMarca extends StatelessWidget {
  final double tamano;
  final bool conAnillo;

  const SelloMarca({super.key, this.tamano = 72, this.conAnillo = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamano,
      height: tamano,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: Tokens.degradadoMarca,
        boxShadow: Tokens.haloColor(Tokens.rosa),
        border: conAnillo
            ? Border.all(color: Colors.white.withValues(alpha: 0.85), width: 3)
            : null,
      ),
      child: Icon(
        Icons.cake_rounded,
        size: tamano * 0.42,
        color: Colors.white,
      ),
    );
  }
}

/// Bloque de marca completo: sello + nombre + firma.
class FirmaMarca extends StatelessWidget {
  final double tamanoSello;
  final double tamanoTitulo;
  final bool mostrarLema;
  final Color? colorTexto;

  const FirmaMarca({
    super.key,
    this.tamanoSello = 64,
    this.tamanoTitulo = 26,
    this.mostrarLema = true,
    this.colorTexto,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SelloMarca(tamano: tamanoSello),
        const SizedBox(height: Tokens.e4),
        Text(
          'Pastelería M&G',
          textAlign: TextAlign.center,
          style: tema.textTheme.displaySmall?.copyWith(
            fontSize: tamanoTitulo,
            color: colorTexto ?? Tokens.tinta,
          ),
        ),
        if (mostrarLema) ...[
          const SizedBox(height: Tokens.e2),
          Text(
            'REPOSTERÍA ARTESANAL',
            style: tema.textTheme.labelSmall?.copyWith(
              color: colorTexto?.withValues(alpha: 0.7) ?? Tokens.tintaSuave,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────── Etiquetas ───────────────────────────

/// Píldora de estado / categoría.
class Pildora extends StatelessWidget {
  final String texto;
  final IconData? icono;
  final Color color;
  final Color? fondo;
  final bool compacta;

  const Pildora({
    super.key,
    required this.texto,
    this.icono,
    this.color = Tokens.rosaProfundo,
    this.fondo,
    this.compacta = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compacta ? Tokens.e2 + 2 : Tokens.e3,
        vertical: compacta ? 3 : 6,
      ),
      decoration: BoxDecoration(
        color: fondo ?? color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(Tokens.radioPildora),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icono != null) ...[
            Icon(icono, size: compacta ? 12 : 14, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            texto,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontSize: compacta ? 11 : 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Antetítulo tipográfico en versalitas usado sobre los títulos de sección.
class Antetitulo extends StatelessWidget {
  final String texto;
  final Color? color;

  const Antetitulo(this.texto, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto.toUpperCase(),
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: color ?? Tokens.rosa),
    );
  }
}

/// Encabezado de sección: antetítulo + título + acción opcional.
class EncabezadoSeccion extends StatelessWidget {
  final String titulo;
  final String? antetitulo;
  final String? descripcion;
  final Widget? accion;

  const EncabezadoSeccion({
    super.key,
    required this.titulo,
    this.antetitulo,
    this.descripcion,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (antetitulo != null) ...[
                Antetitulo(antetitulo!),
                const SizedBox(height: Tokens.e2),
              ],
              Text(titulo, style: tema.textTheme.headlineSmall),
              if (descripcion != null) ...[
                const SizedBox(height: Tokens.e1 + 2),
                Text(descripcion!, style: tema.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (accion != null) accion!,
      ],
    );
  }
}

/// Filete decorativo: línea fina con un rombo centrado.
class Filete extends StatelessWidget {
  final Color color;
  final double ancho;

  const Filete({super.key, this.color = Tokens.lineaFuerte, this.ancho = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ancho,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tokens.e2),
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(width: 5, height: 5, color: color),
            ),
          ),
          Expanded(child: Container(height: 1, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────── Botones ───────────────────────────

/// Botón principal con degradado de marca, halo suave y estado de carga.
class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;
  final bool cargando;
  final Gradient? degradado;
  final Color colorHalo;
  final double altura;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.cargando = false,
    this.degradado,
    this.colorHalo = Tokens.rosa,
    this.altura = 56,
  });

  @override
  Widget build(BuildContext context) {
    final habilitado = alPresionar != null && !cargando;
    return Opacity(
      opacity: habilitado ? 1 : 0.55,
      child: Container(
        height: altura,
        decoration: BoxDecoration(
          gradient: degradado ?? Tokens.degradadoMarca,
          borderRadius: BorderRadius.circular(Tokens.radioSm),
          boxShadow: habilitado ? Tokens.haloColor(colorHalo) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: habilitado ? alPresionar : null,
            borderRadius: BorderRadius.circular(Tokens.radioSm),
            child: Center(
              child: cargando
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icono != null) ...[
                          Icon(icono, size: 19, color: Colors.white),
                          const SizedBox(width: Tokens.e2 + 2),
                        ],
                        Text(
                          texto,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón secundario: superficie blanca, borde capilar, sin ruido.
class BotonContorno extends StatelessWidget {
  final String texto;
  final VoidCallback? alPresionar;
  final IconData? icono;
  final Color color;
  final Color? colorFondo;
  final double altura;

  const BotonContorno({
    super.key,
    required this.texto,
    required this.alPresionar,
    this.icono,
    this.color = Tokens.tinta,
    this.colorFondo,
    this.altura = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: altura,
      child: Material(
        color: colorFondo ?? Tokens.superficie,
        borderRadius: BorderRadius.circular(Tokens.radioSm),
        child: InkWell(
          onTap: alPresionar,
          borderRadius: BorderRadius.circular(Tokens.radioSm),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Tokens.radioSm),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icono != null) ...[
                    Icon(icono, size: 19, color: color),
                    const SizedBox(width: Tokens.e2 + 2),
                  ],
                  Text(
                    texto,
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Formularios ───────────────────────────

/// Campo de texto con etiqueta tipográfica encima del control, más
/// legible y elegante que la etiqueta flotante de Material.
class CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final String? pista;
  final IconData? icono;
  final bool esClave;
  final Widget? sufijo;
  final TextInputType teclado;
  final int maxLineas;
  final String? Function(String?)? validador;
  final void Function(String)? alEnviar;

  const CampoTexto({
    super.key,
    required this.controlador,
    required this.etiqueta,
    this.pista,
    this.icono,
    this.esClave = false,
    this.sufijo,
    this.teclado = TextInputType.text,
    this.maxLineas = 1,
    this.validador,
    this.alEnviar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: Tokens.e2),
          child: Text(
            etiqueta,
            style: tema.textTheme.labelMedium?.copyWith(
              color: Tokens.tintaMedia,
            ),
          ),
        ),
        TextFormField(
          controller: controlador,
          obscureText: esClave,
          keyboardType: teclado,
          maxLines: esClave ? 1 : maxLineas,
          validator: validador,
          onFieldSubmitted: alEnviar,
          style: tema.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: pista,
            prefixIcon: icono == null ? null : Icon(icono, size: 19),
            suffixIcon: sufijo,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────── Estados ───────────────────────────

/// Estado vacío ilustrado con acción opcional.
class EstadoVacio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  const EstadoVacio({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.e8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Tokens.superficieSuave,
              ),
              child: Icon(icono, size: 38, color: Tokens.tintaSuave),
            ),
            const SizedBox(height: Tokens.e6),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: tema.textTheme.headlineSmall,
            ),
            if (mensaje != null) ...[
              const SizedBox(height: Tokens.e2),
              Text(
                mensaje!,
                textAlign: TextAlign.center,
                style: tema.textTheme.bodyMedium,
              ),
            ],
            if (accion != null) ...[
              const SizedBox(height: Tokens.e6),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Indicador de carga discreto y centrado.
class Cargando extends StatelessWidget {
  final String? mensaje;

  const Cargando({super.key, this.mensaje});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
          if (mensaje != null) ...[
            const SizedBox(height: Tokens.e4),
            Text(mensaje!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Bloque rectangular con brillo, usado como esqueleto de carga.
class Esqueleto extends StatefulWidget {
  final double alto;
  final double? ancho;
  final double radio;

  const Esqueleto({
    super.key,
    required this.alto,
    this.ancho,
    this.radio = Tokens.radioSm,
  });

  @override
  State<Esqueleto> createState() => _EsqueletoState();
}

class _EsqueletoState extends State<Esqueleto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        return Container(
          height: widget.alto,
          width: widget.ancho ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radio),
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: const [
                Tokens.superficieSuave,
                Color(0xFFFDF9F6),
                Tokens.superficieSuave,
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────── Avisos ───────────────────────────

/// Aviso contextual con color semántico (info, éxito, alerta, error).
class Aviso extends StatelessWidget {
  final String titulo;
  final String? detalle;
  final IconData icono;
  final Color color;
  final Color fondo;
  final Widget? accion;

  const Aviso({
    super.key,
    required this.titulo,
    required this.icono,
    required this.color,
    required this.fondo,
    this.detalle,
    this.accion,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Tokens.e4),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(Tokens.radioMd),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(Tokens.radioXs),
            ),
            child: Icon(icono, size: 18, color: color),
          ),
          const SizedBox(width: Tokens.e3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: tema.textTheme.titleSmall?.copyWith(color: color),
                ),
                if (detalle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    detalle!,
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: Tokens.tintaMedia,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (accion != null) ...[const SizedBox(width: Tokens.e2), accion!],
        ],
      ),
    );
  }
}

// ─────────────────────────── Utilidades ───────────────────────────

/// Barras de notificación coherentes con el sistema de diseño.
class Avisos {
  const Avisos._();

  static void mostrar(
    BuildContext context, {
    required String mensaje,
    IconData icono = Icons.info_outline_rounded,
    Color color = Tokens.tinta,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icono, color: Colors.white, size: 19),
              const SizedBox(width: Tokens.e3),
              Expanded(
                child: Text(
                  mensaje,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(Tokens.e4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioSm),
          ),
        ),
      );
  }

  static void exito(BuildContext context, String mensaje) => mostrar(
    context,
    mensaje: mensaje,
    icono: Icons.check_circle_outline_rounded,
    color: Tokens.exito,
  );

  static void error(BuildContext context, String mensaje) => mostrar(
    context,
    mensaje: mensaje,
    icono: Icons.error_outline_rounded,
    color: Tokens.peligro,
  );

  static void atencion(BuildContext context, String mensaje) => mostrar(
    context,
    mensaje: mensaje,
    icono: Icons.schedule_rounded,
    color: Tokens.arenaProfundo,
  );
}

/// Botón circular de navegación para las AppBar (volver, acciones).
class BotonCircular extends StatelessWidget {
  final IconData icono;
  final VoidCallback? alPresionar;
  final String? tooltip;
  final Color? color;

  const BotonCircular({
    super.key,
    required this.icono,
    required this.alPresionar,
    this.tooltip,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Tokens.superficie,
        shape: const CircleBorder(
          side: BorderSide(color: Tokens.linea),
        ),
        child: InkWell(
          onTap: alPresionar,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(icono, size: 19, color: color ?? Tokens.tinta),
          ),
        ),
      ),
    );
  }
}
