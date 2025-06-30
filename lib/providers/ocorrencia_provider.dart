import 'package:flutter/material.dart';
import '../models/ocorrencia.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaProvider with ChangeNotifier {
  final OcorrenciaService _service = OcorrenciaService();

  // O estado que este provider gerencia
  List<Ocorrencia> _ocorrencias = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para a UI acessar os dados de forma segura
  List<Ocorrencia> get ocorrencias => _ocorrencias;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Busca as ocorrências de uma propriedade específica e notifica os ouvintes.
  Future<void> fetchOcorrenciasPorPropriedade(String propriedadeId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Anuncia o início do carregamento

    try {
      _ocorrencias = await _service.buscarOcorrenciasPorPropriedade(propriedadeId);
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners(); // Anuncia o fim do carregamento (com sucesso ou erro)
  }
}
