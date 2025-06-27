import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/models/usuario.dart';
import 'package:smpp_flutter/providers/usuario_provider.dart';
import 'package:smpp_flutter/rotas/app_rotas.dart';
import 'package:smpp_flutter/widgets/app_formatters.dart';

class EditarUsuarioPage extends StatefulWidget {
  const EditarUsuarioPage({super.key});

  @override
  State<EditarUsuarioPage> createState() => _EditarUsuarioPageState();
}

class _EditarUsuarioPageState extends State<EditarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefoneController;
  final _senhaController = TextEditingController();
  final _senhaAtualController = TextEditingController();

  bool _senhaVisivel = false;
  bool _isSaving = false;
  String? _tipoUsuarioSelecionado;

  @override
  void initState() {
    super.initState();
    // Popula o formulário com os dados do provider.
    final usuario = Provider.of<UsuarioProvider>(context, listen: false).currentUser;
    _nomeController = TextEditingController(text: usuario?.nome ?? '');
    _emailController = TextEditingController(text: usuario?.email ?? '');
    _telefoneController = TextEditingController(text: usuario?.telefone ?? '');
    _tipoUsuarioSelecionado = usuario?.tipoUsuario ?? 'COMUM';
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    // Se a senha foi alterada, pede a senha atual para confirmação.
    if (_senhaController.text.isNotEmpty) {
      final senhaAtual = await _pedirSenhaAtual();
      if (senhaAtual == null || senhaAtual.isEmpty) return; // Usuário cancelou
      _senhaAtualController.text = senhaAtual;
    }

    setState(() => _isSaving = true);

    final dto = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text,
      'tipoUsuario': _tipoUsuarioSelecionado,
      // Envia a nova senha e a senha atual (se aplicável)
      'senha': _senhaController.text,
      'senhaAtual': _senhaAtualController.text,
    };

    try {
      await Provider.of<UsuarioProvider>(context, listen: false).updateUser(dto);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados com sucesso!'), backgroundColor: Colors.green));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _excluir() async {
    final senhaAtual = await _pedirSenhaAtual(title: 'Excluir Conta', content: 'Para sua segurança, digite sua senha atual para confirmar a exclusão da conta.');
    if (senhaAtual == null || senhaAtual.isEmpty) return;

    try {
      await Provider.of<UsuarioProvider>(context, listen: false).deleteUser(senhaAtual);
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  Future<String?> _pedirSenhaAtual({String? title, String? content}) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(title ?? 'Confirme sua Identidade'),
          content: Text(content ?? 'Digite sua senha atual para continuar.'),
          actions: [
            TextField(controller: controller, obscureText: true, autofocus: true),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                TextButton(onPressed: () => Navigator.of(ctx).pop(controller.text), child: const Text('Confirmar')),
              ],
            )
          ],
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
    _senhaAtualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuta o provider para saber se o usuário é admin.
    final bool souAdmin = Provider.of<UsuarioProvider>(context).isAdmin;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar Perfil'), backgroundColor: Colors.teal),
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
              TextFormField(controller: _senhaController, decoration: InputDecoration(labelText: 'Nova senha (deixe vazio para não alterar)', border: OutlineInputBorder(), suffixIcon: IconButton(icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel))), obscureText: !_senhaVisivel),
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
                  Expanded(child: ElevatedButton.icon(onPressed: _isSaving ? null : _salvar, icon: const Icon(Icons.save), label: const Text('Salvar'))),
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
