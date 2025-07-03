import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/providers/usuario_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';

class UserDrawerWidget extends StatelessWidget {
  const UserDrawerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UsuarioProvider>(
      builder: (context, userProvider, child) {
        final usuario = userProvider.currentUser;

        return Drawer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: Colors.grey[800],
                padding: const EdgeInsets.fromLTRB(16, 50, 16, 24),
                child: userProvider.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.account_circle, color: Colors.white, size: 52),
                    const SizedBox(height: 16),
                    Text(
                      usuario?.nome ?? 'Usuário',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      usuario?.email ?? 'Não autenticado',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tipo: ${usuario?.tipoUsuario ?? 'N/A'}',
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.black87),
                title: const Text('Editar Perfil'),
                onTap: () {
                  if (usuario != null) {
                    Navigator.pushNamed(context, AppRoutes.usuarioEdit, arguments: usuario.id);
                  }
                },
              ),
              if (usuario?.tipoUsuario == 'ADMIN')
                ListTile(
                  leading: const Icon(Icons.person_add, color: Colors.black87),
                  title: const Text('Cadastrar Usuários'),
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.adminCadastro);
                  },
                ),
              const Spacer(),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sair'),
                onTap: () async {
                  await userProvider.logout();
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}