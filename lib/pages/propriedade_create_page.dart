import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/models/atividade.dart';
import 'package:smpp_flutter/models/cidade.dart';
import 'package:smpp_flutter/models/vulnerabilidade.dart';
import 'package:smpp_flutter/providers/propriedade_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';
import 'package:smpp_flutter/services/propriedade_service.dart';
import 'package:smpp_flutter/widgets/app_formatters.dart';

class PropriedadeFormPage extends StatefulWidget {
  const PropriedadeFormPage({super.key});

  @override
  State<PropriedadeFormPage> createState() => _PropriedadeFormPageState();
}

class _PropriedadeFormPageState extends State<PropriedadeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = PropriedadeService();

  final _nomeController = TextEditingController();
  final _proprietarioController = TextEditingController();
  final _telefoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _souProprietario = false;

  List<Cidade> _cidades = [];
  List<Atividade> _atividades = [];
  List<Vulnerabilidade> _vulnerabilidades = [];

  String? _cidadeSelecionadaId;
  List<String> _atividadesSelecionadasIds = [];
  List<String> _vulnerabilidadesSelecionadasIds = [];
  LatLng? _coordenadaSelecionada;

  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _carregarDadosDoFormulario();
  }

  Future<void> _carregarDadosDoFormulario() async {
    try {
      final results = await Future.wait([
        _service.fetchCidades(),
        _service.fetchAtividades(),
        _service.fetchVulnerabilidades(),
        _obterLocalizacaoInicial(),
      ]);

      if (!mounted) return;

      setState(() {
        _cidades = results[0] as List<Cidade>;
        _atividades = results[1] as List<Atividade>;
        _vulnerabilidades = results[2] as List<Vulnerabilidade>;
        _coordenadaSelecionada = results[3] as LatLng?;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  Future<LatLng?> _obterLocalizacaoInicial() async {
    final location = Location();
    try {
      bool serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) serviceEnabled = await location.requestService();
      if (!serviceEnabled) return null;

      PermissionStatus permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return null;
      }
      final locationData = await location.getLocation();
      return LatLng(locationData.latitude!, locationData.longitude!);
    } catch (e) {
      print('Erro ao obter localização: $e');
      return null;
    }
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coordenadaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecione a localização no mapa.')));
      return;
    }

    setState(() => _isSaving = true);

    final propriedadeDto = {
      'cidadeId': _cidadeSelecionadaId,
      'nome': _nomeController.text.toUpperCase(),
      'coordenadas': '${_coordenadaSelecionada!.latitude},${_coordenadaSelecionada!.longitude}',
      'proprietario': _souProprietario ? null : _proprietarioController.text,
      'telefoneProprietario': _souProprietario ? null : _telefoneController.text,
      'atividades': _atividadesSelecionadasIds,
      'vulnerabilidades': _vulnerabilidadesSelecionadasIds,
    };

    try {
      await _service.createPropriedade(propriedadeDto);
      if (!mounted) return;
      await Provider.of<PropriedadeProvider>(context, listen: false).fetchPropriedades();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Propriedade cadastrada com sucesso!'), backgroundColor: Colors.green));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _abrirMapaCompleto() async {
    final LatLng? resultado = await Navigator.pushNamed(
      context,
      AppRoutes.fullMap,
      arguments: {
        'coordenada': _coordenadaSelecionada ?? const LatLng(-29.6843, -53.8016),
        'isReadOnly': false,
      },

    ) as LatLng?;

    if (resultado != null) {
      setState(() => _coordenadaSelecionada = resultado);
      _mapController?.animateCamera(CameraUpdate.newLatLng(resultado));
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _proprietarioController.dispose();
    _telefoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Propriedade'),
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
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(labelText: 'Nome da Propriedade *', border: OutlineInputBorder()),
                maxLength: 50,
                validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _cidadeSelecionadaId,
                items: _cidades.map((cidade) => DropdownMenuItem<String>(value: cidade.id, child: Text(cidade.nome))).toList(),
                onChanged: (value) => setState(() => _cidadeSelecionadaId = value),
                decoration: const InputDecoration(labelText: 'Cidade *', border: OutlineInputBorder()),
                validator: (v) => v == null ? 'Selecione uma cidade' : null,
              ),
              const SizedBox(height: 16),
              const Text('Localização * (toque no mapa para ajustar)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _abrirMapaCompleto,
                child: SizedBox(
                  height: 200,
                  child: _coordenadaSelecionada == null
                      ? Container(color: Colors.grey[300], child: const Center(child: Text('Não foi possível obter a localização')))
                      : ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AbsorbPointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(target: _coordenadaSelecionada!, zoom: 15),
                        markers: {Marker(markerId: const MarkerId('ponto'), position: _coordenadaSelecionada!)},
                        onMapCreated: (controller) => _mapController = controller,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Eu sou o proprietário'),
                value: _souProprietario,
                onChanged: (value) => setState(() => _souProprietario = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (!_souProprietario) ...[
                TextFormField(
                  controller: _proprietarioController,
                  decoration: const InputDecoration(labelText: 'Nome do Proprietário *', border: OutlineInputBorder()),
                  validator: (v) => !_souProprietario && (v == null || v.isEmpty) ? 'Campo obrigatório' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _telefoneController,
                  decoration: const InputDecoration(labelText: 'Telefone do Proprietário *', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  inputFormatters: [AppFormatters.dynamicPhoneMask],
                  validator: (v) {
                    if (_souProprietario) return null;
                    final digits = v?.replaceAll(RegExp(r'\D'), '') ?? '';
                    return digits.length < 10 ? 'Telefone inválido' : null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              MultiSelectDialogField(
                items: _atividades.map((a) => MultiSelectItem<String>(a.id, a.nome)).toList(),
                title: const Text('Atividades'),
                buttonText: const Text('Selecione as Atividades *'),
                onConfirm: (results) => _atividadesSelecionadasIds = results.cast<String>(),
                initialValue: _atividadesSelecionadasIds,
                validator: (v) => v == null || v.isEmpty ? 'Selecione ao menos uma atividade' : null,
                chipDisplay: MultiSelectChipDisplay(),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 16),
              MultiSelectDialogField(
                items: _vulnerabilidades.map((v) => MultiSelectItem<String>(v.id, v.nome)).toList(),
                title: const Text('Vulnerabilidades'),
                buttonText: const Text('Selecione as Vulnerabilidades'),
                onConfirm: (results) => _vulnerabilidadesSelecionadasIds = results.cast<String>(),
                initialValue: _vulnerabilidadesSelecionadasIds,
                chipDisplay: MultiSelectChipDisplay(),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _salvarPropriedade,
                icon: _isSaving
                    ? Container(width: 24, height: 24, padding: const EdgeInsets.all(2.0), child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Icon(Icons.save),
                label: Text(_isSaving ? 'Salvando...' : 'Salvar Propriedade'),
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
}
