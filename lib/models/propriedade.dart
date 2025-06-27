import 'atividade.dart';
import 'cidade.dart';
import 'ocorrencia.dart';
import 'usuario.dart';
import 'vulnerabilidade.dart';

class Propriedade {
  final String id;
  final String nome;
  final Cidade cidade; // Objeto aninhado
  final String coordenadas;
  final String proprietario;
  final String telefoneProprietario;
  final Usuario usuario; // Objeto aninhado
  final List<Atividade> atividades; // Lista de objetos aninhados
  final List<Vulnerabilidade> vulnerabilidades; // Lista de objetos aninhados
  final List<Ocorrencia> ocorrencias; // Lista de objetos aninhados

  const Propriedade({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.coordenadas,
    required this.proprietario,
    required this.telefoneProprietario,
    required this.usuario,
    required this.atividades,
    required this.vulnerabilidades,
    required this.ocorrencias,
  });

  factory Propriedade.fromJson(Map<String, dynamic> json) {
    return Propriedade(
      id: json['id'],
      nome: json['nome'],
      // Chama o construtor .fromJson() do modelo aninhado
      cidade: Cidade.fromJson(json['cidade']),
      coordenadas: json['coordenadas'],
      proprietario: json['proprietario'],
      telefoneProprietario: json['telefoneProprietario'],
      // Chama o construtor .fromJson() do modelo aninhado
      usuario: Usuario.fromJson(json['usuario']),

      // Mapeia a lista de JSONs para uma lista de objetos Atividade
      atividades: (json['atividades'] as List)
          .map((item) => Atividade.fromJson(item))
          .toList(),

      // O mesmo para as outras listas
      vulnerabilidades: (json['vulnerabilidades'] as List)
          .map((item) => Vulnerabilidade.fromJson(item))
          .toList(),

      ocorrencias: (json['ocorrencias'] as List)
          .map((item) => Ocorrencia.fromJson(item))
          .toList(),
    );
  }
}