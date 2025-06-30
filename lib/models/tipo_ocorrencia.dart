class TipoOcorrencia {
  final String id;
  final String nome;

  const TipoOcorrencia({
    required this.id,
    required this.nome,
  });

  /// Construtor de fábrica para criar uma instância a partir de um JSON.
  factory TipoOcorrencia.fromJson(Map<String, dynamic> json) {
    return TipoOcorrencia(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Tipo de ocorrência desconhecido',
    );
  }

  /// Converte a instância do objeto Dart para um mapa JSON.
  /// Útil se você precisar enviar este objeto de volta para a API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}
