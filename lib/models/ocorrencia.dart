import 'foto_ocorrencia.dart';
import 'incidente.dart';
import 'propriedade.dart';
import 'tipo_ocorrencia.dart';

class Ocorrencia {
  final String id;
  final TipoOcorrencia tipoOcorrencia;
  final DateTime data;
  final String? descricao;
  final List<FotoOcorrencia> fotos;
  final Propriedade? propriedade;
  final List<Incidente> incidentes;

  const Ocorrencia({
    required this.id,
    required this.tipoOcorrencia,
    required this.data,
    this.descricao,
    required this.fotos,
    this.propriedade,
    required this.incidentes,
  });

  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    List<T> parseList<T>(String key, T Function(dynamic) fromJson) {
      return (json[key] as List<dynamic>?)?.map(fromJson).toList() ?? [];
    }

    return Ocorrencia(
      id: json['id']?.toString() ?? '',

      tipoOcorrencia: json['tipoOcorrencia'] != null
          ? TipoOcorrencia.fromJson(json['tipoOcorrencia'])
          : const TipoOcorrencia(id: '', nome: 'Desconhecido'),

      data: json['data'] != null
          ? DateTime.tryParse(json['data'].toString()) ?? DateTime.now()
          : DateTime.now(),

      descricao: json['descricao'] as String?,

      propriedade: json['propriedade'] != null
          ? Propriedade.fromJson(json['propriedade'])
          : null,

      fotos: parseList('fotos', (item) => FotoOcorrencia.fromJson(item)),
      incidentes: parseList('incidentes', (item) => Incidente.fromJson(item)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipoOcorrencia': tipoOcorrencia.toJson(),
      'data': data.toIso8601String().split('T')[0],
      'descricao': descricao,
      'fotos': fotos.map((foto) => foto.toJson()).toList(),
      'propriedade': propriedade?.toJson(),
      'incidentes': incidentes.map((incidente) => incidente.toJson()).toList(),
    };
  }
}
