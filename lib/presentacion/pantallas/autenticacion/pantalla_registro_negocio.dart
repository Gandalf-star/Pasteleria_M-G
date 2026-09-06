import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../nucleo/constantes/tipos_negocio.dart';
import '../../../nucleo/tema/tokens_app.dart';
import '../../../nucleo/utilidades/validadores.dart';
import '../../../repositorios/repositorio_autenticacion.dart';
import '../../widgets/componentes.dart';

class PantallaRegistroNegocio extends ConsumerStatefulWidget {
  const PantallaRegistroNegocio({super.key});

  @override
  ConsumerState<PantallaRegistroNegocio> createState() =>
      _PantallaRegistroNegocioState();
}

class _PantallaRegistroNegocioState
    extends ConsumerState<PantallaRegistroNegocio> {
  final _formKey = GlobalKey<FormState>();
  final _nombreNegocioCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _cargando = false;
  bool _mostrarContrasena = false;
  String? _tipoSeleccionado;

  @override
  void dispose() {
    _nombreNegocioCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_tipoSeleccionado == null) {
      Avisos.atencion(context, 'Selecciona el tipo de negocio.');
      return;
    }

    setState(() => _cargando = true);
    try {
      final auth = ref.read(proveedorRepositorioAutenticacion);
      await auth.registrarNegocio(
        correo: Validadores.normalizarCorreo(_correoCtrl.text),
        contrasena: _contrasenaCtrl.text,
        nombreNegocio: _nombreNegocioCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        tipoNegocio: _tipoSeleccionado!,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              size: 34,
              color: Tokens.exito,
            ),
            title: const Text('Solicitud enviada'),
            content: Text(
              'Tu negocio "${_nombreNegocioCtrl.text.trim()}" está en revisión. '
              'Te avisaremos en cuanto sea aprobado para que puedas empezar '
              'a vender.',
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
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Entendido'),
                ),
              ),
            ],
          ),
        );
        // Cerrar sesión después de registrarse (no tiene acceso hasta aprobación)
        await auth.cerrarSesion();
      }
    } catch (e) {
      if (mounted) Avisos.error(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarSelectorTipo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Tokens.superficie,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(Tokens.radioXl),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: Tokens.e3),
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Tokens.lineaFuerte,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Tokens.e6,
                      Tokens.e5,
                      Tokens.e6,
                      Tokens.e4,
                    ),
                    child: const EncabezadoSeccion(
                      antetitulo: 'Categoría',
                      titulo: 'Tipo de negocio',
                      descripcion:
                          'Elige la categoría que mejor describe tu tienda.',
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        Tokens.e5,
                        0,
                        Tokens.e5,
                        Tokens.e8,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: Tokens.e3,
                            crossAxisSpacing: Tokens.e3,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: tiposNegocioDisponibles.length,
                      itemBuilder: (context, index) {
                        final tipo = tiposNegocioDisponibles[index];
                        final seleccionado = _tipoSeleccionado == tipo.clave;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _tipoSeleccionado = tipo.clave);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: seleccionado
                                  ? Tokens.rosaVelo
                                  : Tokens.superficieSuave,
                              borderRadius: BorderRadius.circular(
                                Tokens.radioSm,
                              ),
                              border: Border.all(
                                color: seleccionado
                                    ? Tokens.rosa
                                    : Tokens.linea,
                                width: seleccionado ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tipo.icono,
                                  size: 26,
                                  color: seleccionado
                                      ? Tokens.rosaProfundo
                                      : Tokens.tintaMedia,
                                ),
                                const SizedBox(height: Tokens.e2),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    tipo.etiqueta,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontSize: 11.5,
                                          color: seleccionado
                                              ? Tokens.rosaProfundo
                                              : Tokens.tintaMedia,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final infoTipo = _tipoSeleccionado != null
        ? obtenerInfoTipo(_tipoSeleccionado!)
        : null;

    return Scaffold(
      body: FondoAtelier(
        child: SafeArea(
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
                    const Antetitulo('Alta de comercio'),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    Tokens.e6,
                    Tokens.e6,
                    Tokens.e6,
                    Tokens.e12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child:
                                  Container(
                                        padding: const EdgeInsets.all(
                                          Tokens.e5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Tokens.superficie,
                                          borderRadius: BorderRadius.circular(
                                            Tokens.radioLg,
                                          ),
                                          border: Border.all(
                                            color: Tokens.linea,
                                          ),
                                          boxShadow: Tokens.sombraSuave,
                                        ),
                                        child: Image.asset(
                                          'assets/imagenes/compra_ya_logo.png',
                                          height: 56,
                                        ),
                                      )
                                      .animate()
                                      .scale(
                                        duration: 600.ms,
                                        curve: Curves.easeOutBack,
                                        begin: const Offset(0.8, 0.8),
                                      )
                                      .fadeIn(),
                            ),
                            const SizedBox(height: Tokens.e6),
                            Text(
                              'Crea tu tienda digital',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.displaySmall,
                            ),
                            const SizedBox(height: Tokens.e3),
                            Text(
                              'Registra tu negocio y empieza a vender con un '
                              'asistente que atiende a tus clientes.',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: Tokens.e8),

                            TarjetaSuave(
                              padding: const EdgeInsets.all(Tokens.e6),
                              sombra: Tokens.sombraMedia,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Selector de tipo
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 2,
                                      bottom: Tokens.e2,
                                    ),
                                    child: Text(
                                      'Tipo de negocio',
                                      style: tema.textTheme.labelMedium
                                          ?.copyWith(color: Tokens.tintaMedia),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _cargando ? null : _mostrarSelectorTipo,
                                    borderRadius: BorderRadius.circular(
                                      Tokens.radioSm,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: Tokens.e5,
                                        vertical: Tokens.e4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Tokens.superficie,
                                        borderRadius: BorderRadius.circular(
                                          Tokens.radioSm,
                                        ),
                                        border: Border.all(
                                          color: infoTipo != null
                                              ? Tokens.rosa
                                              : Tokens.linea,
                                          width: infoTipo != null ? 1.6 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            infoTipo?.icono ??
                                                Icons.storefront_outlined,
                                            size: 19,
                                            color: infoTipo != null
                                                ? Tokens.rosaProfundo
                                                : Tokens.tintaSuave,
                                          ),
                                          const SizedBox(width: Tokens.e3 + 2),
                                          Expanded(
                                            child: Text(
                                              infoTipo?.etiqueta ??
                                                  'Selecciona una categoría',
                                              style: tema.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w500,
                                                    color: infoTipo != null
                                                        ? Tokens.tinta
                                                        : Tokens.tintaSuave,
                                                  ),
                                            ),
                                          ),
                                          const Icon(
                                            Icons.expand_more_rounded,
                                            size: 20,
                                            color: Tokens.tintaSuave,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: Tokens.e5),

                                  CampoTexto(
                                    controlador: _nombreNegocioCtrl,
                                    etiqueta: 'Nombre del negocio',
                                    pista: 'Cómo te conocen tus clientes',
                                    icono: Icons.storefront_outlined,
                                    validador: Validadores.requerido,
                                  ),
                                  const SizedBox(height: Tokens.e5),
                                  CampoTexto(
                                    controlador: _correoCtrl,
                                    etiqueta: 'Correo electrónico',
                                    pista: 'contacto@tunegocio.com',
                                    icono: Icons.alternate_email_rounded,
                                    teclado: TextInputType.emailAddress,
                                    validador: Validadores.correo,
                                  ),
                                  const SizedBox(height: Tokens.e5),
                                  CampoTexto(
                                    controlador: _telefonoCtrl,
                                    etiqueta: 'Teléfono de contacto',
                                    pista: 'Con código de país',
                                    icono: Icons.phone_iphone_rounded,
                                    teclado: TextInputType.phone,
                                    validador: Validadores.requerido,
                                  ),
                                  const SizedBox(height: Tokens.e5),
                                  CampoTexto(
                                    controlador: _contrasenaCtrl,
                                    etiqueta: 'Contraseña',
                                    pista: 'Mínimo 6 caracteres',
                                    icono: Icons.lock_outline_rounded,
                                    esClave: !_mostrarContrasena,
                                    sufijo: IconButton(
                                      icon: Icon(
                                        _mostrarContrasena
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        size: 19,
                                      ),
                                      onPressed: () => setState(
                                        () => _mostrarContrasena =
                                            !_mostrarContrasena,
                                      ),
                                    ),
                                    validador: Validadores.contrasena,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: Tokens.e6),

                            BotonPrincipal(
                              texto: 'Enviar solicitud',
                              icono: Icons.send_rounded,
                              cargando: _cargando,
                              alPresionar: _registrar,
                            ),
                            const SizedBox(height: Tokens.e4),
                            Text(
                              'Revisamos cada solicitud manualmente. '
                              'Suele tomar menos de 24 horas.',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodySmall,
                            ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
