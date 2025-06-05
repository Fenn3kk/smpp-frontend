import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class FullMapPage extends StatefulWidget {
  final LatLng coordenadaInicial;

  const FullMapPage({super.key, required this.coordenadaInicial});

  @override
  State<FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<FullMapPage> {
  LatLng? _coordenadaSelecionada;

  @override
  void initState() {
    super.initState();
    _coordenadaSelecionada = widget.coordenadaInicial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Localização')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _coordenadaSelecionada!,
              zoom: 16,
            ),
            onTap: (latLng) {
              setState(() => _coordenadaSelecionada = latLng);
            },
            markers: {
              Marker(
                markerId: const MarkerId('marcador'),
                position: _coordenadaSelecionada!,
              ),
            },
            onCameraMove: (pos) => _coordenadaSelecionada = pos.target,
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30, right: 70),
              child: FloatingActionButton(
                onPressed: () => Navigator.pop(context, _coordenadaSelecionada),
                child: const Icon(Icons.check),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
