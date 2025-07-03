import 'package:flutter/material.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/services/ocorrencia_service.dart';
import 'package:smpp_flutter/services/pdf_service.dart';
import 'package:smpp_flutter/services/propriedade_service.dart';

class RelatorioPropriedadeListPage extends StatefulWidget {
  const RelatorioPropriedadeListPage({super.key});

  @override
  State<RelatorioPropriedadeListPage> createState() => _RelatorioPropriedadeListPageState();
}

class _RelatorioPropriedadeListPageState extends State<RelatorioPropriedadeListPage> {
  late Future<List<Propriedade>> _propriedadesFuture;
  final _propriedadeService = PropriedadeService();
  final _pdfService = PdfService();
  final _ocorrenciaService = OcorrenciaService();

  bool _isGeneratingPdf = false;
  String? _generatingPdfId;

  @override
  void initState() {
    super.initState();
    _propriedadesFuture = _propriedadeService.buscarTodasPropriedades();
  }

  Future<void> _gerarPdfIndividual(Propriedade propriedade) async {
    setState(() {
      _isGeneratingPdf = true;
      _generatingPdfId = propriedade.id;
    });

    try {
      final ocorrencias = await _ocorrenciaService.buscarOcorrenciasPorPropriedade(propriedade.id);
      // 2. Gera o PDF
      await _pdfService.gerarPdfPropriedade(propriedade, ocorrencias);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao gerar PDF: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingPdf = false;
          _generatingPdfId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório por Propriedade'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Propriedade>>(
        future: _propriedadesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar propriedades: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma propriedade encontrada.'));
          }

          final propriedades = snapshot.data!;
          return ListView.builder(
            itemCount: propriedades.length,
            itemBuilder: (ctx, i) {
              final propriedade = propriedades[i];
              final isGenerating = _isGeneratingPdf && _generatingPdfId == propriedade.id;

              return ListTile(
                title: Text(propriedade.nome),
                subtitle: Text(propriedade.cidade.nome),
                trailing: isGenerating
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 3))
                    : IconButton(
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  onPressed: () => _gerarPdfIndividual(propriedade),
                  tooltip: 'Gerar PDF desta propriedade',
                ),
              );
            },
          );
        },
      ),
    );
  }
}