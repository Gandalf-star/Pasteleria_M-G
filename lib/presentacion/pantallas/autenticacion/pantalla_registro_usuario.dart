import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../repositorios/repositorio_autenticacion.dart';
import '../../../../repositorios/repositorio_almacenamiento.dart';

class PantallaRegistroUsuario extends ConsumerStatefulWidget {
  const PantallaRegistroUsuario({super.key});

  @override
  ConsumerState<PantallaRegistroUsuario> createState() =>
      _PantallaRegistroUsuarioState();
}

class _PantallaRegistroUsuarioState
    extends ConsumerState<PantallaRegistroUsuario> {
  final _formKey = GlobalKey<FormState>();
  final _controladorNombre = TextEditingController();
  final _controladorCedula = TextEditingController();
  final _controladorTelefono = TextEditingController();
  final _controladorDireccion = TextEditingController();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();

  bool _cargando = false;
  File? _fotoPerfil;
  File? _fotoCedula;
  final _picker = ImagePicker();

  Future<void> _seleccionarFotoPerfil() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (imagen != null) {
      setState(() => _fotoPerfil = File(imagen.path));
    }
  }

  Future<void> _seleccionarFotoCedula() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.camera, // Usar cámara por defecto para cédula
      imageQuality: 80,
    );
    if (imagen != null) {
      setState(() => _fotoCedula = File(imagen.path));
    }
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoPerfil == null || _fotoCedula == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona tu foto de perfil y captura tu cédula')),
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final repoAuth = ref.read(proveedorRepositorioAutenticacion);
      final repoAlmacenamiento = ref.read(proveedorRepositorioAlmacenamiento);

      // 1. Subir fotos de forma paralela (perfil y cédula)
      final urlFoto = await repoAlmacenamiento.subirArchivoPerfil(_fotoPerfil!);
      final urlCedula = await repoAlmacenamiento.subirArchivoCedula(_fotoCedula!);

      // 2. Registrar usuario y guardar todos los datos en tabla 'clientes'
      await repoAuth.registrarUsuario(
        nombre: _controladorNombre.text.trim(),
        correo: _controladorCorreo.text.trim(),
        contrasena: _controladorContrasena.text,
        cedula: _controladorCedula.text.trim(),
        telefono: _controladorTelefono.text.trim(),
        direccion: _controladorDireccion.text.trim(),
        fotoUrl: urlFoto,
        fotoCedulaUrl: urlCedula,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('¡Registro exitoso! Bienvenido a Pasteleria M&G.', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
        
        // Pequeña pausa para que el usuario lea el mensaje
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/inicial', (route) => false);
        }
      }
    } catch (e) {
      if (mounted) {
        String mensajeError = 'Ocurrió un error inesperado.';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('already registered') || errorStr.contains('user_already_exists')) {
          mensajeError = 'Este correo ya está registrado. Por favor, inicia sesión.';
        } else {
          mensajeError = 'Error: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(mensajeError)),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    
    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: tema.colorScheme.primary),
        title: Text(
          'Crear Cuenta',
          style: GoogleFonts.outfit(
            color: tema.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(
                  '¡Únete a la dulzura!',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: tema.textTheme.displayLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completa tus datos para disfrutar de nuestros deliciosos postres',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: tema.textTheme.bodyMedium?.color,
                  ),
                ),
                const SizedBox(height: 32),

                // Selector de Imagen
                GestureDetector(
                  onTap: _seleccionarFotoPerfil,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(color: tema.colorScheme.primary, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: tema.colorScheme.primary.withAlpha(50),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: _fotoPerfil != null
                        ? ClipOval(
                            child: Image.file(
                              _fotoPerfil!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person_add_rounded,
                            size: 40,
                            color: tema.colorScheme.primary,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _seleccionarFotoPerfil,
                  child: Text(
                    'Elegir foto de perfil',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: tema.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Nombre
                _CampoTexto(
                  controlador: _controladorNombre,
                  etiqueta: 'Nombre completo',
                  icono: Icons.person_outline_rounded,
                  validador: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                // Cédula
                _CampoTexto(
                  controlador: _controladorCedula,
                  etiqueta: 'Número de Cédula',
                  icono: Icons.badge_outlined,
                  teclado: TextInputType.number,
                  validador: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                // Captura Fotográfica de Cédula
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: tema.colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: tema.colorScheme.outlineVariant.withAlpha(100), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Foto de Cédula (Frontal)',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: tema.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _seleccionarFotoCedula,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: tema.colorScheme.primaryContainer.withAlpha(100),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: tema.colorScheme.primary.withAlpha(50), width: 2),
                          ),
                          child: _fotoCedula != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _fotoCedula!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_front_rounded,
                                      size: 48,
                                      color: tema.colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tocar para tomar foto',
                                      style: GoogleFonts.inter(
                                        color: tema.colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Teléfono
                _CampoTexto(
                  controlador: _controladorTelefono,
                  etiqueta: 'Teléfono celular',
                  icono: Icons.phone_android_rounded,
                  teclado: TextInputType.phone,
                  validador: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                // Dirección
                _CampoTexto(
                  controlador: _controladorDireccion,
                  etiqueta: 'Dirección de domicilio',
                  icono: Icons.home_outlined,
                  maxLines: 2,
                  validador: (v) => v!.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                
                // Correo
                _CampoTexto(
                  controlador: _controladorCorreo,
                  etiqueta: 'Correo electrónico',
                  icono: Icons.email_outlined,
                  teclado: TextInputType.emailAddress,
                  validador: (v) => v!.contains('@') ? null : 'Correo inválido',
                ),
                const SizedBox(height: 16),
                
                // Contraseña
                _CampoTexto(
                  controlador: _controladorContrasena,
                  etiqueta: 'Contraseña',
                  icono: Icons.lock_outline_rounded,
                  esClave: true,
                  validador: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ),
                
                const SizedBox(height: 32),

                // Botón Registrar
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tema.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: tema.colorScheme.primary.withAlpha(100),
                    ),
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Crear Mi Cuenta',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CampoTexto extends StatelessWidget {
  final TextEditingController controlador;
  final String etiqueta;
  final IconData icono;
  final bool esClave;
  final TextInputType teclado;
  final int maxLines;
  final String? Function(String?)? validador;

  const _CampoTexto({
    required this.controlador,
    required this.etiqueta,
    required this.icono,
    this.esClave = false,
    this.teclado = TextInputType.text,
    this.maxLines = 1,
    this.validador,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controlador,
      obscureText: esClave,
      keyboardType: teclado,
      maxLines: esClave ? 1 : maxLines,
      validator: validador,
      decoration: InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        filled: true,
      ),
    );
  }
}
