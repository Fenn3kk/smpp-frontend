import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/config/app_config.dart';
import 'package:smpp_flutter/models/incidente.dart';
import 'package:smpp_flutter/models/ocorrencia.dart';
import 'package:smpp_flutter/models/tipo_ocorrencia.dart';
import 'package:smpp_flutter/models/foto_ocorrencia.dart';
import 'package:smpp_flutter/providers/ocorrencia_provider.dart';
import 'package:smpp_flutter/services/ocorrencia_service.dart';

class OcorrenciaEditPage extends StatefulWidget {
  final Ocorrencia ocorrencia;
  final String propriedadeId;

  const OcorrenciaEditPage({
    super.key,
    required this.ocorrencia,
    required this.propriedadeId,
  });

  @override
  State<OcorrenciaEditPage> createState() => _OcorrenciaEditPageState();
}

class _OcorrenciaEditPageState extends State<OcorrenciaEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _ocorrenciaService = OcorrenciaService();

  late final TextEditingController _descricaoController;
  String? _tipoSelecionadoId;
  DateTime? _dataSelecionada;

  late List<FotoOcorrencia> _fotosExistentes;
  final List<XFile> _fotosNovas = [];
  final List<String> _idsFotosParaExcluir = [];

  List<String> _incidentesSelecionadosIds = [];
  List<TipoOcorrencia> _tiposDisponiveis = [];
  List<Incidente> _incidentesDisponiveis = [];

  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _popularFormularioInicial();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _carregarOpcoes();
    });
  }

  void _popularFormularioInicial() {
    final o = widget.ocorrencia;
    _descricaoController = TextEditingController(text: o.descricao);
    _tipoSelecionadoId = o.tipoOcorrencia.id;
    _dataSelecionada = o.data;
    _incidentesSelecionadosIds = o.incidentes.map((i) => i.id).toList();
    _fotosExistentes = List.from(o.fotos);
  }

  Future<void> _carregarOpcoes() async {
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
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro ao carregar opções: ${e.toString()}')));
    }
  }

  void _removerFotoExistente(FotoOcorrencia foto) {
    setState(() {
      _idsFotosParaExcluir.add(foto.id);
      _fotosExistentes.remove(foto);
    });
  }

  void _removerFotoNova(int index) {
    setState(() => _fotosNovas.removeAt(index));
  }

  Future<void> _pegarImagem(ImageSource source) async {
    final XFile? foto = await _picker.pickImage(source: source, imageQuality: 80);
    if (foto != null) {
      setState(() => _fotosNovas.add(foto));
    }
  }

  Future<void> _salvarAlteracoes() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final provider = Provider.of<OcorrenciaProvider>(context, listen: false);

    if (!_formKey.currentState!.validate()) return;
    if (_dataSelecionada == null) return;

    setState(() => _isSaving = true);

    final updateDto = {
      'tipoOcorrenciaId': _tipoSelecionadoId,
      'data': _dataSelecionada!.toIso8601String().split('T')[0],
      'descricao': _descricaoController.text,
      'incidentes': _incidentesSelecionadosIds,
      'fotosParaExcluir': _idsFotosParaExcluir,
    };

    try {
      await _ocorrenciaService.updateOcorrencia(
        ocorrenciaId: widget.ocorrencia.id,
        updateDto: updateDto,
        novasFotos: _fotosNovas,
      );
      if (!mounted) return;

      await provider.fetchOcorrenciasPorPropriedade(widget.propriedadeId);

      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Ocorrência atualizada com sucesso!'), backgroundColor: Colors.green));
      navigator.pop(true);

    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _mostrarFotoAmpliada({File? fotoLocal, FotoOcorrencia? fotoRemota, int? indexLocal}) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: InteractiveViewer(
                panEnabled: false,
                minScale: 1.0,
                maxScale: 4.0,
                child: fotoLocal != null
                    ? Image.file(fotoLocal, fit: BoxFit.contain)
                    : Image.network('${AppConfig.baseUrl}${fotoRemota!.url}', fit: BoxFit.contain),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar', style: TextStyle(color: Colors.white))),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (fotoLocal != null) {
                      _removerFotoNova(indexLocal!);
                    } else {
                      _confirmarExclusaoFotoExistente(fotoRemota!);
                    }
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  label: const Text('Excluir', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusaoFotoExistente(FotoOcorrencia foto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja realmente excluir esta foto?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmar == true) {
      _removerFotoExistente(foto);
    }
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Ocorrência'),
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
                value: _tipoSelecionadoId,
                items: _tiposDisponiveis.map((tipo) => DropdownMenuItem<String>(value: tipo.id, child: Text(tipo.nome))).toList(),
                onChanged: (val) => setState(() => _tipoSelecionadoId = val),
                decoration: const InputDecoration(labelText: 'Tipo de Ocorrência *', border: OutlineInputBorder()),
                validator: (val) => val == null ? 'Selecione um tipo' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(labelText: 'Descrição *', border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Digite a descrição' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final data = await showDatePicker(context: context, initialDate: _dataSelecionada!, firstDate: DateTime(2000), lastDate: DateTime.now());
                  if (data != null) setState(() => _dataSelecionada = data);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Data da Ocorrência *', border: OutlineInputBorder()),
                  child: Text(_dataSelecionada != null ? '${_dataSelecionada!.day.toString().padLeft(2, '0')}/${_dataSelecionada!.month.toString().padLeft(2, '0')}/${_dataSelecionada!.year}' : 'Selecione uma data'),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Fotos da Ocorrência', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),

              if (_fotosExistentes.isEmpty && _fotosNovas.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 16),
                  child: Text('Sem fotos.', style: TextStyle(color: Colors.black54)),
                ),

              if (_fotosExistentes.isNotEmpty)
                _buildPhotoSection(
                  title: 'Fotos Atuais',
                  fotos: _fotosExistentes.map((foto) => _buildPhotoThumbnail(fotoRemota: foto)).toList(),
                ),

              if (_fotosNovas.isNotEmpty)
                _buildPhotoSection(
                  title: 'Novas Fotos',
                  fotos: _fotosNovas.asMap().entries.map((entry) => _buildPhotoThumbnail(fotoLocal: File(entry.value.path), indexLocal: entry.key)).toList(),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAddPhotoButton(onPressed: () => _pegarImagem(ImageSource.camera), icon: Icons.camera_alt_outlined, label: 'Câmera'),
                  const SizedBox(width: 20),
                  _buildAddPhotoButton(onPressed: () => _pegarImagem(ImageSource.gallery), icon: Icons.photo_library_outlined, label: 'Galeria'),
                ],
              ),

              const SizedBox(height: 16),
              MultiSelectDialogField(
                items: _incidentesDisponiveis.map((i) => MultiSelectItem<String>(i.id, i.nome)).toList(),
                initialValue: _incidentesSelecionadosIds,
                title: const Text('Incidentes'),
                buttonText: const Text('Selecione os Incidentes'),
                onConfirm: (results) => _incidentesSelecionadosIds = results.cast<String>(),
                chipDisplay: MultiSelectChipDisplay(),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(4)),
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarAlteracoes,
                icon: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection({required String title, required List<Widget> fotos}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        ),
        SizedBox(
          height: 110,
          child: ListView(scrollDirection: Axis.horizontal, children: fotos),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildPhotoThumbnail({File? fotoLocal, FotoOcorrencia? fotoRemota, int? indexLocal}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => _mostrarFotoAmpliada(fotoLocal: fotoLocal, fotoRemota: fotoRemota, indexLocal: indexLocal),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: fotoLocal != null
              ? Image.file(fotoLocal, width: 100, height: 100, fit: BoxFit.cover)
              : Image.network('${AppConfig.baseUrl}${fotoRemota!.url}', width: 100, height: 100, fit: BoxFit.cover),
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
}
