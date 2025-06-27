class FotoOcorrencia {
  final String id;
  final String? nome; // Nome original do arquivo, pode ser nulo
  final String caminho; // Caminho/URL para acessar a imagem

  const FotoOcorrencia({
    required this.id,
    this.nome,
    required this.caminho,
  });

  factory FotoOcorrencia.fromJson(Map<String, dynamic> json) {
    // É uma boa prática construir a URL completa aqui se o backend só retornar o nome do arquivo
    // Ex: final String urlCompleta = 'http://seu-servidor.com/uploads/${json['caminho']}';
    return FotoOcorrencia(
      id: json['id'],
      nome: json['nome'],
      caminho: json['caminho'], // ou urlCompleta
    );
  }
}