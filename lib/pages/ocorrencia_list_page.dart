import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/config/app_config.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/providers/ocorrencia_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';
import 'package:smpp_flutter/widgets/user_drawer.dart';

class OcorrenciasPage extends StatefulWidget {
  final Propriedade propriedade;

  const OcorrenciasPage({super.key, required this.propriedade});

  @override
  State<OcorrenciasPage> createState() => _OcorrenciasPageState();
}

class _OcorrenciasPageState extends State<OcorrenciasPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<OcorrenciaProvider>(context, listen: false)
            .fetchOcorrenciasPorPropriedade(widget.propriedade.id)
    );
  }

  void _navegarParaCriarOcorrencia() async {
    final foiCriado = await Navigator.pushNamed(
      context,
      AppRoutes.ocorrenciaCreate,
      arguments: widget.propriedade.id,
    );

    // Se uma nova ocorrência foi criada, pede ao provider para recarregar.
    if (foiCriado == true && mounted) {
      Provider.of<OcorrenciaProvider>(context, listen: false)
          .fetchOcorrenciasPorPropriedade(widget.propriedade.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserDrawerWidget(),
      appBar: AppBar(
        title: Text('Ocorrências - ${widget.propriedade.nome}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      // O Consumer reconstrói a UI automaticamente quando o provider notifica mudanças.
      body: Consumer<OcorrenciaProvider>(
        builder: (context, provider, child) {
          Widget body;

          if (provider.isLoading) {
            body = const Center(child: CircularProgressIndicator());
          } else if (provider.errorMessage != null) {
            body = Center(child: Text('Erro: ${provider.errorMessage}'));
          } else if (provider.ocorrencias.isEmpty) {
            body = const Center(child: Text('Nenhuma ocorrência encontrada.'));
          } else {
            body = ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: provider.ocorrencias.length,
              itemBuilder: (context, index) {
                final ocorrencia = provider.ocorrencias[index];
                final data = ocorrencia.data;
                final dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ocorrencia.tipoOcorrencia.nome, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
                        const SizedBox(height: 12),
                        Text('Data: $dataFormatada'),
                        const SizedBox(height: 8),
                        Text('Descrição: ${ocorrencia.descricao ?? "N/A"}'),
                        const SizedBox(height: 8),
                        Text('Incidentes: ${ocorrencia.incidentes.isEmpty ? "Nenhum" : ocorrencia.incidentes.map((i) => i.nome).join(', ')}'),
                        if (ocorrencia.fotos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ocorrencia.fotos.length,
                              itemBuilder: (ctx, i) {
                                final foto = ocorrencia.fotos[i];
                                final imageUrl = '${AppConfig.baseUrl}/uploads/${foto.caminho}';
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(imageUrl, width: 100, height: 100, fit: BoxFit.cover),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchOcorrenciasPorPropriedade(widget.propriedade.id),
            child: body,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navegarParaCriarOcorrencia,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
    );
  }
}
