// lib/services/ocorrencia_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../configs/app_config.dart';
import '../models/incidente.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/ocorrencia.dart';

class OcorrenciaService {

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<List<Ocorrencia>> buscarOcorrenciasPorPropriedade(String propriedadeId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/ocorrencias/propriedade/$propriedadeId');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Ocorrencia.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar as ocorrências: ${response.statusCode}');
    }
  }

  Future<List<TipoOcorrencia>> buscarTiposOcorrencia() async {
    final url = Uri.parse('${AppConfig.baseUrl}/tipo-ocorrencia');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));

      return jsonList.map((json) => TipoOcorrencia.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar os tipos de ocorrência: ${response.statusCode}');
    }
  }

  Future<List<Incidente>> buscarIncidentes() async {
    final url = Uri.parse('${AppConfig.baseUrl}/incidentes');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      // Usa o construtor fromJson para converter cada item da lista
      return jsonList.map((json) => Incidente.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar os incidentes: ${response.statusCode}');
    }
  }

  Future<void> salvarOcorrencia({
    required Map<String, dynamic> ocorrenciaDto,
    required List<XFile> fotos,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/ocorrencias');
    final request = http.MultipartRequest('POST', url);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    request.headers['Authorization'] = 'Bearer $token';

    // Adiciona a parte JSON (DTO)
    request.fields['ocorrenciaDto'] = jsonEncode(ocorrenciaDto);

    // Adiciona os arquivos de foto
    for (var foto in fotos) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'fotos',
          foto.path,
          filename: foto.name,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 200 && response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Falha ao salvar ocorrência: ${response.statusCode} - $responseBody');
    }
  }
}