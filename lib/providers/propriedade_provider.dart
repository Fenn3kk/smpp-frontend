import 'package:flutter/material.dart';
import '../models/propriedade.dart';
import '../services/propriedade_service.dart';

class PropriedadeProvider with ChangeNotifier {
  final PropriedadeService _service = PropriedadeService();

  List<Propriedade> _propriedades = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters para a UI acessar os dados de forma segura e reativa.
  List<Propriedade> get propriedades => _propriedades;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Busca as propriedades da API e notifica os ouvintes sobre as mudanças de estado.
  Future<void> fetchPropriedades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Anuncia: "Estou começando a carregar!"

    try {
      _propriedades = await _service.buscarPropriedades();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners(); // Anuncia: "Terminei de carregar!" (com sucesso ou com erro)
  }

  /// Exclui uma propriedade e atualiza o estado local para refletir a mudança instantaneamente.
  Future<void> deletePropriedade(String id) async {
    try {
      await _service.deletePropriedade(id);

      // Remove da lista local para atualização imediata da UI
      final index = _propriedades.indexWhere((p) => p.id == id);
      if (index != -1) {
        _propriedades.removeAt(index);
        notifyListeners(); // Anuncia a remoção
      }
    } catch (e) {
      // Em um app real, você poderia guardar esse erro para exibir na UI
      print('Erro ao deletar propriedade no provider: $e');
      // Re-lança o erro para que a UI possa mostrar um SnackBar, por exemplo.
      throw e;
    }
  }
}
