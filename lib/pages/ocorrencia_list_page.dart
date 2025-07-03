import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/config/app_config.dart';
import 'package:smpp_flutter/models/foto_ocorrencia.dart';
import 'package:smpp_flutter/models/ocorrencia.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/providers/ocorrencia_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';

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
    final navigator = Navigator.of(context);
    final provider = Provider.of<OcorrenciaProvider>(context, listen: false);

    final foiCriado = await navigator.pushNamed(
      AppRoutes.ocorrenciaCreate,
      arguments: widget.propriedade.id,
    );

    if (foiCriado == true && mounted) {
      provider.fetchOcorrenciasPorPropriedade(widget.propriedade.id);
    }
  }

  void _onActionSelected(String action, Ocorrencia ocorrencia) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<OcorrenciaProvider>(context, listen: false);

    if (action == 'edit') {
      // CORREÇÃO: Envia um Map com a ocorrência E o ID da propriedade.
      final foiModificado = await navigator.pushNamed(
          AppRoutes.ocorrenciaEdit,
          arguments: {
            'ocorrencia': ocorrencia,
            'propriedadeId': widget.propriedade.id,
          }
      );
      if (foiModificado == true && mounted) {
        provider.fetchOcorrenciasPorPropriedade(widget.propriedade.id);
      }
    } else if (action == 'delete') {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final provider = Provider.of<OcorrenciaProvider>(context, listen: false);

      // 1. Mostrar diálogo de confirmação
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Tem certeza que deseja excluir a ocorrência "${ocorrencia.tipoOcorrencia.nome}"? Esta ação não pode ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      // 2. Se o usuário confirmou, chamar o provider
      if (confirmar == true && mounted) {
        try {
          await provider.excluirOcorrencia(ocorrencia.id);
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Ocorrência excluída com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _mostrarFotoAmpliada(String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: GestureDetector(
          onTap: () => Navigator.of(ctx).pop(),
          child: InteractiveViewer(
            panEnabled: false,
            minScale: 1.0,
            maxScale: 4.0,
            child: Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          // MODIFICAÇÃO 1: Alinha o texto do subtítulo ao centro da coluna
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Ocorrências',
              style: TextStyle(
                // MODIFICAÇÃO 2: Aumenta o tamanho da fonte principal
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.propriedade.nome,
              style: const TextStyle(
                // MODIFICAÇÃO 3: Aumenta o tamanho da fonte do subtítulo
                fontSize: 20,
                color: Colors.white70,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        // MODIFICAÇÃO 4: Garante que o bloco do título fique centralizado na AppBar
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
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
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 90),
              itemCount: provider.ocorrencias.length,
              itemBuilder: (context, index) {
                final ocorrencia = provider.ocorrencias[index];
                final data = ocorrencia.data;
                final dataFormatada = '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: Text(ocorrencia.tipoOcorrencia.nome, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
                    subtitle: Text('Data: $dataFormatada', style: const TextStyle(color: Colors.black54)),
                    leading: const Icon(Icons.report_problem_outlined, color: Colors.teal, size: 32),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) => _onActionSelected(value, ocorrencia),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem<String>(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar'))),
                        const PopupMenuItem<String>(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Excluir', style: TextStyle(color: Colors.red)))),
                      ],
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 16),
                            _buildDetailItem(context, 'Descrição', ocorrencia.descricao),
                            const SizedBox(height: 16),
                            _buildChipSection(context, 'Incidentes', ocorrencia.incidentes.map((i) => i.nome).toList()),
                            if (ocorrencia.fotos.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              _buildPhotoSection(context, 'Fotos', ocorrencia.fotos),
                            ],
                          ],
                        ),
                      ),
                    ],
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

  Widget _buildDetailItem(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value ?? 'Não informado', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildChipSection(BuildContext context, String title, List<String> items) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('Nenhum registrado', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54))
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items.map((item) => Chip(
              label: Text(item),
              backgroundColor: themeColor.withOpacity(0.1),
              side: BorderSide(color: themeColor.withOpacity(0.2)),
              labelStyle: TextStyle(color: themeColor, fontWeight: FontWeight.w500),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context, String title, List<FotoOcorrencia> fotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fotos.length,
            itemBuilder: (ctx, i) {
              final foto = fotos[i];
              final imageUrl = '${AppConfig.baseUrl}${foto.url}';
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () => _mostrarFotoAmpliada(imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 100, height: 100, fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}