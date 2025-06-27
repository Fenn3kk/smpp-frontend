import 'package:flutter/material.dart';
import 'package:smpp_flutter/rotas/app_rotas.dart';
import 'package:smpp_flutter/services/auth_service.dart';
import 'package:smpp_flutter/widgets/app_formatters.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  bool _isLoading = false;
  String? _erro;

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _erro = null;
    });

    try {
      // A UI agora apenas chama o método de registro do serviço.
      await _authService.register(
        nome: _nomeController.text.trim(),
        email: _emailController.text.trim(),
        telefone: _telefoneController.text,
        senha: _senhaController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso! Faça o login.'), backgroundColor: Colors.green),
      );
      // Leva o usuário para o login, limpando a pilha de navegação.
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);

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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add_alt_1_outlined, size: 64, color: Colors.teal),
                const SizedBox(height: 16),
                const Text('Crie sua nova conta', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),

                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_erro!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),

                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline), border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined), border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty || !v.contains('@')) return 'Informe um e-mail válido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined), border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  // USA A MÁSCARA REUTILIZÁVEL
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
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_senhaVisivel ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 6 ? 'A senha deve ter no mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cadastrar,
                    icon: _isLoading ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.check_circle_outline),
                    label: Text(_isLoading ? 'Cadastrando...' : 'Cadastrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                  child: const Text('Já tem uma conta? Entrar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
