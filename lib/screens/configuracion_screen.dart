import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/stock_service.dart';

class ConfiguracionSistemaScreen extends StatefulWidget {
  const ConfiguracionSistemaScreen({super.key});

  @override
  State<ConfiguracionSistemaScreen> createState() => _ConfiguracionSistemaScreenState();
}

class _ConfiguracionSistemaScreenState extends State<ConfiguracionSistemaScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() => _version = 'v${info.version}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

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

          Widget bodyContent = Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      child: SwitchListTile(
                        title: const Text("ABRIR STOCK MANUALMENTE",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle:
                            const Text("Permite realizar stock fuera del domingo."),
                        activeThumbColor: Colors.cyan,
                        value: stockForzado,
                        onChanged: (val) => StockService.setStockForzado(val),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _version,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          );

          return dt
              ? Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: sw * 0.6, child: bodyContent))
              : bodyContent;
        },
      ),
    );
  }
}
