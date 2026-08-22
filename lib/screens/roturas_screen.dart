import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';
import '../constants/constants.dart';

class RoturasScreen extends StatefulWidget {
  const RoturasScreen({super.key});
  @override
  State<RoturasScreen> createState() => _RoturasScreenState();
}

class _RoturasScreenState extends State<RoturasScreen> {
  final Map<String, bool> seleccionados = {};
  final Map<String, int> cantidades = {};

  Future<void> _confirmar() async {
    final ref = StockService.articulosRef();
    final Map<String, dynamic> updates = {};
    final List<Map<String, dynamic>> logs = [];

    seleccionados.forEach((k, v) {
      if (v) {
        final int c = cantidades[k] ?? 0;
        updates[k] = FieldValue.increment(-c);
        if (k.toLowerCase() == ArticuloConstants.cachimbas) {
          updates[ArticuloConstants.mastil] = FieldValue.increment(c);
        }
        logs.add({
          'articulo': k.toUpperCase(),
          'cantidad': -c,
          'fecha': DateTime.now(),
          'motivo': 'ROTURAS',
          'operador': usuarioActual?['nombre'],
        });
      }
    });

    if (updates.isEmpty) return;

    await ref.update(updates);
    await StockService.agregarMovimientos(logs);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Roturas registradas")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text("REGISTRO DE ROTURAS")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data!.exists
              ? snap.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};
          final items = data.keys.toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

          for (final i in items) {
            seleccionados.putIfAbsent(i, () => false);
            cantidades.putIfAbsent(i, () => 1);
          }

          Widget bodyContent = Column(children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final String item = items[index];
                  final bool isSel = seleccionados[item] ?? false;
                  final int stock = (data[item] as num?)?.toInt() ?? 0;
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    color: isSel ? Colors.red.withValues(alpha: 0.1) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                          color: isSel ? Colors.red : Colors.transparent),
                    ),
                    child: InkWell(
                      onTap: isSel
                          ? null
                          : () => setState(() {
                                seleccionados[item] = true;
                                cantidades[item] = 1;
                              }),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          Checkbox(
                            activeColor: Colors.red,
                            value: isSel,
                            onChanged: (v) =>
                                setState(() => seleccionados[item] = v!),
                          ),
                          Expanded(
                            child: Text(item.toUpperCase(),
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? Colors.white : Colors.grey)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('STOCK',
                                    style: TextStyle(fontSize: 8, color: Colors.white38)),
                                Text('$stock',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          if (isSel) ...[
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              onPressed: () => setState(() {
                                if ((cantidades[item] ?? 1) > 1) {
                                  cantidades[item] = cantidades[item]! - 1;
                                } else {
                                  seleccionados[item] = false;
                                }
                              }),
                            ),
                            Text("${cantidades[item]}",
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: Colors.green),
                              onPressed: () => setState(
                                  () => cantidades[item] = (cantidades[item] ?? 0) + 1),
                            ),
                          ],
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        side: const BorderSide(color: Colors.grey)),
                    child: const Text("CANCELAR",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirmar,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        minimumSize: const Size(0, 50)),
                    child: const Text("CONFIRMAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ]),
            ),
          ]);

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
