import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smpp_flutter/propriedade_edit_page.dart';
import 'ocorrencia_page.dart';

class PropriedadesPage extends StatefulWidget {
  const PropriedadesPage({super.key});

  @override
  State<PropriedadesPage> createState() => PropriedadesPageState();
}

class PropriedadesPageState extends State<PropriedadesPage> {
  List<Map<String, dynamic>> propriedades = [];
  bool carregando = true;
  void recarregar() => _carregarPropriedades();

  @override
  void initState() {
    super.initState();
    _carregarPropriedades();
  }

  Future<void> _carregarPropriedades() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt');

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/propriedades'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List lista = jsonDecode(response.body);
      setState(() {
        propriedades = List<Map<String, dynamic>>.from(lista);
        carregando = false;
      });
    } else {
      setState(() {
        carregando = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar propriedades (${response.statusCode})')),
      );
    }
  }

  Future<void> _excluir(Map<String, dynamic> propriedade, int index) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: const Text('Deseja excluir esta propriedade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt');

      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8080/propriedades/${propriedade['id']}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 204) {
        setState(() {
          propriedades.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriedade excluída com sucesso')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir propriedade')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    Widget _infoRow(IconData icon, String label, String? value, {bool fade = false}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 8),
            fade
                ? Expanded(
              child: SizedBox(
                height: 20,
                child: ShaderMask(
                  shaderCallback: (rect) {
                    return const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.0, 0.1],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(color: Colors.black, fontSize: 16),
                        children: [
                          TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: value ?? ''),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
                : Expanded(
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                  children: [
                    TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: value ?? ''),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (carregando) {
      return const Center(child: CircularProgressIndicator());
    }

    if (propriedades.isEmpty) {
      return RefreshIndicator(
        onRefresh: _carregarPropriedades,
        child: ListView(
          children: const [
            SizedBox(height: 300),
            Center(child: Text('Nenhuma propriedade cadastrada.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregarPropriedades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: propriedades.length,
        itemBuilder: (context, index) {
          final p = propriedades[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          children: [
                            const Icon(Icons.home_work, color: Colors.black),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p['nome'] ?? '',
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Tooltip(
                            message: 'Editar',
                            child: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final resultado = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditarPropriedadePage(propriedade: p),
                                  ),
                                );
                                if (resultado == true) {
                                  _carregarPropriedades();
                                }
                              },
                            ),
                          ),
                          Tooltip(
                            message: 'Excluir',
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _excluir(p, index),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Divider(color: Colors.black54),
                  const SizedBox(height: 16),
                  _infoRow(Icons.location_city, 'Cidade', p['cidade']['nome']),
                  const SizedBox(height: 8),
                  _infoRow(Icons.location_on, 'Coordenadas', p['coordenadas']),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.agriculture,
                    'Atividades',
                    (p['atividades'] as List).map((a) => a['nome']).join(', '),
                    fade: true,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(
                    Icons.warning,
                    'Vulnerabilidades',
                    (p['vulnerabilidades'] as List).isEmpty
                        ? 'Sem registro'
                        : (p['vulnerabilidades'] as List).map((v) => v['nome']).join(', '),
                    fade: true,
                  ),
                  const SizedBox(height: 8),
                  _infoRow(Icons.person, 'Proprietário', p['proprietario'], fade: true),
                  const SizedBox(height: 8),
                  _infoRow(Icons.phone, 'Telefone', p['telefoneProprietario']),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OcorrenciasPage()),
                        );
                      },
                      icon: const Icon(Icons.report),
                      label: const Text('Ver Ocorrências'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}