import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class CadastroAdminPage extends StatefulWidget {
  const CadastroAdminPage({super.key});

  @override
  State<CadastroAdminPage> createState() => _CadastroAdminPageState();
}

class _CadastroAdminPageState extends State<CadastroAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _senhaVisivel = false;
  String? _erro;
  String _tipoSelecionado = 'COMUM';
  String? _jwt;
  String? _usuarioId;

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

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('jwt');
    _usuarioId = prefs.getString('usuarioId');


    final response = await http.post(
      Uri.parse('http://10.0.2.2:8080/usuarios'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_jwt',
      },
      body: jsonEncode({
        'nome': _nomeController.text.trim().toUpperCase(),
        'email': _emailController.text.trim(),
        'telefone': _telefoneController.text.trim(),
        'senha': _senhaController.text,
        'tipoUsuario': _tipoSelecionado,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário cadastrado com sucesso')),
      );
      Navigator.pop(context);
    } else {
      setState(() => _erro = 'Erro ao cadastrar: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Usuário'),
        backgroundColor: Colors.grey[800],),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_erro != null)
                Text(_erro!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                ),
                validator: (value) =>
                value!.isEmpty ? 'Informe o nome' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
                  if (value!.isEmpty || !emailRegex.hasMatch(value)) {
                    return 'E-mail inválido';
                  }
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
                      return _celularMask.formatEditUpdate(
                        oldValue,
                        TextEditingValue(
                          text: digits,
                          selection: TextSelection.collapsed(offset: selectionIndex),
                        ),
                      );
                    } else {
                      return _fixoMask.formatEditUpdate(
                        oldValue,
                        TextEditingValue(
                          text: digits,
                          selection: TextSelection.collapsed(offset: selectionIndex),
                        ),
                      );
                    }
                  }),
                ],
                decoration: const InputDecoration(labelText: 'Telefone'),
                validator: (value) {
                  final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                  return (digits.length < 10 || digits.length > 11)
                      ? 'Telefone inválido'
                      : null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _senhaController,
                obscureText: !_senhaVisivel,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  suffixIcon: IconButton(
                    icon: Icon(_senhaVisivel
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _senhaVisivel = !_senhaVisivel),
                  ),
                ),
                validator: (value) =>
                value!.length < 6 ? 'Mínimo de 6 caracteres' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipoSelecionado,
                items: const [
                  DropdownMenuItem(value: 'COMUM', child: Text('Comum')),
                  DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                ],
                onChanged: (value) => setState(() => _tipoSelecionado = value!),
                decoration: const InputDecoration(labelText: 'Tipo de usuário'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cadastrar,
                icon: const Icon(Icons.check),
                label: const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
