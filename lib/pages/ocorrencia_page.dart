import 'package:flutter/material.dart';
import 'package:smpp_flutter/configs/app_config.dart'; // Necessário para a URL da imagem
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/rotas/app_rotas.dart';
import 'package:smpp_flutter/services/ocorrencia_service.dart';
import '../models/ocorrencia.dart';
import '../widgets/user_drawer.dart';

class OcorrenciasPage extends StatefulWidget {
  // 1. RECEBENDO O MODELO, não um Map
  final Propriedade propriedade;

  const OcorrenciasPage({super.key, required this.propriedade});

  @override
  State<OcorrenciasPage> createState() => _OcorrenciasPageState();
}

class _OcorrenciasPageState extends State<OcorrenciasPage> {
  // 2. USANDO O MODELO no estado
  List<Ocorrencia> _ocorrencias = [];
  bool _carregando = true;
  final OcorrenciaService _service = OcorrenciaService();

  @override
  void initState() {
    super.initState();
    _carregarOcorrencias();
  }

  Future<void> _carregarOcorrencias() async {
    setState(() => _carregando = true);

    try {
      final data = await _service.buscarOcorrenciasPorPropriedade(widget.propriedade.id);
      if (!mounted) return;

      setState(() {
        _ocorrencias = data as List<Ocorrencia>;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar ocorrências: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _carregando = false);
      }
    }
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black, fontSize: 16),
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: value ?? ''),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const UserDrawerWidget(),
      appBar: AppBar(
        // 4. ACESSANDO DADOS de forma segura
        title: Text('Ocorrências - ${widget.propriedade.nome}'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          _carregando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
            onRefresh: _carregarOcorrencias,
            child: _ocorrencias.isEmpty
                ? const Center(child: Text('Nenhuma ocorrência encontrada.'))
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Espaço para o FAB
              itemCount: _ocorrencias.length,
              itemBuilder: (context, index) {
                // 5. USANDO O OBJETO OCORRENCIA fortemente tipado
                final ocorrencia = _ocorrencias[index];

                // Acessando os dados de forma segura e com autocompletar
                final tipoNome = ocorrencia.tipoOcorrencia.nome;
                final data = ocorrencia.data;
                final dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
                final descricao = ocorrencia.descricao ?? 'Sem descrição';
                final tiposIncidentes = ocorrencia.incidentes.isEmpty
                    ? 'Nenhum'
                    : ocorrencia.incidentes.map((i) => i.nome).join(', ');
                final fotos = ocorrencia.fotos;

                return Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tipoNome,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                        const SizedBox(height: 8),
                        _infoRow('Data', dataFormatada),
                        _infoRow('Descrição', descricao),
                        _infoRow('Incidentes', tiposIncidentes),
                        if (fotos.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text('Fotos:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: fotos.length,
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final foto = fotos[i];
                                // 6. CONSTRUINDO A URL da imagem de forma segura
                                final imageUrl = '${AppConfig.baseUrl}/uploads/${foto.caminho}';
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.broken_image, color: Colors.grey),
                                    ),
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
            ),
          ),
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.extended(
              onPressed: () async {
                // 7. USANDO ROTAS NOMEADAS para navegar
                final result = await Navigator.pushNamed(
                  context,
                  AppRoutes.ocorrenciaCreate,
                  arguments: widget.propriedade.id, // Passando o ID como argumento
                );

                // Recarrega a lista se o usuário voltar da tela de criação
                if (result == true || result == null) {
                  _carregarOcorrencias();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar'),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}