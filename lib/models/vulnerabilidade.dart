class Vulnerabilidade {
  final String id;
  final String nome;

  const Vulnerabilidade({
    required this.id,
    required this.nome,
  });

  /// Cria uma instância a partir de um JSON.
  factory Vulnerabilidade.fromJson(Map<String, dynamic> json) {
    return Vulnerabilidade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Vulnerabilidade desconhecida',
    );
  }

  /// Converte a instância para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}