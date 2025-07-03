class Atividade {
  final String id;
  final String nome;

  const Atividade({
    required this.id,
    required this.nome,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Atividade desconhecida',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}