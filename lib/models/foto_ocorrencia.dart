class FotoOcorrencia {
  final String id;
  final String? nome; // Nome original do arquivo, pode ser nulo
  final String url;  // O campo agora se chama 'url' para bater com a API.

  const FotoOcorrencia({
    required this.id,
    this.nome,
    required this.url,
  });

  factory FotoOcorrencia.fromJson(Map<String, dynamic> json) {
    return FotoOcorrencia(

      id: json.containsKey('id') && json['id'] != null ? json['id'].toString() : '',
      nome: json['nome'] as String?,
      url: json.containsKey('url') && json['url'] != null ? json['url'].toString() : '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'url': url,
    };
  }
}