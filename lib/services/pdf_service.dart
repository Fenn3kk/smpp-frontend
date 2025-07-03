import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:smpp_flutter/models/ocorrencia.dart';
import 'package:smpp_flutter/models/propriedade.dart';

class PdfService {
  // GERA O PDF PARA UMA ÚNICA PROPRIEDADE COM SUAS OCORRÊNCIAS
  Future<void> gerarPdfPropriedade(Propriedade propriedade, List<Ocorrencia> ocorrencias) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader('Relatório de Propriedade'),
        build: (context) => [
          _buildPropriedadeInfo(propriedade),
          pw.Divider(height: 30, thickness: 2),
          pw.Text('Ocorrências Registradas', style: pw.Theme.of(context).header2),
          pw.SizedBox(height: 10),
          _buildOcorrenciasInfo(ocorrencias),
        ],
        footer: (context) => _buildFooter(),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // GERA O PDF GERAL COM TODAS AS PROPRIEDADES
  Future<void> gerarPdfGeral(List<Propriedade> propriedades) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        header: (context) => _buildHeader('Relatório Geral de Propriedades'),
        build: (context) => [
          for (final propriedade in propriedades) ...[
            _buildPropriedadeInfo(propriedade),
            pw.Divider(height: 20, thickness: 1, borderStyle: pw.BorderStyle.dashed),
          ]
        ],
        footer: (context) => _buildFooter(),
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // WIDGETS AUXILIARES PARA CONSTRUIR O PDF
  pw.Widget _buildHeader(String title) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('SMPP - Relatório', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
        pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Relatório gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Página', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  pw.Widget _buildPropriedadeInfo(Propriedade propriedade) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(propriedade.nome.toUpperCase(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
        pw.SizedBox(height: 10),
        _buildInfoRow('Cidade:', propriedade.cidade.nome),
        _buildInfoRow('Proprietário:', propriedade.proprietario ?? 'O próprio usuário'),
        _buildInfoRow('Telefone:', propriedade.telefoneProprietario ?? 'Não informado'),
        _buildInfoRow('Coordenadas:', propriedade.coordenadas),
        pw.SizedBox(height: 5),
        pw.Text('Atividades:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Wrap(
          spacing: 5,
          runSpacing: 5,
          children: propriedade.atividades.map((a) => pw.Text('- ${a.nome}')).toList(),
        ),
        pw.SizedBox(height: 5),
        pw.Text('Vulnerabilidades:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Wrap(
          spacing: 5,
          runSpacing: 5,
          children: propriedade.vulnerabilidades.map((v) => pw.Text('- ${v.nome}')).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildOcorrenciasInfo(List<Ocorrencia> ocorrencias) {
    if (ocorrencias.isEmpty) {
      return pw.Text('Nenhuma ocorrência registrada para esta propriedade.');
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: ocorrencias.map((ocorrencia) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(10),
          margin: const pw.EdgeInsets.only(bottom: 10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey, width: 0.5), borderRadius: pw.BorderRadius.circular(5)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('${ocorrencia.tipoOcorrencia.nome} - ${DateFormat('dd/MM/yyyy').format(ocorrencia.data)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 5),
              pw.Text(ocorrencia.descricao ?? 'Sem descrição.'),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
          children: [
            pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(width: 5),
            pw.Text(value),
          ]
      ),
    );
  }
}