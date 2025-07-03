import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
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

  String? _tipoSelecionadoId;
  DateTime? _dataSelecionada;
  final List<XFile> _fotos = [];
  final ImagePicker _picker = ImagePicker();
  List<String> _incidentesSelecionadosIds = [];

  List<TipoOcorrencia> _tiposDisponiveis = [];
  List<Incidente> _incidentesDisponiveis = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarDadosIniciais();
    });
  }

  Future<void> _carregarDadosIniciais() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

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
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}'), backgroundColor: Colors.red),
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
      setState(() => _dataSelecionada = data);
    }
  }

  Future<void> _pegarImagem(ImageSource source) async {
    final XFile? foto = await _picker.pickImage(source: source, imageQuality: 80);
    if (foto != null) {
      setState(() => _fotos.add(foto));
    }
  }

  void _removerFoto(int index) {
    setState(() => _fotos.removeAt(index));
  }

  Future<void> _salvarOcorrencia() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (!_formKey.currentState!.validate() || _dataSelecionada == null || _tipoSelecionadoId == null) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos obrigatórios')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final ocorrenciaDto = {
      'tipoOcorrenciaId': _tipoSelecionadoId,
      'data': _dataSelecionada!.toIso8601String().split('T')[0],
      'descricao': _descricaoController.text,
      'propriedadeId': widget.propriedadeId,
      'incidentes': _incidentesSelecionadosIds,
    };

    try {
      await _ocorrenciaService.salvarComFotos(ocorrenciaDto: ocorrenciaDto, fotos: _fotos);
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Ocorrência salva com sucesso!'), backgroundColor: Colors.green),
      );
      navigator.pop(true);
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Ocorrência'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Tipo de Ocorrência *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.category_outlined)),
                items: _tiposDisponiveis.map((tipo) => DropdownMenuItem<String>(value: tipo.id, child: Text(tipo.nome))).toList(),
                value: _tipoSelecionadoId,
                onChanged: (val) => setState(() => _tipoSelecionadoId = val),
                validator: (val) => val == null || val.isEmpty ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição da Ocorrência *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.description_outlined)),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Digite a descrição' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selecionarData,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data da Ocorrência *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today_outlined)),
                  child: Text(
                    _dataSelecionada == null
                        ? 'Selecione uma data'
                        : '${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Fotos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _fotos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _fotos.length) {
                      return Row(
                        children: [
                          _buildAddPhotoButton(onPressed: () => _pegarImagem(ImageSource.camera), icon: Icons.camera_alt_outlined, label: 'Câmera'),
                          const SizedBox(width: 10),
                          _buildAddPhotoButton(onPressed: () => _pegarImagem(ImageSource.gallery), icon: Icons.photo_library_outlined, label: 'Galeria'),
                        ],
                      );
                    }
                    return _buildPhotoPreview(index);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Incidentes Relacionados:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              MultiSelectDialogField(
                items: _incidentesDisponiveis.map((i) => MultiSelectItem<String>(i.id, i.nome)).toList(),
                title: const Text('Incidentes'),
                buttonText: const Text('Selecione os incidentes'),
                onConfirm: (results) {
                  _incidentesSelecionadosIds = results.cast<String>();
                },
                initialValue: _incidentesSelecionadosIds,
                chipDisplay: MultiSelectChipDisplay(),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarOcorrencia,
                icon: _isSaving
                    ? Container(width: 20, height: 20, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Ocorrência'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton({required VoidCallback onPressed, required IconData icon, required String label}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPhotoPreview(int index) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(_fotos[index].path), width: 100, height: 100, fit: BoxFit.cover),
          ),
          IconButton(
            onPressed: () => _removerFoto(index),
            icon: const Icon(Icons.cancel_rounded, color: Colors.white),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
