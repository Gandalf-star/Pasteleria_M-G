import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../repositorios/repositorio_autenticacion.dart';
import '../../../nucleo/constantes/tipos_negocio.dart';

class PantallaRegistroNegocio extends ConsumerStatefulWidget {
  const PantallaRegistroNegocio({super.key});

  @override
  ConsumerState<PantallaRegistroNegocio> createState() => _PantallaRegistroNegocioState();
}

class _PantallaRegistroNegocioState extends ConsumerState<PantallaRegistroNegocio> {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor selecciona el tipo de negocio'),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final auth = ref.read(proveedorRepositorioAutenticacion);
      await auth.registrarNegocio(
        correo: _correoCtrl.text.trim(),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            icon: const Icon(Icons.check_circle_rounded, size: 56, color: Color(0xFF10B981)),
            title: Text('¡Solicitud Enviada!', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            content: Text(
              'Tu negocio "${_nombreNegocioCtrl.text.trim()}" está en proceso de revisión.\n\nTe notificaremos cuando sea aprobado para que puedas empezar a vender.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
        // Cerrar sesión después de registrarse (no tiene acceso hasta aprobación)
        await auth.cerrarSesion();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Selecciona el tipo de negocio',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
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
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(16),
                              border: seleccionado
                                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                                  : null,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  tipo.icono,
                                  size: 32,
                                  color: seleccionado
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tipo.etiqueta,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
                                    color: seleccionado
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.onSurface,
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
    final infoTipo = _tipoSeleccionado != null ? obtenerInfoTipo(_tipoSeleccionado!) : null;

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Fondo oscuro premium con destellos (mesh gradient simulado)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tema.colorScheme.primaryContainer.withAlpha(51),
                boxShadow: [
                  BoxShadow(
                    color: tema.colorScheme.primaryContainer.withAlpha(51),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).move(
                duration: 10.seconds,
                begin: const Offset(0, 0),
                end: const Offset(-50, 50),
                curve: Curves.easeInOutSine,
              ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tema.colorScheme.secondary.withAlpha(38),
                boxShadow: [
                  BoxShadow(
                    color: tema.colorScheme.secondary.withAlpha(38),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).move(
                duration: 8.seconds,
                begin: const Offset(0, 0),
                end: const Offset(30, -30),
                curve: Curves.easeInOutSine,
              ),
          SafeArea(
          child: Column(
            children: [
              // AppBar manual
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Registro de Negocio',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance visual
                  ],
                ),
              ),
              // Formulario
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(15),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(30),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Ícono central
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withAlpha(10),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(color: Colors.white.withAlpha(25), width: 1.5),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Image.asset(
                                          'assets/imagenes/compra_ya_logo.png',
                                          height: 60,
                                        ),
                                      ),
                                    ),
                                  ),
                                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                                const SizedBox(height: 8),
                                Text(
                                  'Crea tu tienda digital',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Selector de tipo de negocio
                                GestureDetector(
                                  onTap: _cargando ? null : _mostrarSelectorTipo,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(13),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _tipoSeleccionado != null
                                            ? Colors.white
                                            : Colors.white.withAlpha(77),
                                        width: _tipoSeleccionado != null ? 2 : 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          infoTipo?.icono ?? Icons.category_outlined,
                                          color: Colors.white.withAlpha(179),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            infoTipo?.etiqueta ?? 'Tipo de negocio *',
                                            style: TextStyle(
                                              color: infoTipo != null
                                                  ? Colors.white
                                                  : Colors.white.withAlpha(179),
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_drop_down,
                                          color: Colors.white.withAlpha(179),
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 200.ms).fadeIn(),
                                const SizedBox(height: 16),

                                _construirCampo(
                                  controlador: _nombreNegocioCtrl,
                                  etiqueta: 'Nombre del negocio',
                                  icono: Icons.business_rounded,
                                  validador: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                                ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 300.ms).fadeIn(),
                                const SizedBox(height: 16),
                                _construirCampo(
                                  controlador: _correoCtrl,
                                  etiqueta: 'Correo electrónico',
                                  icono: Icons.email_outlined,
                                  tipoTeclado: TextInputType.emailAddress,
                                  validador: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                                    if (!v.contains('@')) return 'Correo inválido';
                                    return null;
                                  },
                                ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 400.ms).fadeIn(),
                                const SizedBox(height: 16),
                                _construirCampo(
                                  controlador: _telefonoCtrl,
                                  etiqueta: 'Teléfono de contacto',
                                  icono: Icons.phone_outlined,
                                  tipoTeclado: TextInputType.phone,
                                  validador: (v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
                                ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 500.ms).fadeIn(),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _contrasenaCtrl,
                                  obscureText: !_mostrarContrasena,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Contraseña',
                                    labelStyle: TextStyle(color: Colors.white.withAlpha(179)),
                                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white.withAlpha(179)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _mostrarContrasena ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.white.withAlpha(179),
                                      ),
                                      onPressed: () => setState(() => _mostrarContrasena = !_mostrarContrasena),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.white.withAlpha(77)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(color: Colors.white, width: 2),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.red.shade300),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(color: Colors.red.shade300, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white.withAlpha(13),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Campo requerido';
                                    if (v.length < 6) return 'Mínimo 6 caracteres';
                                    return null;
                                  },
                                ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 600.ms).fadeIn(),
                                const SizedBox(height: 28),
                                SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _cargando ? null : _registrar,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: tema.colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _cargando
                                        ? SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: tema.colorScheme.primary,
                                            ),
                                          )
                                        : Text(
                                            'Enviar Solicitud',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ).animate().slideY(begin: 0.2, duration: 600.ms, delay: 700.ms).fadeIn(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
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

  Widget _construirCampo({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    TextInputType tipoTeclado = TextInputType.text,
    String? Function(String?)? validador,
  }) {
    return TextFormField(
      controller: controlador,
      keyboardType: tipoTeclado,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: etiqueta,
        labelStyle: TextStyle(color: Colors.white.withAlpha(179)),
        prefixIcon: Icon(icono, color: Colors.white.withAlpha(179)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withAlpha(77)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withAlpha(13),
      ),
      validator: validador,
    );
  }
}
