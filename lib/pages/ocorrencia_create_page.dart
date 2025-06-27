import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smpp_flutter/models/incidente.dart';
import 'package:smpp_flutter/models/tipo_ocorrencia.dart';
import '../services/ocorrencia_service.dart';

class OcorrenciaFormPage extends StatefulWidget {
  final String propriedadeId;

  const OcorrenciaFormPage({super.key, required this.propriedadeId});

  @override
  State<OcorrenciaFormPage> createState() => _OcorrenciaFormPageState();
}

class _OcorrenciaFormPageState extends State<OcorrenciaFormPage> {
  final OcorrenciaService _ocorrenciaService = OcorrenciaService();

  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();

  String? _tipoSelecionado;
  DateTime? _dataSelecionada;
  List<XFile> _fotos = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _incidentesSelecionados = [];

  List<Incidente> _incidentesDisponiveis = [];
  List<TipoOcorrencia> _tiposDisponiveis = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final results = await Future.wait([
        _ocorrenciaService.buscarTiposOcorrencia(),
        _ocorrenciaService.buscarIncidentes(),
      ]);
      if (!mounted) return;
      setState(() {
        _tiposDisponiveis = results[0] as List<TipoOcorrencia>;
        _incidentesDisponiveis = results[1] as List<Incidente>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _selecionarData() async {
    final hoje = DateTime.now();
    final data = await showDatePicker(
      context: context,
      initialDate: hoje,
      firstDate: DateTime(2000),
      lastDate: hoje,
    );
    if (data != null) {
      setState(() {
        _dataSelecionada = data;
      });
    }
  }

  Future<void> _selecionarFotoGaleria() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.gallery);
    if (foto != null) {
      setState(() {
        _fotos.add(foto);
      });
    }
  }

  Future<void> _tirarFotoCamera() async {
    final XFile? foto = await _picker.pickImage(source: ImageSource.camera);
    if (foto != null) {
      setState(() {
        _fotos.add(foto);
      });
    }
  }

  void _removerFoto(int index) {
    setState(() {
      _fotos.removeAt(index);
    });
  }

  Future<void> _salvarOcorrencia() async {
    if (!_formKey.currentState!.validate() || _dataSelecionada == null || _tipoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // Monta o DTO que será enviado como JSON
    final ocorrenciaDto = {
      'tipoOcorrenciaId': _tipoSelecionado!,
      'data': _dataSelecionada!.toIso8601String().split('T')[0],
      'descricao': _descricaoController.text,
      'propriedadeId': widget.propriedadeId,
      'incidentes': _incidentesSelecionados,
    };

    try {
      // Chama o método do serviço, passando o DTO e as fotos
      await _ocorrenciaService.salvarOcorrencia(
        ocorrenciaDto: ocorrenciaDto,
        fotos: _fotos,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ocorrência salva com sucesso!')),
      );
      Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Ocorrência'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Ocorrência *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _tiposDisponiveis.map((tipo) {
                  return DropdownMenuItem<String>(
                    value: tipo.id, // O valor é o ID do tipo
                    child: Text(tipo.nome), // O texto exibido é o nome
                  );
                }).toList(),
                value: _tipoSelecionado,
                onChanged: (val) => setState(() => _tipoSelecionado = val),
                validator: (val) => val == null || val.isEmpty
                    ? 'Selecione um tipo'
                    : null,
              ),
              const SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição da Ocorrência *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
                maxLength: 100,
                validator: (value) =>
                value == null || value.isEmpty ? 'Digite a descrição' : null,
              ),
              const SizedBox(height: 16),

              // Data
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Data da Ocorrência *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _dataSelecionada == null
                        ? 'Selecione uma data'
                        : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}',
                    style: TextStyle(
                      color: _dataSelecionada == null
                          ? Colors.grey[600]
                          : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Fotos
              const Text('Fotos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _fotos.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          children: [
                            FloatingActionButton(
                              heroTag: 'galeria',
                              onPressed: _selecionarFotoGaleria,
                              child: const Icon(Icons.photo_library),
                              mini: true,
                            ),
                            const SizedBox(height: 4),
                            FloatingActionButton(
                              heroTag: 'camera',
                              onPressed: _tirarFotoCamera,
                              child: const Icon(Icons.camera_alt),
                              mini: true,
                            ),
                          ],
                        ),
                      );
                    }

                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_fotos[index].path),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _removerFoto(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Incidentes
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Incidentes Relacionados:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      ..._incidentesDisponiveis.map((incidente) {
                        final id = incidente.id;
                        final nome = incidente.nome;
                        final selecionado = _incidentesSelecionados.contains(id);

                        return CheckboxListTile(
                          title: Text(nome),
                          value: selecionado,
                          onChanged: (bool? val) {
                            setState(() {
                              if (val == true) {
                                _incidentesSelecionados.add(id);
                              } else {
                                _incidentesSelecionados.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botão salvar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _salvarOcorrencia,
                  icon: _isSaving
                      ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3,))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Salvando...' : 'Salvar Ocorrência'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}