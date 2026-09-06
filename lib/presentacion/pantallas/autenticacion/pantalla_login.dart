import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../nucleo/tema/tokens_app.dart';
import '../../../repositorios/repositorio_autenticacion.dart';
import '../../widgets/componentes.dart';
import 'pantalla_registro_usuario.dart';

class PantallaLogin extends ConsumerStatefulWidget {
  const PantallaLogin({super.key});

  @override
  ConsumerState<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends ConsumerState<PantallaLogin> {
  final _formKey = GlobalKey<FormState>();
  final _controladorCorreo = TextEditingController();
  final _controladorContrasena = TextEditingController();
  bool _cargando = false;
  bool _ocultarContrasena = true;
  bool _recordarContrasena = false;

  @override
  void initState() {
    super.initState();
    _cargarCredenciales();
  }

  @override
  void dispose() {
    _controladorCorreo.dispose();
    _controladorContrasena.dispose();
    super.dispose();
  }

  Future<void> _cargarCredenciales() async {
    final prefs = await SharedPreferences.getInstance();
    final recordar = prefs.getBool('recordar_contrasena') ?? false;
    if (recordar && mounted) {
      setState(() {
        _recordarContrasena = true;
        _controladorCorreo.text = prefs.getString('correo') ?? '';
        _controladorContrasena.text = prefs.getString('contrasena') ?? '';
      });
    }
  }

  Future<void> _iniciarSesion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final repoAuth = ref.read(proveedorRepositorioAutenticacion);
      await repoAuth.iniciarSesion(
        _controladorCorreo.text.trim(),
        _controladorContrasena.text,
      );

      final prefs = await SharedPreferences.getInstance();
      if (_recordarContrasena) {
        await prefs.setBool('recordar_contrasena', true);
        await prefs.setString('correo', _controladorCorreo.text.trim());
        await prefs.setString('contrasena', _controladorContrasena.text);
      } else {
        await prefs.remove('recordar_contrasena');
        await prefs.remove('correo');
        await prefs.remove('contrasena');
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/inicial', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        Avisos.error(
          context,
          'No pudimos iniciar sesión. Revisa tus credenciales.',
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
                    const Antetitulo('Acceso de clientes'),
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
                    Tokens.e10,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: const SelloMarca(tamano: 66)
                                  .animate()
                                  .scale(
                                    duration: 600.ms,
                                    curve: Curves.easeOutBack,
                                    begin: const Offset(0.75, 0.75),
                                  ),
                            ),
                            const SizedBox(height: Tokens.e6),
                            Text(
                              'Bienvenido de vuelta',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.displaySmall,
                            ).animate().fadeIn(duration: 500.ms).slideY(
                              begin: 0.14,
                              curve: Curves.easeOutCubic,
                            ),
                            const SizedBox(height: Tokens.e3),
                            Text(
                              'Entra a tu cuenta para retomar tus pedidos y '
                              'tus cuotas del Club M&G.',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodyMedium,
                            ).animate().fadeIn(delay: 120.ms),

                            const SizedBox(height: Tokens.e8),

                            TarjetaSuave(
                              padding: const EdgeInsets.all(Tokens.e6),
                              sombra: Tokens.sombraMedia,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
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
                                  const SizedBox(height: Tokens.e5),
                                  CampoTexto(
                                    controlador: _controladorContrasena,
                                    etiqueta: 'Contraseña',
                                    pista: '••••••••',
                                    icono: Icons.lock_outline_rounded,
                                    esClave: _ocultarContrasena,
                                    alEnviar: (_) => _iniciarSesion(),
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
                                  const SizedBox(height: Tokens.e4),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: Checkbox(
                                          value: _recordarContrasena,
                                          onChanged: (val) => setState(
                                            () => _recordarContrasena =
                                                val ?? false,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: Tokens.e3),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _recordarContrasena =
                                                !_recordarContrasena,
                                          ),
                                          child: Text(
                                            'Recordarme en este dispositivo',
                                            style: tema.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: Tokens.tintaMedia,
                                                ),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => Avisos.mostrar(
                                          context,
                                          mensaje:
                                              'Escríbenos por el chat y te '
                                              'ayudamos a recuperarla.',
                                        ),
                                        child: const Text('¿La olvidaste?'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms, duration: 500.ms)
                                .slideY(begin: 0.1, curve: Curves.easeOutCubic),

                            const SizedBox(height: Tokens.e6),

                            BotonPrincipal(
                              texto: 'Entrar',
                              icono: Icons.arrow_forward_rounded,
                              cargando: _cargando,
                              alPresionar: _iniciarSesion,
                            ).animate().fadeIn(delay: 320.ms).slideY(
                              begin: 0.24,
                              curve: Curves.easeOutCubic,
                            ),

                            const SizedBox(height: Tokens.e6),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '¿Aún no tienes cuenta?',
                                  style: tema.textTheme.bodySmall,
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const PantallaRegistroUsuario(),
                                    ),
                                  ),
                                  child: const Text('Regístrate'),
                                ),
                              ],
                            ).animate().fadeIn(delay: 420.ms),
                          ],
                        ),
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
