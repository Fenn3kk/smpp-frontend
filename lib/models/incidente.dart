class Incidente {
  final String id;
  final String nome;

  const Incidente({
    required this.id,
    required this.nome,
  });

  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Incidente desconhecido',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
    };
  }
}
