class TipoOcorrencia {
  final String id;
  final String nome;

  const TipoOcorrencia({
    required this.id,
    required this.nome,
  });

  /// Cria uma instância de TipoOcorrencia a partir de um mapa JSON.
  factory TipoOcorrencia.fromJson(Map<String, dynamic> json) {
    return TipoOcorrencia(
      id: json['id'],
      nome: json['nome'],
    );
  }

  /// Converte a instância de TipoOcorrencia para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}