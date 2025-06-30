class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String tipoUsuario;

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.tipoUsuario,
  });

  /// Construtor de fábrica para criar uma instância de Usuário a partir de um mapa JSON.
  /// Lida com possíveis valores nulos da API de forma segura.
  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Usuário desconhecido',
      email: json['email']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      tipoUsuario: json['tipoUsuario']?.toString() ?? 'COMUM',
    );
  }

  /// Converte a instância do objeto Dart para um mapa JSON.
  /// Útil se você precisar enviar este objeto de volta para a API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'tipoUsuario': tipoUsuario,
    };
  }
}
