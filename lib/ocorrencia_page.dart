import 'package:flutter/material.dart';

class OcorrenciasPage extends StatelessWidget {
  const OcorrenciasPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Exemplo de dados que viriam do banco de dados
    final List<Map<String, String>> ocorrencias = [
      {
        'tipo': 'Alagamento',
        'data': '24/04/2025',
        'descricao': 'Água invadiu a plantação.',
        'propriedade': 'Sítio São José',
      },
      {
        'tipo': 'Queda de Ponte',
        'data': '20/04/2025',
        'descricao': 'Ponte de acesso principal caiu.',
        'propriedade': 'Fazenda Boa Vista',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ocorrencias.length,
      itemBuilder: (context, index) {
        final ocorrencia = ocorrencias[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            leading: const Icon(Icons.warning, color: Colors.red),
            title: Text(ocorrencia['tipo'] ?? ''),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Data: ${ocorrencia['data']}'),
                Text('Propriedade: ${ocorrencia['propriedade']}'),
                Text('Descrição: ${ocorrencia['descricao']}'),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}