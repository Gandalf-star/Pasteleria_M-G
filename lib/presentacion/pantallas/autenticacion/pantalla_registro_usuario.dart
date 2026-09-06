import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../nucleo/tema/tokens_app.dart';
import '../../../repositorios/repositorio_almacenamiento.dart';
import '../../../repositorios/repositorio_autenticacion.dart';
import '../../widgets/componentes.dart';

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
  bool _ocultarContrasena = true;

  // Guardamos el XFile (para subirlo) y sus bytes (para previsualizarlo).
  // `Image.file` no existe en Web, asi que la vista previa usa `Image.memory`.
  XFile? _fotoPerfil;
  Uint8List? _bytesPerfil;
  XFile? _fotoCedula;
  Uint8List? _bytesCedula;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controladorNombre.dispose();
    _controladorCedula.dispose();
    _controladorTelefono.dispose();
    _controladorDireccion.dispose();
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFotoPerfil() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoPerfil = imagen;
      _bytesPerfil = bytes;
    });
  }

  Future<void> _seleccionarFotoCedula() async {
    // En móvil abrimos la cámara; en la web de escritorio el selector no
    // ofrece cámara, así que caemos al explorador de archivos.
    final XFile? imagen = await _picker.pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
      imageQuality: 80,
    );
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    if (!mounted) return;
    setState(() {
      _fotoCedula = imagen;
      _bytesCedula = bytes;
    });
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fotoPerfil == null || _fotoCedula == null) {
      Avisos.atencion(
        context,
        'Añade tu foto de perfil y la captura de tu cédula.',
      );
      return;
    }

    setState(() => _cargando = true);
    try {
      final repoAuth = ref.read(proveedorRepositorioAutenticacion);
      final repoAlmacenamiento = ref.read(proveedorRepositorioAlmacenamiento);
      final correo = _controladorCorreo.text.trim();

      // 1. Crear la cuenta primero: las subidas y el insert necesitan sesión.
      final userId = await repoAuth.crearCuentaCliente(
        correo: correo,
        contrasena: _controladorContrasena.text,
      );

      // 2. Subir fotos (perfil y cédula) ya autenticados.
      final urlFoto = await repoAlmacenamiento.subirArchivoPerfil(_fotoPerfil!);
      final urlCedula = await repoAlmacenamiento.subirArchivoCedula(
        _fotoCedula!,
      );

      // 3. Guardar la ficha del cliente.
      await repoAuth.guardarDatosCliente(
        userId: userId,
        nombre: _controladorNombre.text.trim(),
        correo: correo,
        cedula: _controladorCedula.text.trim(),
        telefono: _controladorTelefono.text.trim(),
        direccion: _controladorDireccion.text.trim(),
        fotoUrl: urlFoto,
        fotoCedulaUrl: urlCedula,
      );

      if (mounted) {
        Avisos.exito(
          context,
          '¡Registro exitoso! Te damos la bienvenida a Pastelería M&G.',
        );

        // Pequeña pausa para que el usuario lea el mensaje
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/inicial',
            (route) => false,
          );
        }
      }
    } on RegistroFallido catch (e) {
      // El repositorio ya redactó un mensaje apto para el usuario.
      if (mounted) Avisos.error(context, e.mensaje);
    } catch (e) {
      if (mounted) Avisos.error(context, _mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Traduce los errores técnicos a algo accionable para el usuario.
  String _mensajeDeError(Object e) {
    final texto = e.toString();
    final minus = texto.toLowerCase();

    if (minus.contains('already registered') ||
        minus.contains('user_already_exists')) {
      return 'Este correo ya está registrado. Inicia sesión.';
    }
    if (minus.contains('bucket not found')) {
      return 'Falta configurar el almacenamiento de imágenes en Supabase.';
    }
    if (minus.contains('row-level security') ||
        minus.contains('violates row-level') ||
        minus.contains('unauthorized')) {
      return 'No tienes permiso para guardar estos datos. Revisa las políticas '
          'de Supabase.';
    }
    if (minus.contains('failed host lookup') ||
        minus.contains('socketexception') ||
        minus.contains('clientexception')) {
      return 'Sin conexión con el servidor. Revisa tu internet.';
    }
    if (minus.contains('password')) {
      return 'La contraseña no cumple los requisitos mínimos.';
    }
    return 'No pudimos completar el registro: $texto';
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

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
                    const Antetitulo('Nueva cuenta'),
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
                            Text(
                              'Únete a la casa',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.displaySmall,
                            ),
                            const SizedBox(height: Tokens.e3),
                            Text(
                              'Necesitamos unos datos para habilitar tus '
                              'pedidos y tu línea del Club M&G.',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: Tokens.e8),

                            // ── Retrato ────────────────────────────
                            Center(
                              child: _SelectorRetrato(
                                bytes: _bytesPerfil,
                                alTocar: _seleccionarFotoPerfil,
                              ),
                            ),
                            const SizedBox(height: Tokens.e3),
                            Center(
                              child: TextButton(
                                onPressed: _seleccionarFotoPerfil,
                                child: Text(
                                  _fotoPerfil == null
                                      ? 'Añadir foto de perfil'
                                      : 'Cambiar foto de perfil',
                                ),
                              ),
                            ),

                            const SizedBox(height: Tokens.e8),

                            // ── Identidad ──────────────────────────
                            _Seccion(
                              antetitulo: 'Paso 1',
                              titulo: 'Tu identidad',
                              hijos: [
                                CampoTexto(
                                  controlador: _controladorNombre,
                                  etiqueta: 'Nombre completo',
                                  pista: 'Nombre y apellido',
                                  icono: Icons.person_outline_rounded,
                                  validador: (v) => (v ?? '').trim().isEmpty
                                      ? 'Requerido'
                                      : null,
                                ),
                                CampoTexto(
                                  controlador: _controladorCedula,
                                  etiqueta: 'Número de cédula',
                                  pista: 'Solo dígitos',
                                  icono: Icons.badge_outlined,
                                  teclado: TextInputType.number,
                                  validador: (v) => (v ?? '').trim().isEmpty
                                      ? 'Requerido'
                                      : null,
                                ),
                                _CapturaCedula(
                                  bytes: _bytesCedula,
                                  alTocar: _seleccionarFotoCedula,
                                ),
                              ],
                            ),

                            const SizedBox(height: Tokens.e5),

                            // ── Contacto ───────────────────────────
                            _Seccion(
                              antetitulo: 'Paso 2',
                              titulo: 'Dónde te encontramos',
                              hijos: [
                                CampoTexto(
                                  controlador: _controladorTelefono,
                                  etiqueta: 'Teléfono celular',
                                  pista: '0412 000 0000',
                                  icono: Icons.phone_iphone_rounded,
                                  teclado: TextInputType.phone,
                                  validador: (v) => (v ?? '').trim().isEmpty
                                      ? 'Requerido'
                                      : null,
                                ),
                                CampoTexto(
                                  controlador: _controladorDireccion,
                                  etiqueta: 'Dirección de entrega',
                                  pista: 'Calle, edificio, referencia',
                                  icono: Icons.location_on_outlined,
                                  maxLineas: 2,
                                  validador: (v) => (v ?? '').trim().isEmpty
                                      ? 'Requerido'
                                      : null,
                                ),
                              ],
                            ),

                            const SizedBox(height: Tokens.e5),

                            // ── Acceso ─────────────────────────────
                            _Seccion(
                              antetitulo: 'Paso 3',
                              titulo: 'Datos de acceso',
                              hijos: [
                                CampoTexto(
                                  controlador: _controladorCorreo,
                                  etiqueta: 'Correo electrónico',
                                  pista: 'tucorreo@ejemplo.com',
                                  icono: Icons.alternate_email_rounded,
                                  teclado: TextInputType.emailAddress,
                                  validador: (v) => (v ?? '').contains('@')
                                      ? null
                                      : 'Ingresa un correo válido',
                                ),
                                CampoTexto(
                                  controlador: _controladorContrasena,
                                  etiqueta: 'Contraseña',
                                  pista: 'Mínimo 6 caracteres',
                                  icono: Icons.lock_outline_rounded,
                                  esClave: _ocultarContrasena,
                                  sufijo: IconButton(
                                    icon: Icon(
                                      _ocultarContrasena
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      size: 19,
                                    ),
                                    onPressed: () => setState(
                                      () => _ocultarContrasena =
                                          !_ocultarContrasena,
                                    ),
                                  ),
                                  validador: (v) => (v ?? '').length < 6
                                      ? 'Mínimo 6 caracteres'
                                      : null,
                                ),
                              ],
                            ),

                            const SizedBox(height: Tokens.e6),

                            const Aviso(
                              titulo: 'Tus datos están protegidos',
                              detalle:
                                  'Usamos tu cédula únicamente para verificar '
                                  'tu identidad al financiar pedidos.',
                              icono: Icons.verified_user_outlined,
                              color: Tokens.salviaProfundo,
                              fondo: Tokens.salviaSuave,
                            ),

                            const SizedBox(height: Tokens.e6),

                            BotonPrincipal(
                              texto: 'Crear mi cuenta',
                              icono: Icons.auto_awesome_rounded,
                              cargando: _cargando,
                              alPresionar: _registrar,
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

/// Agrupador visual de campos con antetítulo y título.
class _Seccion extends StatelessWidget {
  final String antetitulo;
  final String titulo;
  final List<Widget> hijos;

  const _Seccion({
    required this.antetitulo,
    required this.titulo,
    required this.hijos,
  });

  @override
  Widget build(BuildContext context) {
    return TarjetaSuave(
      padding: const EdgeInsets.all(Tokens.e5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EncabezadoSeccion(antetitulo: antetitulo, titulo: titulo),
          const SizedBox(height: Tokens.e5),
          for (int i = 0; i < hijos.length; i++) ...[
            if (i > 0) const SizedBox(height: Tokens.e5),
            hijos[i],
          ],
        ],
      ),
    );
  }
}

/// Avatar circular con borde punteado sutil para elegir el retrato.
class _SelectorRetrato extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback alTocar;

  const _SelectorRetrato({required this.bytes, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: alTocar,
      child: Container(
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Tokens.superficie,
          border: Border.all(color: Tokens.lineaFuerte, width: 1.5),
          boxShadow: Tokens.sombraSuave,
        ),
        padding: const EdgeInsets.all(5),
        child: ClipOval(
          child: bytes != null
              ? Image.memory(
                  bytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )
              : Container(
                  color: Tokens.rosaVelo,
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    size: 30,
                    color: Tokens.rosa,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Zona de captura de la cédula con estado vacío/lleno diferenciado.
class _CapturaCedula extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback alTocar;

  const _CapturaCedula({required this.bytes, required this.alTocar});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: Tokens.e2),
          child: Row(
            children: [
              Text(
                'Cédula (frontal)',
                style: tema.textTheme.labelMedium?.copyWith(
                  color: Tokens.tintaMedia,
                ),
              ),
              const Spacer(),
              if (bytes != null)
                const Pildora(
                  texto: 'Listo',
                  icono: Icons.check_rounded,
                  color: Tokens.exito,
                  compacta: true,
                ),
            ],
          ),
        ),
        GestureDetector(
          onTap: alTocar,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: bytes == null ? Tokens.superficieSuave : Colors.white,
              borderRadius: BorderRadius.circular(Tokens.radioSm),
              border: Border.all(
                color: bytes == null ? Tokens.lineaFuerte : Tokens.exito,
              ),
            ),
            child: bytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(Tokens.radioSm - 1),
                    child: Image.memory(
                      bytes!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.photo_camera_outlined,
                        size: 30,
                        color: Tokens.tintaSuave,
                      ),
                      const SizedBox(height: Tokens.e3),
                      Text(
                        'Toca para tomar la foto',
                        style: tema.textTheme.titleSmall?.copyWith(
                          color: Tokens.tintaMedia,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Asegúrate de que se lea con claridad',
                        style: tema.textTheme.bodySmall,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
