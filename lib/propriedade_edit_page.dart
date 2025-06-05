import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:smpp_flutter/full_map_page.dart';

class EditarPropriedadePage extends StatefulWidget {
  final Map<String, dynamic> propriedade;

  const EditarPropriedadePage({super.key, required this.propriedade});

  @override
  State<EditarPropriedadePage> createState() => _EditarPropriedadePageState();
}

class _EditarPropriedadePageState extends State<EditarPropriedadePage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _proprietarioController = TextEditingController();
  final _telefoneProprietarioController = TextEditingController();

  bool _souProprietario = false;
  List<Map<String, dynamic>> _atividades = [];
  List<Map<String, dynamic>> _vulnerabilidades = [];
  List<Map<String, dynamic>> _cidades = [];

  List<String> _atividadesSelecionadas = [];
  List<String> _vulnerabilidadesSelecionadas = [];
  String? _cidadeSelecionadaId;

  LatLng? _coordenadaSelecionada;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    _nomeController.text = widget.propriedade['nome'];

    _souProprietario = widget.propriedade['proprietario'].toString().isEmpty;
    if (!_souProprietario) {
      _proprietarioController.text = widget.propriedade['proprietario'];
      _telefoneProprietarioController.text = widget.propriedade['telefoneProprietario'];
    }

    final partes = widget.propriedade['coordenadas'].split(',');
    if (partes.length == 2) {
      final lat = double.tryParse(partes[0]);
      final lng = double.tryParse(partes[1]);
      if (lat != null && lng != null) {
        _coordenadaSelecionada = LatLng(lat, lng);
      }
    }

    _atividadesSelecionadas = (widget.propriedade['atividades'] as List<dynamic>?)
        ?.map((a) => a['id'].toString())
        .toList() ??
        [];

    _vulnerabilidadesSelecionadas =
        (widget.propriedade['vulnerabilidades'] as List<dynamic>?)
            ?.map((v) => v['id'].toString())
            .toList() ??
            [];

    _cidadeSelecionadaId = widget.propriedade['cidade']['id'].toString();

    _carregarOpcoes();
  }

  Future<void> _carregarOpcoes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    print(token);
    final headers = {'Authorization': 'Bearer $token'};

    final atividadesResponse = await http.get(Uri.parse('http://10.0.2.2:8080/atividades'), headers: headers);
    final vulnerabilidadesResponse = await http.get(Uri.parse('http://10.0.2.2:8080/vulnerabilidades'), headers: headers);
    final cidadesResponse = await http.get(Uri.parse('http://10.0.2.2:8080/cidades'), headers: headers);

    if (atividadesResponse.statusCode == 200 &&
        vulnerabilidadesResponse.statusCode == 200 &&
        cidadesResponse.statusCode == 200) {
      setState(() {
        _atividades = List<Map<String, dynamic>>.from(json.decode(atividadesResponse.body));
        _vulnerabilidades = List<Map<String, dynamic>>.from(json.decode(vulnerabilidadesResponse.body));
        _cidades = List<Map<String, dynamic>>.from(json.decode(cidadesResponse.body));
      });
    }
  }

  Future<void> _salvarPropriedade() async {
    if (!_formKey.currentState!.validate()) return;
    if (_atividadesSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma atividade.')),
      );
      return;
    }
    if (_coordenadaSelecionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a localização no mapa.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
    final url = Uri.parse('http://10.0.2.2:8080/propriedades/${widget.propriedade['id']}');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': _nomeController.text,
        'cidade': _cidadeSelecionadaId,
        'coordenadas': '${_coordenadaSelecionada!.latitude},${_coordenadaSelecionada!.longitude}',
        'proprietario': _souProprietario ? '' : _proprietarioController.text,
        'telefoneProprietario': _souProprietario ? '' : _telefoneProprietarioController.text,
        'atividades': _atividadesSelecionadas,
        'vulnerabilidades': _vulnerabilidadesSelecionadas,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriedade atualizada com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: ${response.statusCode}')),
      );
    }
  }

  void _abrirMapaCompleto() async {
    final LatLng resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapPage(coordenadaInicial: _coordenadaSelecionada!),
      ),
    );
    setState(() {
      _coordenadaSelecionada = resultado;
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(_coordenadaSelecionada!));
      }
    });
  }

  Widget _buildTextField(TextEditingController controller, String label, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Digite $label' : null,
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _proprietarioController.dispose();
    _telefoneProprietarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Propriedade'),
        backgroundColor: Colors.grey[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(_nomeController, 'Nome da Propriedade'),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: DropdownButtonFormField<String>(
                  value: _cidadeSelecionadaId,
                  decoration: const InputDecoration(
                    labelText: 'Cidade',
                    border: OutlineInputBorder(),
                  ),
                  items: _cidades.map((cidade) {
                    return DropdownMenuItem<String>(
                      value: cidade['id'].toString(),
                      child: Text(cidade['nome']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _cidadeSelecionadaId = value;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Selecione a cidade' : null,
                ),
              ),

              const SizedBox(height: 16),
              const Text('Localização (toque para abrir)', style: TextStyle(fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: _coordenadaSelecionada == null ? null : _abrirMapaCompleto,
                child: SizedBox(
                  height: 150,
                  child: _coordenadaSelecionada == null
                      ? const Center(child: CircularProgressIndicator())
                      : AbsorbPointer(
                    child: GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                      initialCameraPosition: CameraPosition(
                        target: _coordenadaSelecionada!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(markerId: const MarkerId('ponto'), position: _coordenadaSelecionada!)
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              CheckboxListTile(
                title: const Text('Eu sou o proprietário'),
                value: _souProprietario,
                onChanged: (value) => setState(() => _souProprietario = value ?? false),
              ),

              if (!_souProprietario) ...[
                _buildTextField(_proprietarioController, 'Proprietário'),
                _buildTextField(_telefoneProprietarioController, 'Telefone do Proprietário'),
              ],

              const SizedBox(height: 16),
              const Text('Atividades - No mínimo uma*', style: TextStyle(fontWeight: FontWeight.bold)),
              MultiSelectDialogField(
                items: _atividades
                    .map((e) => MultiSelectItem<String>(e['id'].toString(), e['nome']))
                    .toList(),
                title: const Text("Atividades"),
                buttonText: const Text("Selecionar Atividades"),
                initialValue: _atividadesSelecionadas,
                onConfirm: (values) {
                  _atividadesSelecionadas = List<String>.from(values);
                },
                validator: (values) =>
                values == null || values.isEmpty ? 'Selecione pelo menos uma atividade' : null,
              ),

              const SizedBox(height: 16),
              const Text('Vulnerabilidades - Não obrigatório', style: TextStyle(fontWeight: FontWeight.bold)),
              MultiSelectDialogField(
                items: _vulnerabilidades
                    .map((e) => MultiSelectItem<String>(e['id'].toString(), e['nome']))
                    .toList(),
                title: const Text("Vulnerabilidades"),
                buttonText: const Text("Selecionar Vulnerabilidades"),
                initialValue: _vulnerabilidadesSelecionadas,
                onConfirm: (values) {
                  _vulnerabilidadesSelecionadas = List<String>.from(values);
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _salvarPropriedade,
                icon: const Icon(Icons.save),
                label: const Text('Salvar Alterações'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
