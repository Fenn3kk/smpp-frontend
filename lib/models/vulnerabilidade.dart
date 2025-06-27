class Vulnerabilidade {
  final String id;
  final String nome;

  const Vulnerabilidade({
    required this.id,
    required this.nome,
  });

  factory Vulnerabilidade.fromJson(Map<String, dynamic> json) {
    return Vulnerabilidade(
      id: json['id'],
      nome: json['nome'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}