import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class FullMapPage extends StatefulWidget {
  final LatLng coordenadaInicial;
  final bool isReadOnly;

  const FullMapPage({
    super.key,
    required this.coordenadaInicial,
    this.isReadOnly = false,
  });

  @override
  State<FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<FullMapPage> {
  GoogleMapController? _mapController;

  late LatLng _coordenadaSelecionada;

  late LatLng _lastMapPosition;

  @override
  void initState() {
    super.initState();
    _coordenadaSelecionada = widget.coordenadaInicial;
    _lastMapPosition = widget.coordenadaInicial;
  }

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
        title: Text(widget.isReadOnly ? 'Visualizar Localização' : 'Selecionar Localização'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _coordenadaSelecionada,
              zoom: 16,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },

            onCameraMove: widget.isReadOnly ? null : (position) {
              _lastMapPosition = position.target;
            },
            onCameraIdle: widget.isReadOnly ? null : () {
              setState(() {
                _coordenadaSelecionada = _lastMapPosition;
              });
            },
            markers: widget.isReadOnly
                ? {Marker(markerId: const MarkerId('marcador'), position: _coordenadaSelecionada)}
                : {},
            myLocationButtonEnabled: false,
            myLocationEnabled: true,
          ),
          if (!widget.isReadOnly)
            const IgnorePointer(
              child: Icon(Icons.location_pin, color: Colors.red, size: 50),
            ),
          if (!widget.isReadOnly)
            Positioned(
              bottom: 30,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    heroTag: 'myLocation',
                    onPressed: _irParaMinhaLocalizacao,
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 16),
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
