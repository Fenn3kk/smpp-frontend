import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/incidente.dart';
import '../models/tipo_ocorrencia.dart';
import '../models/ocorrencia.dart';

class OcorrenciaService {

  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
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
      throw Exception('Falha ao carregar tipos de ocorrência: ${response.statusCode}');
    }
  }

  Future<List<Incidente>> buscarIncidentes() async {
    final url = Uri.parse('${AppConfig.baseUrl}/incidentes');
    final headers = await _getAuthHeaders();
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Incidente.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar incidentes: ${response.statusCode}');
    }
  }

  Future<void> salvarComFotos({
    required Map<String, dynamic> ocorrenciaDto,
    required List<XFile> fotos,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/ocorrencias');
    final request = http.MultipartRequest('POST', url);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromString(
        'ocorrenciaDto',
        jsonEncode(ocorrenciaDto),
        contentType: MediaType('application', 'json'),
      ),
    );

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

    if (response.statusCode != 201) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Falha ao salvar ocorrência: ${response.statusCode} - $responseBody');
    }
  }

  Future<void> updateOcorrencia({
    required String ocorrenciaId,
    required Map<String, dynamic> updateDto,
    required List<XFile> novasFotos,
  }) async {
    final url = Uri.parse('${AppConfig.baseUrl}/ocorrencias/$ocorrenciaId');
    final request = http.MultipartRequest('PUT', url);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt') ?? '';
    request.headers['Authorization'] = 'Bearer $token';

    request.files.add(
      http.MultipartFile.fromString(
        'ocorrenciaUpdateDto',
        jsonEncode(updateDto),
        contentType: MediaType('application', 'json'),
      ),
    );

    for (var foto in novasFotos) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'novasFotos',
          foto.path,
          filename: foto.name,
        ),
      );
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Falha ao atualizar ocorrência: ${response.statusCode} - $responseBody');
    }
  }

  Future<void> deleteFoto(String fotoId) async {
    final url = Uri.parse('${AppConfig.baseUrl}/fotos/$fotoId');
    final headers = await _getAuthHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 204) {
      throw Exception('Falha ao excluir a foto: ${response.statusCode}');
    }
  }

  Future<void> deleteOcorrencia(String id) async {
    final url = Uri.parse('${AppConfig.baseUrl}/ocorrencias/$id');
    final headers = await _getAuthHeaders();

    final response = await http.delete(url, headers: headers);

    if (response.statusCode != 204) {
      throw Exception('Falha ao excluir a ocorrência: ${response.statusCode}');
    }
  }
}

