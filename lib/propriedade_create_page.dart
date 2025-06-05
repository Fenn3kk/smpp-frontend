import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:smpp_flutter/full_map_page.dart';
import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class PropriedadeFormPage extends StatefulWidget {
  const PropriedadeFormPage({super.key});

  @override
  State<PropriedadeFormPage> createState() => _PropriedadeFormPageState();
}

class _PropriedadeFormPageState extends State<PropriedadeFormPage> {
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

  String? _cidadeSelecionada;

  LatLng? _coordenadaSelecionada;
  LocationData? _posicaoAtual;
  GoogleMapController? _mapController;

  final _fixoMask = MaskTextInputFormatter(
    mask: '(##) ####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  final _celularMask = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );

  @override
  void initState() {
    super.initState();
    _carregarOpcoes();
    _carregarLocalizacaoAtual();
  }

  Future<void> _carregarOpcoes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');
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

  Future<void> _carregarLocalizacaoAtual() async {
    final location = Location();
    try {
      final hasPermission = await location.hasPermission();
      if (hasPermission == PermissionStatus.denied) {
        await location.requestPermission();
      }
      final serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        await location.requestService();
      }
      _posicaoAtual = await location.getLocation();
      setState(() {
        _coordenadaSelecionada = LatLng(_posicaoAtual!.latitude!, _posicaoAtual!.longitude!);
      });
    } catch (e) {
      setState(() {
        _coordenadaSelecionada = const LatLng(-29.6897, -53.8069);
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
    final url = Uri.parse('http://10.0.2.2:8080/propriedades');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': _nomeController.text,
        'cidade': _cidadeSelecionada,
        'coordenadas': '${_coordenadaSelecionada!.latitude},${_coordenadaSelecionada!.longitude}',
        'proprietario': _souProprietario ? '' : _proprietarioController.text,
        'telefoneProprietario': _souProprietario ? '' : _telefoneProprietarioController.text,
        'atividades': _atividadesSelecionadas,
        'vulnerabilidades': _vulnerabilidadesSelecionadas,
      }),
    );

    if (!mounted) return;

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Propriedade cadastrada com sucesso!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: ${response.statusCode}')),
      );
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _proprietarioController.dispose();
    _telefoneProprietarioController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {String? hint, List<TextInputFormatter>? inputFormatters, String? Function(String?)? validator, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        inputFormatters: inputFormatters,
        validator: validator ?? (value) => value == null || value.isEmpty ? 'Digite $label' : null,
        keyboardType: keyboardType,
      ),
    );
  }

  void _abrirMapaCompleto() async {
    if (_coordenadaSelecionada == null) return;
    final LatLng resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapPage(coordenadaInicial: _coordenadaSelecionada!),
      ),
    );

    if (!mounted) return;

    setState(() {
      _coordenadaSelecionada = resultado;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(resultado),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Propriedade'),
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

              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cidadeSelecionada,
                items: _cidades
                    .map((cidade) => DropdownMenuItem<String>(
                  value: cidade['id'],
                  child: Text(cidade['nome']),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _cidadeSelecionada = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Cidade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Selecione uma cidade' : null,
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
                      initialCameraPosition: CameraPosition(
                        target: _coordenadaSelecionada!,
                        zoom: 15,
                      ),
                      markers: {
                        Marker(markerId: const MarkerId('ponto'), position: _coordenadaSelecionada!)
                      },
                      onMapCreated: (controller) {
                        _mapController = controller;
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
                _buildTextField(
                  _telefoneProprietarioController,
                  'Telefone do Proprietário',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

                      if (digits.length > 11) digits = digits.substring(0, 11);

                      final selectionIndex = digits.length;

                      if (digits.length > 10) {
                        final formatted = _celularMask.formatEditUpdate(
                          oldValue,
                          TextEditingValue(
                            text: digits,
                            selection: TextSelection.collapsed(offset: selectionIndex),
                          ),
                        );
                        return formatted;
                      } else {
                        final formatted = _fixoMask.formatEditUpdate(
                          oldValue,
                          TextEditingValue(
                            text: digits,
                            selection: TextSelection.collapsed(offset: selectionIndex),
                          ),
                        );
                        return formatted;
                      }
                    }),
                  ],
                  validator: (value) {
                    if (_souProprietario) return null;
                    final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                    if (digits.length < 10 || digits.length > 11) {
                      return 'Telefone inválido';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),
              const Text('Atividades - No mínimo uma*', style: TextStyle(fontWeight: FontWeight.bold)),
              MultiSelectDialogField(
                items: _atividades.map((e) => MultiSelectItem<String>(e['id'], e['nome'])).toList(),
                title: const Text('Atividades'),
                selectedColor: Colors.blueGrey,
                buttonIcon: const Icon(Icons.list),
                buttonText: const Text('Selecione as atividades'),
                onConfirm: (results) {
                  setState(() {
                    _atividadesSelecionadas = results.cast<String>();
                  });
                },
                initialValue: _atividadesSelecionadas,
                validator: (values) {
                  if (values == null || values.isEmpty) {
                    return 'Selecione pelo menos uma atividade';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              const Text('Vulnerabilidades (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
              MultiSelectDialogField(
                items: _vulnerabilidades.map((e) => MultiSelectItem<String>(e['id'], e['nome'])).toList(),
                title: const Text('Vulnerabilidades'),
                selectedColor: Colors.blueGrey,
                buttonIcon: const Icon(Icons.list),
                buttonText: const Text('Selecione as vulnerabilidades'),
                onConfirm: (results) {
                  setState(() {
                    _vulnerabilidadesSelecionadas = results.cast<String>();
                  });
                },
                initialValue: _vulnerabilidadesSelecionadas,
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _salvarPropriedade,
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
