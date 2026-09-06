import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../nucleo/tema/tokens_app.dart';
import '../../widgets/componentes.dart';
import '../autenticacion/pantalla_login.dart';
import '../autenticacion/pantalla_registro_usuario.dart';
import '../pantalla_inicial.dart';

class PantallaBienvenida extends StatelessWidget {
  const PantallaBienvenida({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      body: FondoAtelier(
        intenso: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, restricciones) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: restricciones.maxHeight,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          Tokens.e6,
                          Tokens.e8,
                          Tokens.e6,
                          Tokens.e6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // ── Marca ──────────────────────────────
                            Center(
                              child: const SelloMarca(tamano: 88).animate().scale(
                                duration: 700.ms,
                                curve: Curves.easeOutBack,
                                begin: const Offset(0.7, 0.7),
                              ),
                            ),
                            const SizedBox(height: Tokens.e6),

                            Hero(
                              tag: 'logo_titulo',
                              child: Material(
                                color: Colors.transparent,
                                child: Text(
                                  'Pastelería\nM&G',
                                  textAlign: TextAlign.center,
                                  style: tema.textTheme.displayLarge?.copyWith(
                                    height: 1.02,
                                    fontSize: 52,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(duration: 600.ms).slideY(
                              begin: 0.16,
                              duration: 600.ms,
                              curve: Curves.easeOutCubic,
                            ),

                            const SizedBox(height: Tokens.e5),
                            Center(child: const Filete()).animate().fadeIn(
                              delay: 250.ms,
                            ),
                            const SizedBox(height: Tokens.e5),

                            Text(
                              'Repostería artesanal horneada cada mañana '
                              'y llevada hasta tu puerta.',
                              textAlign: TextAlign.center,
                              style: tema.textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                            ).animate().fadeIn(delay: 300.ms).slideY(
                              begin: 0.14,
                              duration: 600.ms,
                            ),

                            const SizedBox(height: Tokens.e8),

                            // ── Argumentos de valor ────────────────
                            const _PanelValores()
                                .animate()
                                .fadeIn(delay: 420.ms, duration: 600.ms)
                                .slideY(begin: 0.12, curve: Curves.easeOutCubic),

                            const SizedBox(height: Tokens.e8),

                            // ── Acciones ───────────────────────────
                            BotonPrincipal(
                              texto: 'Crear mi cuenta',
                              icono: Icons.auto_awesome_rounded,
                              alPresionar: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantallaRegistroUsuario(),
                                ),
                              ),
                            ).animate().fadeIn(delay: 560.ms).slideY(
                              begin: 0.3,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),

                            const SizedBox(height: Tokens.e3),

                            BotonContorno(
                              texto: 'Ya tengo cuenta',
                              icono: Icons.lock_open_rounded,
                              alPresionar: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PantallaLogin(),
                                ),
                              ),
                            ).animate().fadeIn(delay: 640.ms).slideY(
                              begin: 0.3,
                              duration: 500.ms,
                              curve: Curves.easeOutCubic,
                            ),

                            const SizedBox(height: Tokens.e5),

                            Center(
                              child: TextButton.icon(
                                onPressed: () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PantallaInicial(),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.restaurant_menu_rounded,
                                  size: 17,
                                ),
                                label: const Text('Ver la carta primero'),
                                style: TextButton.styleFrom(
                                  foregroundColor: Tokens.tintaMedia,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Tokens.e4,
                                    vertical: Tokens.e3,
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 760.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tres promesas de marca presentadas como una tarjeta editorial.
class _PanelValores extends StatelessWidget {
  const _PanelValores();

  @override
  Widget build(BuildContext context) {
    return TarjetaSuave(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.e5,
        vertical: Tokens.e2,
      ),
      sombra: Tokens.sombraMedia,
      child: Column(
        children: const [
          _FilaValor(
            icono: Icons.local_fire_department_rounded,
            color: Tokens.rosa,
            titulo: 'Horneado del día',
            detalle: 'Todo se prepara la misma mañana en que lo recibes.',
          ),
          Divider(height: 1, indent: 52),
          _FilaValor(
            icono: Icons.credit_card_rounded,
            color: Tokens.arenaProfundo,
            titulo: 'Club M&G',
            detalle: 'Llévalo hoy y págalo en tres cuotas sin intereses.',
          ),
          Divider(height: 1, indent: 52),
          _FilaValor(
            icono: Icons.support_agent_rounded,
            color: Tokens.salviaProfundo,
            titulo: 'Asesoría inmediata',
            detalle: 'Un asistente te acompaña de principio a fin.',
          ),
        ],
      ),
    );
  }
}

class _FilaValor extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String detalle;

  const _FilaValor({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tokens.e4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(Tokens.radioXs),
            ),
            child: Icon(icono, size: 18, color: color),
          ),
          const SizedBox(width: Tokens.e3 + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tema.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  detalle,
                  style: tema.textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
