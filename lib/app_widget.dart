import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/rotas/app_rotas.dart';

// Importe todas as suas páginas
import 'package:smpp_flutter/pages/login_page.dart';
import 'package:smpp_flutter/pages/home_page.dart';
import 'package:smpp_flutter/pages/cadastro_page.dart';
import 'package:smpp_flutter/pages/admin_cadastro_page.dart';
import 'package:smpp_flutter/pages/full_map_page.dart';
import 'package:smpp_flutter/pages/ocorrencia_create_page.dart';
import 'package:smpp_flutter/pages/ocorrencia_page.dart';
import 'package:smpp_flutter/pages/propriedade_create_page.dart';
import 'package:smpp_flutter/pages/propriedade_edit_page.dart';
import 'package:smpp_flutter/pages/propriedade_page.dart';
import 'package:smpp_flutter/pages/usuario_edit_page.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMPP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.login,
      onGenerateRoute: (settings) {
        switch (settings.name) {

        // --- Rotas Simples (sem argumentos) ---
          case AppRoutes.login:
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case AppRoutes.home:
            return MaterialPageRoute(builder: (_) => const HomePage());
          case AppRoutes.cadastro:
            return MaterialPageRoute(builder: (_) => const CadastroPage());
          case AppRoutes.adminCadastro:
            return MaterialPageRoute(builder: (_) => const CadastroAdminPage());
          case AppRoutes.propriedade:
            return MaterialPageRoute(builder: (_) => const PropriedadesPage());
          case AppRoutes.propriedadeCreate:
            return MaterialPageRoute(builder: (_) => const PropriedadeFormPage());
          case AppRoutes.usuarioEdit:
            return MaterialPageRoute(builder: (_) => const EditarUsuarioPage());

        // --- Rotas com Argumentos ---
          case AppRoutes.fullMap:
            final args = settings.arguments as LatLng;
            return MaterialPageRoute(builder: (_) => FullMapPage(coordenadaInicial: args));

          case AppRoutes.ocorrencia:
            final args = settings.arguments as Propriedade;
            return MaterialPageRoute(builder: (_) => OcorrenciasPage(propriedade: args));

          case AppRoutes.ocorrenciaCreate:
            final args = settings.arguments as String;
            return MaterialPageRoute(builder: (_) => OcorrenciaFormPage(propriedadeId: args));

          case AppRoutes.propriedadeEdit:
            final args = settings.arguments as Propriedade;
            return MaterialPageRoute(builder: (_) => EditarPropriedadePage(propriedade: args));

        // Rota de fallback para páginas não encontradas
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('Rota não encontrada: ${settings.name}'),
                ),
              ),
            );
        }
      },
    );
  }
}

