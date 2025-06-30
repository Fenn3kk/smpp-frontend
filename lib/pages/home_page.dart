import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/pages/propriedade_list_page.dart';
import 'package:smpp_flutter/providers/propriedade_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';
import '../widgets/user_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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

  void _navegarParaCriarPropriedade() async {
    final foiCriado = await Navigator.pushNamed(context, AppRoutes.propriedadeCreate);

    if (foiCriado == true && mounted) {
      // Após a criação, simplesmente notifica o provider para buscar os dados atualizados.
      // 'listen: false' é usado porque só estamos chamando um método, não reconstruindo a HomePage.
      Provider.of<PropriedadeProvider>(context, listen: false).fetchPropriedades();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[800],
        centerTitle: true,
        title: const Text('SMPP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: const UserDrawerWidget(),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _selectedIndex = index),
        children: const [
          PropriedadesPage(), // A página de propriedades continua aqui
          Center(child: Text('Relatórios', style: TextStyle(fontSize: 18))),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
        onPressed: _navegarParaCriarPropriedade,
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_work), label: 'Propriedades'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Relatórios'),
        ],
      ),
    );
  }
}
