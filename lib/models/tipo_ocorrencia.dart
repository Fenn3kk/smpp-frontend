class TipoOcorrencia {
  final String id;
  final String nome;

  const TipoOcorrencia({
    required this.id,
    required this.nome,
  });

  factory TipoOcorrencia.fromJson(Map<String, dynamic> json) {
    return TipoOcorrencia(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Tipo de ocorrência desconhecido',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}
