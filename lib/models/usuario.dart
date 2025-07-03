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

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Usuário desconhecido',
      email: json['email']?.toString() ?? '',
      telefone: json['telefone']?.toString() ?? '',
      tipoUsuario: json['tipoUsuario']?.toString() ?? 'COMUM',
    );
  }

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
