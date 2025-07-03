import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smpp_flutter/models/ocorrencia.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/pages/ocorrencia_edit_page.dart';
import 'package:smpp_flutter/pages/relatorio_propriedade_list_page.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';
import 'package:smpp_flutter/pages/login_page.dart';
import 'package:smpp_flutter/pages/home_page.dart';
import 'package:smpp_flutter/pages/cadastro_page.dart';
import 'package:smpp_flutter/pages/admin_usuario_create_page.dart';
import 'package:smpp_flutter/pages/full_map_page.dart';
import 'package:smpp_flutter/pages/ocorrencia_create_page.dart';
import 'package:smpp_flutter/pages/ocorrencia_list_page.dart';
import 'package:smpp_flutter/pages/propriedade_create_page.dart';
import 'package:smpp_flutter/pages/propriedade_edit_page.dart';
import 'package:smpp_flutter/pages/propriedade_list_page.dart';
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
      debugShowCheckedModeBanner: false,
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
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final coordenada = args['coordenada'] as LatLng;
              final isReadOnly = args['isReadOnly'] as bool? ?? false;
              return MaterialPageRoute(
                builder: (_) => FullMapPage(
                  coordenadaInicial: coordenada,
                  isReadOnly: isReadOnly,
                ),
              );
            }
            break;

          case AppRoutes.ocorrencia:
            if (settings.arguments is Propriedade) {
              final args = settings.arguments as Propriedade;
              return MaterialPageRoute(builder: (_) => OcorrenciasPage(propriedade: args));
            }
            break;

          case AppRoutes.ocorrenciaCreate:
            if (settings.arguments is String) {
              final args = settings.arguments as String;
              return MaterialPageRoute(builder: (_) => OcorrenciaFormPage(propriedadeId: args));
            }
            break;

          case AppRoutes.ocorrenciaEdit:
            if (settings.arguments is Map<String, dynamic>) {
              final args = settings.arguments as Map<String, dynamic>;
              final ocorrencia = args['ocorrencia'] as Ocorrencia;
              final propriedadeId = args['propriedadeId'] as String;
              return MaterialPageRoute(
                builder: (_) => OcorrenciaEditPage(
                  ocorrencia: ocorrencia,
                  propriedadeId: propriedadeId,
                ),
              );
            }
            break;

          case AppRoutes.propriedadeEdit:
            if (settings.arguments is Propriedade) {
              final args = settings.arguments as Propriedade;
              return MaterialPageRoute(builder: (_) => EditarPropriedadePage(propriedade: args));
            }
            break;

          case AppRoutes.relatorioPropriedadeList:
            return MaterialPageRoute(builder: (_) => const RelatorioPropriedadeListPage());
        }

        // Rota de fallback para páginas não encontradas ou com argumentos errados
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Erro de Navegação')),
            body: Center(
              child: Text('Rota não encontrada ou argumentos inválidos para: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
