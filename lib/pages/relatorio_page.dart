import 'package:flutter/material.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';
import 'package:smpp_flutter/services/pdf_service.dart';
import 'package:smpp_flutter/services/propriedade_service.dart';

class RelatoriosPage extends StatelessWidget {
  const RelatoriosPage({super.key});

  void _gerarRelatorioGeral(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gerar Relatório Geral?'),
        content: const Text('Deseja gerar um PDF com os dados de todas as propriedades cadastradas?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Gerar PDF', style: TextStyle(color: Colors.teal))),
        ],
      ),
    );

    if (confirmar == true) {
      showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()), barrierDismissible: false);

      try {
        final todasPropriedades = await PropriedadeService().buscarTodasPropriedades();

        await PdfService().gerarPdfGeral(todasPropriedades);
      } catch(e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar relatório: ${e.toString()}')));
      } finally {
        if (context.mounted) Navigator.of(context).pop(); // Fecha o indicador de carregamento
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.description, color: Colors.teal),
            title: const Text('Relatório por Propriedade'),
            subtitle: const Text('Selecione uma propriedade para ver detalhes e ocorrências.'),
            onTap: () => Navigator.of(context).pushNamed(AppRoutes.relatorioPropriedadeList),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Relatório Geral de Propriedades'),
            subtitle: const Text('Gere um PDF com os dados de todas as suas propriedades.'),
            onTap: () => _gerarRelatorioGeral(context),
          ),
        ],
      ),
    );
  }
}