class Usuario {
  final String id;
  final String nome;
  final String email;
  final String telefone;
  final String tipoUsuario; // ADMIN ou COMUM

  const Usuario({
    required this.id,
    required this.nome,
    required this.email,
    required this.telefone,
    required this.tipoUsuario,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      telefone: json['telefone'],
      tipoUsuario: json['tipoUsuario'],
    );
  }
}