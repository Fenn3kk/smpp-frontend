import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../configs/app_config.dart';
import '../models/usuario.dart';

class UsuarioService {
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    };
  }

  /// Busca um usuário pelo seu ID.
  Future<Usuario> buscarUsuarioById(String id) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/usuarios/$id');
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Falha ao carregar dados do usuário: ${response.statusCode}');
  }

  /// Atualiza os dados de um usuário.
  Future<Usuario> updateUsuario(String id, Map<String, dynamic> dto) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/usuarios/$id');

    final response = await http.put(url, headers: headers, body: jsonEncode(dto));

    if (response.statusCode == 200) {
      return Usuario.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
    }
    throw Exception('Falha ao atualizar usuário: ${response.statusCode}');
  }

  Future<void> createUserByAdmin(Map<String, dynamic> userDto) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/usuarios');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(userDto),
    );

    if (response.statusCode != 201) { // 201 Created
      try {
        final errorBody = jsonDecode(response.body);
        final message = errorBody['message'] ?? 'E-mail indisponível ou dados inválidos.';
        throw Exception(message);
      } catch (_) {
        throw Exception('Erro ao cadastrar usuário: ${response.statusCode}');
      }
    }
  }

  /// Exclui o usuário.
  Future<void> deleteUsuario(String id) async {
    final headers = await _getAuthHeaders();
    final url = Uri.parse('${AppConfig.baseUrl}/usuarios/$id');

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Falha ao excluir usuário: ${response.statusCode}');
    }
  }
}
