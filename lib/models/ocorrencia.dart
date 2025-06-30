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
  final Propriedade? propriedade; // Pode ser nulo dependendo do contexto da API
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

  /// Cria uma instância de Ocorrencia a partir de um JSON de forma segura.
  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    // Função auxiliar para processar listas de forma segura
    List<T> parseList<T>(String key, T Function(dynamic) fromJson) {
      return (json[key] as List<dynamic>?)?.map(fromJson).toList() ?? [];
    }

    return Ocorrencia(
      id: json['id']?.toString() ?? '',

      tipoOcorrencia: json['tipoOcorrencia'] != null
          ? TipoOcorrencia.fromJson(json['tipoOcorrencia'])
          : const TipoOcorrencia(id: '', nome: 'Desconhecido'), // Valor padrão

      data: json['data'] != null
          ? DateTime.tryParse(json['data'].toString()) ?? DateTime.now()
          : DateTime.now(), // Valor padrão

      descricao: json['descricao'] as String?,

      // A propriedade pode não vir em todas as respostas da API, então tratamos o nulo.
      propriedade: json['propriedade'] != null
          ? Propriedade.fromJson(json['propriedade'])
          : null,

      fotos: parseList('fotos', (item) => FotoOcorrencia.fromJson(item)),
      incidentes: parseList('incidentes', (item) => Incidente.fromJson(item)),
    );
  }

  /// Converte a instância do objeto Dart para um mapa JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipoOcorrencia': tipoOcorrencia.toJson(),
      'data': data.toIso8601String().split('T')[0], // Envia apenas a data
      'descricao': descricao,
      'fotos': fotos.map((foto) => foto.toJson()).toList(),
      'propriedade': propriedade?.toJson(), // Usa o operador '?' para segurança
      'incidentes': incidentes.map((incidente) => incidente.toJson()).toList(),
    };
  }
}
