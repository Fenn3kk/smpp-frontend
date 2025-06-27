import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class FullMapPage extends StatefulWidget {
  final LatLng coordenadaInicial;

  const FullMapPage({super.key, required this.coordenadaInicial});

  @override
  State<FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<FullMapPage> {
  // O GoogleMapController é a chave para interagir com o mapa programaticamente.
  GoogleMapController? _mapController;

  // A coordenada selecionada agora é atualizada quando o mapa para de se mover.
  late LatLng _coordenadaSelecionada;

  @override
  void initState() {
    super.initState();
    _coordenadaSelecionada = widget.coordenadaInicial;
  }

  /// Leva o mapa para a localização atual do dispositivo.
  Future<void> _irParaMinhaLocalizacao() async {
    final location = Location();
    try {
      final locationData = await location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final minhaPosicao = LatLng(locationData.latitude!, locationData.longitude!);
        _mapController?.animateCamera(CameraUpdate.newLatLng(minhaPosicao));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível obter a localização atual.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Localização'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // O Mapa ocupa todo o espaço
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _coordenadaSelecionada,
              zoom: 16,
            ),
            onMapCreated: (controller) => _mapController = controller,
            // ATUALIZAÇÃO DE PERFORMANCE: Usamos onCameraIdle
            // Isso atualiza a coordenada apenas quando o usuário para de arrastar o mapa.
            onCameraIdle: () async {
              if (_mapController != null) {
                // Pega a lat/lng do centro da tela do mapa
                final centerLatLng = await _mapController!.getLatLng(
                  ScreenCoordinate(
                    x: MediaQuery.of(context).size.width.floor() ~/ 2,
                    y: MediaQuery.of(context).size.height.floor() ~/ 2,
                  ),
                );
                setState(() {
                  _coordenadaSelecionada = centerLatLng;
                });
              }
            },
            myLocationButtonEnabled: false, // Desativamos o botão padrão
            myLocationEnabled: true, // Mostra o ponto azul da localização do usuário
          ),

          // 1. O PINO CENTRAL FIXO: Este ícone nunca se move.
          const IgnorePointer(
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 50,
            ),
          ),

          // 2. BOTÕES DE AÇÃO: Alinhados no canto inferior direito.
          Positioned(
            bottom: 30,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 3. NOVO BOTÃO: Ir para a localização atual
                FloatingActionButton(
                  heroTag: 'myLocation',
                  onPressed: _irParaMinhaLocalizacao,
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 16),
                // Botão de confirmação melhorado
                FloatingActionButton.extended(
                  heroTag: 'confirmLocation',
                  onPressed: () => Navigator.pop(context, _coordenadaSelecionada),
                  label: const Text('Confirmar'),
                  icon: const Icon(Icons.check),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
