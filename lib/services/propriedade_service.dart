import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smpp_flutter/models/atividade.dart';
import 'package:smpp_flutter/models/cidade.dart';
import 'package:smpp_flutter/models/vulnerabilidade.dart';
import '../configs/app_config.dart';
import '../models/propriedade.dart';

class PropriedadeService {

  Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt') ?? '';
  }

  Future<List<Propriedade>> buscarPropriedades() async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/propriedades');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      // Usa o modelo Propriedade para converter o JSON em uma lista de objetos
      return jsonList.map((json) => Propriedade.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar as propriedades: ${response.statusCode}');
    }
  }

  Future<void> deletePropriedade(String id) async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/propriedades/$id');

    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception('Falha ao excluir a propriedade: ${response.statusCode}');
    }
  }

  Future<List<Cidade>> fetchCidades() async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/cidades');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Cidade.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar cidades');
  }

  /// Busca a lista de todas as Atividades.
  Future<List<Atividade>> fetchAtividades() async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/atividades');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Atividade.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar atividades');
  }

  /// Busca a lista de todas as Vulnerabilidades.
  Future<List<Vulnerabilidade>> fetchVulnerabilidades() async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/vulnerabilidades');
    final response = await http.get(url, headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Vulnerabilidade.fromJson(json)).toList();
    }
    throw Exception('Falha ao carregar vulnerabilidades');
  }

  /// Cria uma nova propriedade enviando o DTO.
  Future<void> createPropriedade(Map<String, dynamic> propriedadeDto) async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/propriedades');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(propriedadeDto),
    );

    if (response.statusCode != 201) { // 201 Created é o esperado
      throw Exception('Falha ao criar propriedade: ${response.statusCode}');
    }
  }

  Future<void> updatePropriedade(String id, Map<String, dynamic> propriedadeDto) async {
    final token = await _getToken();
    final url = Uri.parse('${AppConfig.baseUrl}/propriedades/$id');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(propriedadeDto),
    );

    if (response.statusCode != 200) { // 200 OK é o esperado
      throw Exception('Falha ao atualizar propriedade: ${response.statusCode}');
    }
  }
}