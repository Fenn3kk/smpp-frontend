class FotoOcorrencia {
  final String id;
  final String? nome; // Nome original do arquivo, pode ser nulo
  final String caminho; // Caminho/nome do arquivo no servidor

  const FotoOcorrencia({
    required this.id,
    this.nome,
    required this.caminho,
  });

  /// Cria uma instância a partir de um JSON de forma segura.
  factory FotoOcorrencia.fromJson(Map<String, dynamic> json) {
    return FotoOcorrencia(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] as String?, // O nome pode ser nulo
      caminho: json['caminho']?.toString() ?? '',
    );
  }

  /// Converte a instância para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'caminho': caminho,
    };
  }
}
