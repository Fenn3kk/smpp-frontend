import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/providers/propriedade_provider.dart';
import 'package:smpp_flutter/routes/app_rotas.dart';

class PropriedadesPage extends StatefulWidget {
  const PropriedadesPage({super.key});

  @override
  State<PropriedadesPage> createState() => _PropriedadesPageState();
}

class _PropriedadesPageState extends State<PropriedadesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<PropriedadeProvider>(context, listen: false).fetchPropriedades());
  }

  Future<void> _excluir(PropriedadeProvider provider, Propriedade propriedade) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir a propriedade "${propriedade.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      try {
        await provider.deletePropriedade(propriedade.id);
        scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('Propriedade excluída com sucesso'), backgroundColor: Colors.green),
        );
      } catch (e) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _navegarPara(String routeName, Propriedade propriedade) async {
    final navigator = Navigator.of(context);
    final provider = Provider.of<PropriedadeProvider>(context, listen: false);

    final foiModificado = await navigator.pushNamed(routeName, arguments: propriedade);

    if (foiModificado == true && mounted) {
      provider.fetchPropriedades();
    }
  }

  void _navegarParaMapa(Propriedade propriedade) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final parts = propriedade.coordenadas.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          await navigator.pushNamed(
            AppRoutes.fullMap,
            arguments: {
              'coordenada': LatLng(lat, lng),
              'isReadOnly': true,
            },
          );
        }
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Coordenadas inválidas.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropriedadeProvider>(
      builder: (context, provider, child) {
        Widget body;

        if (provider.isLoading && provider.propriedades.isEmpty) {
          body = const Center(child: CircularProgressIndicator());
        } else if (provider.errorMessage != null) {
          body = Center(child: Text('Ocorreu um erro: ${provider.errorMessage}'));
        } else if (provider.propriedades.isEmpty) {
          body = const Center(child: Text('Nenhuma propriedade cadastrada.'));
        } else {
          body = ListView.builder(
            padding: const EdgeInsets.fromLTRB(1, 1, 1, 70),
            itemCount: provider.propriedades.length,
            itemBuilder: (context, index) {
              final p = provider.propriedades[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    p.nome,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                  subtitle: Text(p.cidade.nome, style: const TextStyle(color: Colors.black54)),
                  leading: const Icon(Icons.home_work_outlined, color: Colors.teal, size: 32),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _navegarPara(AppRoutes.propriedadeEdit, p);
                      } else if (value == 'delete') {
                        _excluir(provider, p);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Editar')),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Excluir', style: TextStyle(color: Colors.red))),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildDetailItem(context, Icons.person_outline, 'Proprietário', p.proprietario),
                          _buildDetailItem(context, Icons.phone_outlined, 'Telefone', p.telefoneProprietario),
                          _buildMapLink(context, p),
                          const SizedBox(height: 16),
                          _buildChipSection(context, 'Atividades', Icons.agriculture_outlined, p.atividades.map((a) => a.nome).toList()),
                          const SizedBox(height: 12),
                          _buildChipSection(context, 'Vulnerabilidades', Icons.warning_amber_rounded, p.vulnerabilidades.map((v) => v.nome).toList()),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _navegarPara(AppRoutes.ocorrencia, p),
                              icon: const Icon(Icons.report_problem_outlined, size: 18),
                              label: const Text('Ver Ocorrências'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPropriedades(),
          child: body,
        );
      },
    );
  }

  Widget _buildChipSection(BuildContext context, String title, IconData icon, List<String> items) {
    final themeColor = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        if (items.isEmpty)
          const Text('Nenhuma registrada', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54))
        else
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: items.map((item) => Chip(
              label: Text(item),
              backgroundColor: themeColor.withOpacity(0.1),
              side: BorderSide(color: themeColor.withOpacity(0.2)),
              labelStyle: TextStyle(color: themeColor, fontWeight: FontWeight.w500),
            )).toList(),
          ),
      ],
    );
  }

  Widget _buildDetailItem(BuildContext context, IconData icon, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Não informado',
                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLink(BuildContext context, Propriedade propriedade) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.map_outlined, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localização',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _navegarParaMapa(propriedade),
                  child: Text(
                    'Ver no mapa',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade700,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
