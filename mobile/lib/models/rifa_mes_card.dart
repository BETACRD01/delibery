// lib/screens/user/widgets/rifa_mes_card.dart

import 'package:flutter/material.dart';

import '../../../models/rifa_activa.dart';

class RifaMesCard extends StatelessWidget {
  final RifaActiva? rifa;
  final bool cargando;
  final VoidCallback? onVerPremios;

  const RifaMesCard({super.key, this.rifa, this.cargando = false, this.onVerPremios});

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (rifa == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.card_giftcard, color: Colors.grey),
          title: Text('Rifa del Mes'),
          subtitle: Text('No hay ninguna rifa activa en este momento.'),
        ),
      );
    }

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onVerPremios,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(rifa!.titulo, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '¡Completa ${rifa!.pedidosMinimos} pedidos este mes y participa para ganar increíbles premios!',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 16),
              // --- BARRA DE PROGRESO ---
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: rifa!.progreso,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(rifa!.progreso >= 1.0 ? Colors.green : Colors.blue),
                ),
              ),
              const SizedBox(height: 8),
              // --- TEXTO DE PROGRESO ---
              Center(
                child: Text(
                  rifa!.progreso >= 1.0
                      ? '¡Ya estás participando!'
                      : 'Llevas ${rifa!.misPedidos} de ${rifa!.pedidosMinimos} pedidos',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: rifa!.progreso >= 1.0 ? Colors.green[700] : Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: onVerPremios,
                  child: const Text('Ver Premios y Detalles', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
