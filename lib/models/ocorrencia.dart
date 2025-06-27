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
  final Propriedade propriedade;
  final List<Incidente> incidentes;

  const Ocorrencia({
    required this.id,
    required this.tipoOcorrencia,
    required this.data,
    this.descricao,
    required this.fotos,
    required this.propriedade,
    required this.incidentes,
  });

  factory Ocorrencia.fromJson(Map<String, dynamic> json) {
    return Ocorrencia(
      id: json['id'],
      // Chama os construtores .fromJson() dos modelos aninhados
      tipoOcorrencia: TipoOcorrencia.fromJson(json['tipoOcorrencia']),
      // Converte a string de data (ex: "2025-06-27") para um objeto DateTime
      data: DateTime.parse(json['data']),
      descricao: json['descricao'],
      propriedade: Propriedade.fromJson(json['propriedade']),

      // Mapeia as listas de JSON para listas de objetos
      fotos: (json['fotos'] as List)
          .map((item) => FotoOcorrencia.fromJson(item))
          .toList(),

      incidentes: (json['incidentes'] as List)
          .map((item) => Incidente.fromJson(item))
          .toList(),
    );
  }
}