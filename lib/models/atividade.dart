class Atividade {
  final String id;
  final String nome;

  const Atividade({
    required this.id,
    required this.nome,
  });

  /// Construtor de fábrica para criar uma instância a partir de um JSON.
  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Atividade desconhecida',
    );
  }

  /// Converte a instância do objeto Dart para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}