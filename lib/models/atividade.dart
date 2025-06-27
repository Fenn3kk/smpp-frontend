class Atividade {
  final String id;
  final String nome;

  const Atividade({
    required this.id,
    required this.nome,
  });

  factory Atividade.fromJson(Map<String, dynamic> json) {
    return Atividade(
      id: json['id'],
      nome: json['nome'],
    );
  }
}