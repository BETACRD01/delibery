// lib/screens/user/widgets/rifa_mes_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import '../../../models/raffles/rifa_activa.dart';

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
          child: Center(child: CupertinoActivityIndicator(radius: 14)),
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
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: rifa!.progreso,
                  child: Container(
                    decoration: BoxDecoration(
                      color: rifa!.progreso >= 1.0 ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
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
