import 'package:flutter/material.dart';

class OcorrenciaFormPage extends StatefulWidget {
  const OcorrenciaFormPage({super.key});

  @override
  State<OcorrenciaFormPage> createState() => _OcorrenciaFormPageState();
}

class _OcorrenciaFormPageState extends State<OcorrenciaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  String? _tipoSelecionado;
  DateTime? _dataSelecionada;

  final List<String> _tipos = ['Queda de ponte', 'Alagamento', 'Seca', 'Outros'];

  void _selecionarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorrência salva com sucesso!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Ocorrência'),
        backgroundColor: Colors.grey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo'),
                value: _tipoSelecionado,
                items: _tipos.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoSelecionado = value;
                  });
                },
                validator: (value) => value == null ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Informe a descrição' : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data'),
                subtitle: Text(_dataSelecionada == null
                    ? 'Nenhuma data selecionada'
                    : '${_dataSelecionada!.day}/${_dataSelecionada!.month}/${_dataSelecionada!.year}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _selecionarData,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _salvar,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
