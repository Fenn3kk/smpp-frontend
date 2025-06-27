import 'package:flutter/material.dart';

class InfoRowWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool fade; // Para controlar o efeito de fade no texto longo

  const InfoRowWidget({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.fade = false,
  });

  @override
  Widget build(BuildContext context) {
    // A lógica que antes era uma função de ajuda, agora é o método build
    // deste widget independente.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value ?? 'Não informado'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}