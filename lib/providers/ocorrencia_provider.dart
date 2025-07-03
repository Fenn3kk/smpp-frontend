import 'package:flutter/material.dart';
import '../models/ocorrencia.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaProvider with ChangeNotifier {
  final OcorrenciaService _service = OcorrenciaService();

  List<Ocorrencia> _ocorrencias = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Ocorrencia> get ocorrencias => _ocorrencias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOcorrenciasPorPropriedade(String propriedadeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ocorrencias = await _service.buscarOcorrenciasPorPropriedade(propriedadeId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteFoto(String ocorrenciaId, String fotoId) async {
    await _service.deleteFoto(fotoId);

    final ocorrenciaIndex = _ocorrencias.indexWhere((o) => o.id == ocorrenciaId);
    if (ocorrenciaIndex != -1) {
      _ocorrencias[ocorrenciaIndex].fotos.removeWhere((f) => f.id == fotoId);
      notifyListeners();
    }
  }

  Future<void> excluirOcorrencia(String ocorrenciaId) async {
    try {
      await _service.deleteOcorrencia(ocorrenciaId);

      _ocorrencias.removeWhere((o) => o.id == ocorrenciaId);

      notifyListeners();

    } catch (e) {
      throw Exception('Erro ao excluir ocorrência: ${e.toString()}');
    }
  }
}
