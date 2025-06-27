import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smpp_flutter/configs/app_config.dart';
import 'package:smpp_flutter/models/usuario.dart';
import 'package:smpp_flutter/services/auth_service.dart';
import 'package:smpp_flutter/services/usuario_service.dart';

class UsuarioProvider with ChangeNotifier {
  final UsuarioService _userService = UsuarioService();
  final AuthService _authService = AuthService();

  Usuario? _currentUser;
  bool _isLoading = true;

  Usuario? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.tipoUsuario == 'ADMIN';

  UsuarioProvider() { _tryAutoLogin(); }

  Future<void> _tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('usuarioId')) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final usuarioId = prefs.getString('usuarioId')!;
    try {
      _currentUser = await _userService.buscarUsuarioById(usuarioId);
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Orquestra o processo de login.
  Future<void> login(String email, String senha) async {
    try {
      // 1. Chama o AuthService para autenticar e salvar o token.
      final authData = await _authService.login(email, senha);

      // 2. Se autenticado, busca os dados completos do usuário.
      final usuarioId = authData['usuarioId'];
      _currentUser = await _userService.buscarUsuarioById(usuarioId);

      notifyListeners(); // Notifica a UI que o usuário mudou.
    } catch (e) {
      _currentUser = null;
      notifyListeners();
      // Re-lança a exceção para que a UI possa pegá-la e mostrar o erro.
      throw e;
    }
  }

  /// Atualiza os dados do usuário e, se bem-sucedido, busca os dados atualizados.
  Future<void> updateUser(Map<String, dynamic> dto) async {
    if (_currentUser == null) throw Exception("Usuário não autenticado.");

    // Se uma nova senha foi fornecida, reautentica primeiro para confirmar a identidade.
    if (dto['senhaAtual'] != null && dto['senhaAtual'].isNotEmpty) {
      await _authService.reauthenticate(dto['senhaAtual']);
    }

    final updatedUser = await _userService.updateUsuario(_currentUser!.id, dto);
    _currentUser = updatedUser;

    // Se a senha foi alterada, força um novo login para obter um novo token.
    if (dto['senha'] != null && dto['senha'].isNotEmpty) {
      await login(_currentUser!.email, dto['senha']);
    }

    notifyListeners();
  }

  Future<void> reauthenticate(String senha) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail'); // Precisamos salvar o email no login

    if (email == null) {
      throw Exception('Sessão inválida. Por favor, faça login novamente.');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    // Se o login não for bem-sucedido, a senha está incorreta.
    if (response.statusCode != 200) {
      throw Exception('Senha atual incorreta.');
    }
    // Se deu 200, não precisamos fazer nada, apenas deixar a execução continuar.
  }

  /// Exclui o usuário atual após confirmar a senha.
  Future<void> deleteUser(String senhaAtual) async {
    if (_currentUser == null) throw Exception("Usuário não autenticado.");

    await _authService.reauthenticate(senhaAtual);
    await _userService.deleteUsuario(_currentUser!.id);
    await logout(); // O logout já limpa os dados e notifica
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
