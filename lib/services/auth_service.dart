import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String email, String senha) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt', body['token']);
      await prefs.setString('usuarioId', body['usuarioId'].toString());
      await prefs.setString('userEmail', email);
      return body;
    } else {
      throw Exception('Credenciais inválidas.');
    }
  }

  Future<void> reauthenticate(String senha) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('userEmail');

    if (email == null) {
      throw Exception('Sessão inválida. Por favor, faça login novamente.');
    }

    final url = Uri.parse('${AppConfig.baseUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'senha': senha}),
    );

    if (response.statusCode != 200) {
      throw Exception('Senha atual incorreta.');
    }
  }

  Future<void> register({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/cadastro');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'senha': senha,
      }),
    );

    if (response.statusCode != 201) {
      try {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'E-mail indisponível ou dados inválidos.';
        throw Exception(message);
      } catch (_) {
        throw Exception('Erro ao registrar: ${response.statusCode}');
      }
    }
  }
}
