import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/providers/usuario_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';
import 'package:smpp_flutter/services/auth_service.dart';
import 'package:smpp_flutter/widgets/app_formatters.dart';

class EditarUsuarioPage extends StatefulWidget {
  const EditarUsuarioPage({super.key});

  @override
  State<EditarUsuarioPage> createState() => _EditarUsuarioPageState();
}

class _EditarUsuarioPageState extends State<EditarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _isAuthenticated = false;
  bool _isSaving = false;
  String? _tipoUsuarioSelecionado;
  String _senhaAtualConfirmada = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autenticarParaEditar();
    });
  }

  Future<void> _autenticarParaEditar() async {
    final navigator = Navigator.of(context);

    final senhaConfirmada = await _pedirSenhaAtualComValidacao();

    if (senhaConfirmada != null) {
      final usuario = Provider.of<UsuarioProvider>(context, listen: false).currentUser;
      _nomeController.text = usuario?.nome ?? '';
      _emailController.text = usuario?.email ?? '';
      _telefoneController.text = usuario?.telefone ?? '';
      _tipoUsuarioSelecionado = usuario?.tipoUsuario ?? 'COMUM';
      _senhaAtualConfirmada = senhaConfirmada;
      setState(() => _isAuthenticated = true);
    } else {
      navigator.pop();
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = Provider.of<UsuarioProvider>(context, listen: false);

    setState(() => _isSaving = true);

    final dto = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text,
      'tipoUsuario': _tipoUsuarioSelecionado,
      'senha': _senhaController.text,
      'senhaAtual': _senhaAtualConfirmada,
    };

    try {
      await provider.updateUser(dto);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green));
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _excluir() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = Provider.of<UsuarioProvider>(context, listen: false);

    try {
      await provider.deleteUser(_senhaAtualConfirmada);
      if (!mounted) return;
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<String?> _pedirSenhaAtualComValidacao() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        String? dialogError;
        bool isChecking = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirmar Identidade'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Para editar seu perfil, por favor, digite sua senha atual.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    obscureText: true,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Senha Atual',
                      errorText: dialogError,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: isChecking ? null : () async {
                    setDialogState(() {
                      isChecking = true;
                      dialogError = null;
                    });
                    try {
                      await _authService.reauthenticate(controller.text);
                      if (!mounted) return;
                      Navigator.of(ctx).pop(controller.text);
                    } catch (e) {
                      setDialogState(() {
                        dialogError = 'Senha incorreta. Tente novamente.';
                        isChecking = false;
                      });
                    }
                  },
                  child: isChecking ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _telefoneController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Editar Perfil'), backgroundColor: Colors.teal),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final bool souAdmin = Provider.of<UsuarioProvider>(context).isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil'), backgroundColor: Colors.teal, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(controller: _nomeController, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Informe o nome' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress, validator: (v) => v!.isEmpty || !v.contains('@') ? 'Email inválido' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _telefoneController, decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder()), keyboardType: TextInputType.phone, inputFormatters: [AppFormatters.dynamicPhoneMask]),
              const SizedBox(height: 16),
              TextFormField(controller: _senhaController, decoration: const InputDecoration(labelText: 'Nova senha (deixe vazio para não alterar)', border: OutlineInputBorder()), obscureText: true),
              if (souAdmin) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _tipoUsuarioSelecionado,
                  items: const [
                    DropdownMenuItem(value: 'COMUM', child: Text('Comum')),
                    DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                  ],
                  onChanged: (valor) => setState(() => _tipoUsuarioSelecionado = valor),
                  decoration: const InputDecoration(labelText: 'Tipo de Usuário', border: OutlineInputBorder()),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(child: ElevatedButton.icon(onPressed: _isSaving ? null : _salvar, icon: const Icon(Icons.save), label: const Text('Salvar Alterações'))),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: _isSaving ? null : _excluir, icon: const Icon(Icons.delete_forever), label: const Text('Excluir Conta')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
