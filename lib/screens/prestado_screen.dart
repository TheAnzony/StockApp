import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';
import '../constants/constants.dart';

class PrestadoScreen extends StatefulWidget {
  const PrestadoScreen({super.key});
  @override
  State<PrestadoScreen> createState() => _PrestadoScreenState();
}

class _PrestadoScreenState extends State<PrestadoScreen> {
  Map<String, bool> seleccionados = {};
  Map<String, int> cantidades = {};
  final TextEditingController _dest = TextEditingController();

  Future<void> _confirmar() async {
    final ref = StockService.articulosRef();
    final Map<String, dynamic> updates = {};
    final List<Map<String, dynamic>> logs = [];

    seleccionados.forEach((k, v) {
      if (v) {
        final int cant = cantidades[k] ?? 0;
        final int val = -cant;
        updates[k] = FieldValue.increment(val);
        if (k.toLowerCase() == ArticuloConstants.cachimbas) {
          updates[ArticuloConstants.mangueras] = FieldValue.increment(val);
          logs.add({
            'articulo': 'MANGUERAS (AUTO)',
            'cantidad': val,
            'fecha': DateTime.now(),
            'motivo': 'PRESTADO',
            'operador': usuarioActual?['nombre'],
            'destino': _dest.text,
          });
        }
        logs.add({
          'articulo': k.toUpperCase(),
          'cantidad': val,
          'fecha': DateTime.now(),
          'motivo': 'PRESTADO',
          'operador': usuarioActual?['nombre'],
          'destino': _dest.text,
        });
      }
    });

    await ref.update(updates);
    await StockService.agregarMovimientos(logs);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ PRESTADO registrado")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('PRESTADO')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List<String> items = data.keys
              .where((k) =>
                  k.toLowerCase() != ArticuloConstants.mangueras &&
                  data[k] is num)
              .toList()
            ..sort();

          Widget bodyContent = Column(children: [
            Padding(
              padding: const EdgeInsets.all(15),
              child: TextField(
                controller: _dest,
                decoration: const InputDecoration(
                    labelText: "DESTINO", border: OutlineInputBorder()),
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final String item = items[index];
                  final bool isSel = seleccionados[item] ?? false;
                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 5),
                    color:
                        isSel ? Colors.blue.withValues(alpha: 0.1) : null,
                    child: ListTile(
                      onTap: isSel
                          ? null
                          : () => setState(() {
                                seleccionados[item] = true;
                                cantidades[item] = 1;
                              }),
                      leading: Checkbox(
                        value: isSel,
                        onChanged: (v) => setState(() {
                          seleccionados[item] = v!;
                          if (v) cantidades[item] = 1;
                        }),
                      ),
                      title: Text(item.toUpperCase(),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),
                      trailing: isSel
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.remove_circle_outline),
                                  onPressed: () => setState(() {
                                    if ((cantidades[item] ?? 1) > 1) {
                                      cantidades[item] =
                                          cantidades[item]! - 1;
                                    } else {
                                      seleccionados[item] = false;
                                    }
                                  }),
                                ),
                                Text("${cantidades[item] ?? 1}",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green),
                                  onPressed: () => setState(() =>
                                      cantidades[item] =
                                          (cantidades[item] ?? 0) + 1),
                                ),
                              ],
                            )
                          : null,
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
                    child: const Text("CANCELAR"),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: _confirmar,
                    child: const Text("CONFIRMAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
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
