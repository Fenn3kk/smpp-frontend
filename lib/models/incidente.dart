class Incidente {
  final String id;
  final String nome;

  const Incidente({
    required this.id,
    required this.nome,
  });

  /// Cria uma instância a partir de um JSON.
  factory Incidente.fromJson(Map<String, dynamic> json) {
    return Incidente(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Incidente desconhecido',
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
