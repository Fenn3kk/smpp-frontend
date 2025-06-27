import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smpp_flutter/models/propriedade.dart';
import 'package:smpp_flutter/providers/propriedade_provider.dart';
import 'package:smpp_flutter/rotas/app_rotas.dart';
import 'package:smpp_flutter/widgets/info_row.dart';

class PropriedadesPage extends StatefulWidget {
  const PropriedadesPage({super.key});

  @override
  State<PropriedadesPage> createState() => _PropriedadesPageState();
}

class _PropriedadesPageState extends State<PropriedadesPage> {
  @override
  void initState() {
    super.initState();
    // Pede ao provider para carregar os dados assim que a tela for construída.
    // Usamos Future.microtask para garantir que o 'context' esteja pronto.
    Future.microtask(() =>
        Provider.of<PropriedadeProvider>(context, listen: false).fetchPropriedades());
  }

  /// Exclui uma propriedade através do provider e exibe o feedback na UI.
  Future<void> _excluir(PropriedadeProvider provider, Propriedade propriedade) async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Propriedade excluída com sucesso'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Navega para outras telas e recarrega os dados se necessário.
  void _navegarPara(String routeName, Propriedade propriedade) async {
    final foiModificado = await Navigator.pushNamed(context, routeName, arguments: propriedade);
    if (foiModificado == true && mounted) {
      Provider.of<PropriedadeProvider>(context, listen: false).fetchPropriedades();
    }
  }

  @override
  Widget build(BuildContext context) {
    // O Consumer reconstrói a UI automaticamente quando o provider notifica mudanças.
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
            padding: const EdgeInsets.all(16),
            itemCount: provider.propriedades.length,
            itemBuilder: (context, index) {
              final p = provider.propriedades[index];
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.home_work_outlined, color: Colors.teal, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              p.nome,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                onPressed: () => _navegarPara(AppRoutes.propriedadeEdit, p),
                                tooltip: 'Editar Propriedade',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _excluir(provider, p),
                                tooltip: 'Excluir Propriedade',
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24, thickness: 1),
                      InfoRowWidget(icon: Icons.location_city, label: 'Cidade', value: p.cidade.nome),
                      InfoRowWidget(icon: Icons.map_outlined, label: 'Coordenadas', value: p.coordenadas),
                      InfoRowWidget(icon: Icons.agriculture_outlined, label: 'Atividades', value: p.atividades.map((a) => a.nome).join(', '), fade: true),
                      InfoRowWidget(
                        icon: Icons.warning_amber_rounded,
                        label: 'Vulnerabilidades',
                        value: p.vulnerabilidades.isEmpty ? null : p.vulnerabilidades.map((v) => v.nome).join(', '),
                        fade: true,
                      ),
                      InfoRowWidget(icon: Icons.person_outline, label: 'Proprietário', value: p.proprietario),
                      InfoRowWidget(icon: Icons.phone_outlined, label: 'Telefone', value: p.telefoneProprietario),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () => _navegarPara(AppRoutes.ocorrencia, p),
                          icon: const Icon(Icons.report_problem_outlined),
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
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchPropriedades(),
          child: body,
        );
      },
    );
  }
}
