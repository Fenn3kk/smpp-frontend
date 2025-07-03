import 'package:flutter/material.dart';
import '../models/propriedade.dart';
import '../services/propriedade_service.dart';

class PropriedadeProvider with ChangeNotifier {
  final PropriedadeService _service = PropriedadeService();

  List<Propriedade> _propriedades = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Propriedade> get propriedades => _propriedades;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Busca as propriedades da API e notifica os ouvintes sobre as mudanças de estado.
  Future<void> fetchPropriedades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _propriedades = await _service.buscarPropriedades();
      _propriedades.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deletePropriedade(String id) async {
    try {
      await _service.deletePropriedade(id);

      final index = _propriedades.indexWhere((p) => p.id == id);
      if (index != -1) {
        _propriedades.removeAt(index);
        notifyListeners();
      }
    } catch (e) {
      print('Erro ao deletar propriedade no provider: $e');
      throw e;
    }
  }
}
