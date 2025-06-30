class Cidade {
  final String id;
  final String nome;

  const Cidade({
    required this.id,
    required this.nome,
  });

  /// Cria uma instância de Cidade a partir de um mapa JSON.
  factory Cidade.fromJson(Map<String, dynamic> json) {
    return Cidade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Cidade desconhecida',
    );
  }

  /// Converte a instância de Cidade para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}
