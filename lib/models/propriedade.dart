import 'atividade.dart';
import 'cidade.dart';
import 'ocorrencia.dart';
import 'usuario.dart';
import 'vulnerabilidade.dart';

class Propriedade {
  final String id;
  final String nome;
  final Cidade cidade;
  final String coordenadas;
  final String? proprietario;
  final String? telefoneProprietario;
  final Usuario usuario;
  final List<Atividade> atividades;
  final List<Vulnerabilidade> vulnerabilidades;
  final List<Ocorrencia> ocorrencias;

  const Propriedade({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.coordenadas,
    this.proprietario,
    this.telefoneProprietario,
    required this.usuario,
    required this.atividades,
    required this.vulnerabilidades,
    required this.ocorrencias,
  });

  factory Propriedade.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(dynamic) fromJson) {
      return (json[key] as List<dynamic>?)?.map(fromJson).toList() ?? [];
    }

    return Propriedade(
      id: json['id']?.toString() ?? '',
      nome: json['nome']?.toString() ?? 'Propriedade sem nome',
      coordenadas: json['coordenadas']?.toString() ?? '0.0,0.0',
      cidade: json['cidade'] != null
          ? Cidade.fromJson(json['cidade'])
          : const Cidade(id: '', nome: 'Inválida'),
      usuario: json['usuario'] != null
          ? Usuario.fromJson(json['usuario'])
          : const Usuario(id: '', nome: 'Inválido', email: '', telefone: '', tipoUsuario: 'COMUM'),
      proprietario: json['proprietario'] as String?,
      telefoneProprietario: json['telefoneProprietario'] as String?,
      atividades: parseList('atividades', (item) => Atividade.fromJson(item)),
      vulnerabilidades: parseList('vulnerabilidades', (item) => Vulnerabilidade.fromJson(item)),
      ocorrencias: parseList('ocorrencias', (item) => Ocorrencia.fromJson(item)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cidade': cidade.toJson(),
      'coordenadas': coordenadas,
      'proprietario': proprietario,
      'telefoneProprietario': telefoneProprietario,
      'usuario': usuario.toJson(),
      'atividades': atividades.map((item) => item.toJson()).toList(),
      'vulnerabilidades': vulnerabilidades.map((item) => item.toJson()).toList(),
      'ocorrencias': ocorrencias.map((item) => item.toJson()).toList(),
    };
  }
}