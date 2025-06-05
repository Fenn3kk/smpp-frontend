import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'login_page.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _senhaVisivel = false;
  String? _erro;

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse('http://10.0.2.2:8080/auth/cadastro');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nome': _nomeController.text.trim().toUpperCase(),
        'email': _emailController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'senha': _senhaController.text,
      }),
    );

    if (response.statusCode == 201) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      setState(() => _erro = 'E-mail indisponível ou dados inválidos.');
    }
  }

  final _fixoMask = MaskTextInputFormatter(
    mask: '(##) ####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Icon(Icons.person_add, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('Criar nova conta',
                    style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                if (_erro != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(_erro!, style: const TextStyle(color: Colors.red)),
                  ),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome completo',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Informe seu nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'E-mail',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value!.isEmpty) return 'Informe seu e-mail';
                    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                    if (!emailRegex.hasMatch(value)) return 'E-mail inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

                      if (digits.length > 11) digits = digits.substring(0, 11);

                      final selectionIndex = digits.length;

                      if (digits.length > 10) {
                        final formatted = _celularMask.formatEditUpdate(
                          oldValue,
                          TextEditingValue(
                            text: digits,
                            selection: TextSelection.collapsed(offset: selectionIndex),
                          ),
                        );
                        return formatted;
                      } else {
                        final formatted = _fixoMask.formatEditUpdate(
                          oldValue,
                          TextEditingValue(
                            text: digits,
                            selection: TextSelection.collapsed(offset: selectionIndex),
                          ),
                        );
                        return formatted;
                      }
                    }),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'N.º de telefone',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 10 || digits.length > 11) {
                      return 'Telefone inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  obscureText: !_senhaVisivel,
                  decoration: InputDecoration(
                    labelText: 'Senha',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _senhaVisivel ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() => _senhaVisivel = !_senhaVisivel);
                      },
                    ),
                  ),
                  validator: (value) =>
                  value!.length < 6 ? 'Mínimo de 6 caracteres' : null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _cadastrar,
                    icon: const Icon(Icons.check),
                    label: const Text('Cadastrar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
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