import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../autenticacion/pantalla_login.dart';
import '../autenticacion/pantalla_registro_usuario.dart';
import '../pantalla_inicial.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: tema.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Fondo pastel suave decorativo
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tema.colorScheme.primaryContainer.withAlpha(150),
              ),
            ),
          ).animate().fadeIn(duration: 1.seconds).scale(duration: 1.seconds),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tema.colorScheme.secondaryContainer.withAlpha(150),
              ),
            ),
          ).animate().fadeIn(duration: 1.seconds, delay: 300.ms).scale(),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  // Logo animado
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: tema.colorScheme.primary.withAlpha(30),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cake_rounded,
                        size: 80,
                        color: tema.colorScheme.primary,
                      ),
                    ).animate()
                      .scale(duration: 800.ms, curve: Curves.elasticOut)
                      .shimmer(delay: 1.seconds, duration: 1.seconds, color: tema.colorScheme.primaryContainer),
                  ),
                  const SizedBox(height: 32),
                  
                  // Texto principal
                  Hero(
                    tag: 'logo_titulo',
                    child: Text(
                      'Pasteleria M&G',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: tema.colorScheme.primary,
                        letterSpacing: -1,
                      ),
                    ),
                  ).animate().slideY(begin: 0.3, duration: 600.ms).fadeIn(),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    'Los postres más deliciosos, \ndirecto a tu puerta.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: tema.textTheme.bodyMedium?.color,
                      height: 1.4,
                    ),
                  ).animate().slideY(begin: 0.3, delay: 200.ms, duration: 600.ms).fadeIn(),
                  
                  const Spacer(flex: 2),

                  // Botones CTA
                  _BotonPrimario(
                    texto: 'Crear cuenta',
                    icono: Icons.person_add_rounded,
                    alPresionar: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaRegistroUsuario()),
                      );
                    },
                  ).animate().slideY(begin: 0.5, delay: 400.ms, duration: 500.ms).fadeIn(),
                  
                  const SizedBox(height: 16),
                  
                  _BotonSecundario(
                    texto: 'Iniciar sesión',
                    icono: Icons.login_rounded,
                    alPresionar: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaLogin()),
                      );
                    },
                  ).animate().slideY(begin: 0.5, delay: 500.ms, duration: 500.ms).fadeIn(),
                  
                  const SizedBox(height: 24),
                  
                  // Acceso rápido
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaInicial()),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: tema.textTheme.bodyMedium?.color,
                    ),
                    child: Text(
                      'Explorar el menú primero',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ).animate().fadeIn(delay: 800.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotonPrimario extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback alPresionar;

  const _BotonPrimario({
    required this.texto,
    required this.icono,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: alPresionar,
        style: ElevatedButton.styleFrom(
          backgroundColor: tema.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: tema.colorScheme.primary.withAlpha(100),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 24),
            const SizedBox(width: 12),
            Text(
              texto,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BotonSecundario extends StatelessWidget {
  final String texto;
  final IconData icono;
  final VoidCallback alPresionar;

  const _BotonSecundario({
    required this.texto,
    required this.icono,
    required this.alPresionar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return SizedBox(
      height: 60,
      child: OutlinedButton(
        onPressed: alPresionar,
        style: OutlinedButton.styleFrom(
          foregroundColor: tema.colorScheme.primary,
          side: BorderSide(color: tema.colorScheme.primary.withAlpha(100), width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 24),
            const SizedBox(width: 12),
            Text(
              texto,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
