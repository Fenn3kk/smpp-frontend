import 'package:flutter/material.dart';
import 'package:smpp_flutter/services/usuario_service.dart';
import 'package:smpp_flutter/widgets/app_formatters.dart';

class CadastroAdminPage extends StatefulWidget {
  const CadastroAdminPage({super.key});

  @override
  State<CadastroAdminPage> createState() => _CadastroAdminPageState();
}

class _CadastroAdminPageState extends State<CadastroAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioService = UsuarioService();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _isLoading = false;
  String? _erro;
  String _tipoUsuarioSelecionado = 'COMUM';

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    final userDto = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text,
      'senha': _senhaController.text,
      'tipoUsuario': _tipoUsuarioSelecionado,
    };

    try {
      await _usuarioService.createUserByAdmin(userDto);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso!'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();

    } catch (e) {
      setState(() {
        _erro = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Novo Usuário'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(_erro!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome completo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email_outlined)),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty || !v.contains('@') ? 'Informe um e-mail válido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefoneController,
                decoration: const InputDecoration(labelText: 'Telefone', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone_outlined)),
                keyboardType: TextInputType.phone,
                inputFormatters: [AppFormatters.dynamicPhoneMask],
                validator: (v) {
                  final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                  if (digits.length < 10) return 'Telefone inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                ),
                validator: (v) => v == null || v.length < 6 ? 'Mínimo de 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoUsuarioSelecionado,
                items: const [
                  DropdownMenuItem(value: 'COMUM', child: Text('Comum')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                ],
                onChanged: (value) => setState(() => _tipoUsuarioSelecionado = value!),
                decoration: const InputDecoration(labelText: 'Tipo de usuário', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _cadastrar,
                icon: _isLoading
                    ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Icon(Icons.person_add),
                label: Text(_isLoading ? 'Cadastrando...' : 'Cadastrar Usuário'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
