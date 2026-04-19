import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_service.dart';

class ConfiguracionSistemaScreen extends StatelessWidget {
  const ConfiguracionSistemaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CONFIGURACIÓN SISTEMA")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.configuracionStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          bool stockForzado =
              snap.data!.exists ? (snap.data!['stock_forzado'] ?? false) : false;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: SwitchListTile(
                  title: const Text("ABRIR STOCK MANUALMENTE",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle:
                      const Text("Permite realizar stock fuera del domingo."),
                  activeColor: Colors.cyan,
                  value: stockForzado,
                  onChanged: (val) => StockService.setStockForzado(val),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
