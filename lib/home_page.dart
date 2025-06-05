import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:smpp_flutter/admin_cadastro_page.dart';

import 'package:smpp_flutter/usuario_edit_page.dart';
import 'package:smpp_flutter/ocorrencia_form_page.dart';
import 'package:smpp_flutter/propriedade_page.dart';
import 'login_page.dart';
import 'propriedade_create_page.dart';

class HomePage extends StatefulWidget {
  final int initialIndex;

  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex;
  late PageController _pageController;
  final GlobalKey<PropriedadesPageState> _propriedadesKey = GlobalKey();

  String? _nome;
  String? _email;
  String? _telefone;
  String? _jwt;
  String? _usuarioId;
  bool _carregandoUsuario = true;
  String? _tipoUsuario;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
    _carregarDadosUsuario();
  }

  Future<void> _carregarDadosUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    _jwt = prefs.getString('jwt');
    _usuarioId = prefs.getString('usuarioId');

    if (_jwt == null || _usuarioId == null) {
      setState(() => _carregandoUsuario = false);
      return;
    }

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8080/usuarios/$_usuarioId'),
      headers: {'Authorization': 'Bearer $_jwt'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _nome = data['nome'];
        _email = data['email'];
        _telefone = data['telefone'];
        _tipoUsuario = data['tipoUsuario'];
        _carregandoUsuario = false;
      });
    } else {
      setState(() => _carregandoUsuario = false);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        centerTitle: true,
        title: const Text(
          'SMPP',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Colors.grey[800],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: _carregandoUsuario
                  ? const Center(child: CircularProgressIndicator(color: Colors.white))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.account_circle, color: Colors.white, size: 52),
                      SizedBox(width: 12),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _nome ?? 'Usuário',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _email ?? 'Email não disponível',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _telefone ?? 'Telefone não disponível',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _tipoUsuario != null
                        ? 'Tipo: $_tipoUsuario'
                        : 'Tipo de usuário não disponível',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.black87),
              title: const Text('Editar/Excluir Usuário'),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EditarUsuarioPage()),
                );
                _carregarDadosUsuario();
              },
            ),
            if (!_carregandoUsuario && _tipoUsuario == 'ADMIN')
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.black87),
                title: const Text('Cadastrar Usuários'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CadastroAdminPage()),
                  );
                },
              ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sair'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            children: [
              PropriedadesPage(key: _propriedadesKey),
              const Center(
                child: Text('Relatórios', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          Positioned(
            bottom: 50,
            right: 16,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _selectedIndex == 0 ? 1.0 : 0.0,
              child: IgnorePointer(
                ignoring: _selectedIndex != 0,
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PropriedadeFormPage(),
                      ),
                    );
                    _propriedadesKey.currentState?.recarregar();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar'),
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey[800],
        unselectedItemColor: Colors.grey[500],
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_work),
            label: 'Propriedades',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Relatórios',
          ),
        ],
      ),
    );
  }
}
