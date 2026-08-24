import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'nucleo/constantes/entorno.dart';
import 'nucleo/tema/tema_app.dart';
import 'presentacion/pantallas/bienvenida/pantalla_bienvenida.dart';
import 'presentacion/pantallas/pantalla_inicial.dart';
import 'presentacion/pantallas/autenticacion/pantalla_registro_usuario.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  // Inicializar Supabase usando las variables de entorno
  await Supabase.initialize(
    url: Entorno.supabaseUrl,
    publishableKey: Entorno.supabaseAnonKey,
  );

  // Iniciar la app envuelta en ProviderScope para Riverpod
  runApp(const ProviderScope(child: AplicacionSweetBites()));
}

class AplicacionSweetBites extends StatelessWidget {
  const AplicacionSweetBites({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pasteleria M&G',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.temaClaro,
      darkTheme: TemaApp.temaOscuro,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const PantallaBienvenida(),
        '/inicial': (context) => const PantallaInicial(),
        '/registro_usuario': (context) => const PantallaRegistroUsuario(),
      },
    );
  }
}
