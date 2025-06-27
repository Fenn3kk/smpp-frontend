import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/providers/propriedade_provider.dart';
import 'package:smpp_flutter/providers/usuario_provider.dart';
import 'app_widget.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Registra os providers que estarão disponíveis para todo o app.
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),
        ChangeNotifierProvider(create: (_) => PropriedadeProvider()),
        // Adicione outros providers aqui conforme a necessidade.
      ],
      child: const AppWidget(),
    ),
  );
}