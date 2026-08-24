import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../repositorios/repositorio_autenticacion.dart';

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

  Future<void> _cargarCredenciales() async {
    final prefs = await SharedPreferences.getInstance();
    final recordar = prefs.getBool('recordar_contrasena') ?? false;
    if (recordar) {
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
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/inicial',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión. Verifica tus credenciales.'),
            backgroundColor: Colors.redAccent,
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Icono animado
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: tema.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cake_rounded,
                      size: 60,
                      color: tema.colorScheme.primary,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                ),
                const SizedBox(height: 32),
                
                Text(
                  '¡Hola de nuevo!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: tema.textTheme.displayLarge?.color,
                  ),
                ).animate().slideY(begin: 0.3, duration: 500.ms).fadeIn(),
                
                const SizedBox(height: 8),
                Text(
                  'Ingresa a tu cuenta para pedir tus postres favoritos',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: tema.textTheme.bodyMedium?.color,
                  ),
                ).animate().slideY(begin: 0.3, delay: 100.ms, duration: 500.ms).fadeIn(),
                
                const SizedBox(height: 48),

                // Correo
                TextFormField(
                  controller: _controladorCorreo,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email_outlined),
                    filled: true,
                  ),
                  validator: (v) => v!.contains('@') ? null : 'Correo inválido',
                ).animate().slideX(begin: -0.2, delay: 200.ms, duration: 500.ms).fadeIn(),
                
                const SizedBox(height: 20),

                // Contraseña
                TextFormField(
                  controller: _controladorContrasena,
                  obscureText: _ocultarContrasena,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _ocultarContrasena 
                            ? Icons.visibility_outlined 
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _ocultarContrasena = !_ocultarContrasena;
                        });
                      },
                    ),
                    filled: true,
                  ),
                  validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                ).animate().slideX(begin: 0.2, delay: 300.ms, duration: 500.ms).fadeIn(),
                
                const SizedBox(height: 8),

                CheckboxListTile(
                  title: Text(
                    'Recordar contraseña',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: tema.textTheme.bodyMedium?.color,
                    ),
                  ),
                  value: _recordarContrasena,
                  onChanged: (val) {
                    setState(() {
                      _recordarContrasena = val ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: tema.colorScheme.primary,
                ).animate().fadeIn(delay: 400.ms),
                
                const SizedBox(height: 4),
                
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      '¿Olvidaste tu contraseña?',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: tema.colorScheme.primary,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 32),

                // Botón Ingresar
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _iniciarSesion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tema.colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: tema.colorScheme.primary.withAlpha(100),
                    ),
                    child: _cargando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Ingresar',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                ).animate().slideY(begin: 0.5, delay: 400.ms, duration: 500.ms).fadeIn(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
