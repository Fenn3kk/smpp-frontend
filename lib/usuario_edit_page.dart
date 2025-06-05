import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:smpp_flutter/login_page.dart';

class EditarUsuarioPage extends StatefulWidget {
  const EditarUsuarioPage({super.key});

  @override
  State<EditarUsuarioPage> createState() => _EditarUsuarioPageState();
}

class _EditarUsuarioPageState extends State<EditarUsuarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _senhaController = TextEditingController();
  bool _mostrarSenha = false;

  String? _usuarioId;
  String? _jwt;
  bool _carregando = true;
  bool _autenticado = false;
  String? _senhaAtual;
  String? _tipoUsuario;
  String? _tipoUsuarioSelecionado;
  bool _souAdmin = false;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarUsuario();
    });
  }

  Future<void> _pedirSenhaAtual() async {
    final senha = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final controller = TextEditingController();
        bool mostrarSenha = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Confirme sua senha'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Senha atual',
                  suffixIcon: IconButton(
                    icon: Icon(
                      mostrarSenha ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        mostrarSenha = !mostrarSenha;
                      });
                    },
                  ),
                ),
                obscureText: !mostrarSenha,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(null),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );

    if (senha == null || senha.isEmpty) {
      Navigator.pop(context); // sai da página se cancelar ou vazio
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    _usuarioId = prefs.getString('usuarioId');
    _jwt = prefs.getString('jwt');

    if (_usuarioId == null) {
      _mostrarErro('Usuário não encontrado.');
      return;
    }

    // Buscar o email da API
    final usuarioResponse = await http.get(
      Uri.parse('http://10.0.2.2:8080/usuarios/$_usuarioId'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json'},
    );

    if (usuarioResponse.statusCode != 200) {
      _mostrarErro('Erro ao buscar email do usuário.');
      return;
    }

    final usuarioData = json.decode(usuarioResponse.body);
    final email = usuarioData['email'];
    print(email);

    final loginResponse = await http.post(
      Uri.parse('http://10.0.2.2:8080/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'senha': senha}),
    );

    if (loginResponse.statusCode == 200) {
      final data = json.decode(loginResponse.body);
      await prefs.setString('jwt', data['token']);
      print('Token salvo após login da senha: ${data['token']}');
      setState(() {
        _jwt = data['token']; // <-- IMPORTANTE!
        _senhaAtual = senha;
        _autenticado = true;
      });
      await _carregarUsuario();
    } else {
      _mostrarErro('Senha incorreta. Tente novamente.');
      await _pedirSenhaAtual();
    }
  }

  Future<void> _carregarUsuario() async {
    if (!_autenticado) {
      await _pedirSenhaAtual();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _usuarioId = prefs.getString('usuarioId');
    _jwt = prefs.getString('jwt');

    if (_usuarioId == null || _jwt == null) {
      _mostrarErro('Usuário não autenticado.');
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/usuarios/$_usuarioId'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _nomeController.text = data['nome'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telefoneController.text = data['telefone'] ?? '';
        _tipoUsuario = data['tipoUsuario'];
        _tipoUsuarioSelecionado = data['tipoUsuario'] ?? 'COMUM';
        _souAdmin = data['tipoUsuario'] == 'ADMIN';
        _carregando = false;
      });
    } else {
      _mostrarErro('Erro ao carregar dados do usuário.');
    }
  }

  String? validarEmail(String? email) {
    if (email == null || email.isEmpty) return 'Informe o email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email.trim())) return 'Email inválido';
    return null;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();

    final Map<String, dynamic> usuario = {
      'nome': _nomeController.text.trim(),
      'email': _emailController.text.trim(),
      'telefone': _telefoneController.text.trim(),
      'tipoUsuario': _tipoUsuarioSelecionado ?? 'COMUM',
    };

    if (_senhaController.text.isNotEmpty) {
      usuario['senha'] = _senhaController.text;
    }

    final response = await http.put(
      Uri.parse('http://10.0.2.2:8080/usuarios/$_usuarioId'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json',
      },
      body: json.encode(usuario),
    );

    if (response.statusCode == 200) {
      // Reautentica com email e senha atual
      final loginResponse = await http.post(
        Uri.parse('http://10.0.2.2:8080/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': _emailController.text.trim(),
          'senha': _senhaController.text.isNotEmpty ? _senhaController.text : _senhaAtual,
        }),
      );

      if (loginResponse.statusCode == 200) {
        final loginData = json.decode(loginResponse.body);
        await prefs.setString('jwt', loginData['token']);
        print('Token salvo após login alteração: ${loginData['token']}');
        _jwt = loginData['token'];

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuário atualizado com sucesso')),
        );
        Navigator.pop(context);
      }
      else {
        _mostrarErro('Atualizou, mas falhou ao reautenticar. Faça login novamente.');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      _mostrarErro('Erro ao atualizar usuário.');
    }
  }

  Future<void> _excluir() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir seu usuário?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir')),
        ],
      ),
    );

    if (confirmar != true) return;

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8080/usuarios/$_usuarioId'),
      headers: {
        'Authorization': 'Bearer $_jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt');
      await prefs.remove('usuarioId');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      _mostrarErro('Erro ao excluir usuário.');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Usuário'),
        backgroundColor: Colors.grey[800],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(labelText: 'Nome'),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Informe o nome' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: validarEmail,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
                      if (digits.length > 11) digits = digits.substring(0, 11);
                      final mask = digits.length > 10 ? _celularMask : _fixoMask;
                      return TextEditingValue(
                        text: mask.maskText(digits),
                        selection: TextSelection.collapsed(offset: mask.getUnmaskedText().length),
                      );
                    }),
                  ],
                  decoration: const InputDecoration(labelText: 'Telefone'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _senhaController,
                  decoration: InputDecoration(
                    labelText: 'Nova senha (deixe vazio para não alterar)',
                    suffixIcon: IconButton(
                      icon: Icon(_mostrarSenha ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _mostrarSenha = !_mostrarSenha;
                        });
                      },
                    ),
                  ),
                  obscureText: !_mostrarSenha,
                ),
                if (_souAdmin)
                  DropdownButtonFormField<String>(
                    value: _tipoUsuarioSelecionado,
                    items: const [
                      DropdownMenuItem(value: 'COMUM', child: Text('Comum')),
                      DropdownMenuItem(value: 'ADMIN', child: Text('Administrador')),
                    ],
                    onChanged: (valor) {
                      setState(() {
                        _tipoUsuarioSelecionado = valor;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Tipo de Usuário'),
                  ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: _salvar,
                      child: const Text('Salvar'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _excluir,
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
