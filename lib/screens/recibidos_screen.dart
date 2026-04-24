import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';

class RecibidosScreen extends StatefulWidget {
  const RecibidosScreen({super.key});
  @override
  State<RecibidosScreen> createState() => _RecibidosScreenState();
}

class _RecibidosScreenState extends State<RecibidosScreen> {
  List<Map<String, dynamic>> productosAnadidos = [];

  void _abrirSelector(List<String> catalogo) {
    String? temporalArt;
    final cantController = TextEditingController(text: "1");
    final origenController = TextEditingController();
    String temporalConcepto = "STOCK NUEVO";

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text("Añadir Producto"),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Artículo"),
                items: catalogo
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (v) => temporalArt = v,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: cantController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: "Cantidad", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: temporalConcepto,
                decoration: const InputDecoration(labelText: "Concepto"),
                items: ["STOCK NUEVO", "DEVOLUCIÓN PRESTADO"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setSt(() => temporalConcepto = v!),
              ),
              if (temporalConcepto == "DEVOLUCIÓN PRESTADO") ...[
                const SizedBox(height: 15),
                TextField(
                  controller: origenController,
                  decoration:
                      const InputDecoration(labelText: "¿De dónde viene?"),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text("CANCELAR")),
            ElevatedButton(
              onPressed: () {
                if (temporalArt != null) {
                  setState(() {
                    productosAnadidos.add({
                      'articulo': temporalArt,
                      'cantidad': int.tryParse(cantController.text) ?? 1,
                      'concepto': temporalConcepto,
                      'origen': temporalConcepto == "DEVOLUCIÓN PRESTADO"
                          ? origenController.text
                          : null,
                    });
                  });
                  Navigator.pop(c);
                }
              },
              child: const Text("AÑADIR"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text("RECIBIR MATERIAL")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final catalogo =
              (snap.data!.data() as Map).keys.whereType<String>().toList()
                ..sort();

          Widget bodyContent = Column(children: [
            Expanded(
              child: productosAnadidos.isEmpty
                  ? const Center(child: Text("Lista vacía"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: productosAnadidos.length,
                      itemBuilder: (context, index) {
                        final p = productosAnadidos[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                                "${p['articulo'].toString().toUpperCase()} (x${p['cantidad']})"),
                            subtitle: Text(
                              p['concepto'] +
                                  (p['origen'] != null
                                      ? " [${p['origen']}]"
                                      : ""),
                              style: TextStyle(
                                  color: p['origen'] != null
                                      ? Colors.cyan
                                      : Colors.green),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.redAccent),
                              onPressed: () => setState(
                                  () => productosAnadidos.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),
              child: Column(children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF1976D2)),
                  onPressed: () => _abrirSelector(catalogo),
                  icon: const Icon(Icons.add),
                  label: const Text("AÑADIR PRODUCTO",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: productosAnadidos.isEmpty
                      ? null
                      : () async {
                          final ref = StockService.articulosRef();
                          final Map<String, dynamic> updates = {};
                          final List<Map<String, dynamic>> logs = [];

                          for (var p in productosAnadidos) {
                            final String art = p['articulo'];
                            final int cant = p['cantidad'];
                            updates[art] = FieldValue.increment(cant);
                            String conceptoFinal = p['concepto'];
                            if (p['origen'] != null &&
                                p['origen'].toString().isNotEmpty) {
                              conceptoFinal += " (${p['origen']})";
                            }
                            logs.add({
                              'articulo': art.toUpperCase(),
                              'cantidad': cant,
                              'fecha': DateTime.now(),
                              'motivo': 'RECIBIDO',
                              'concepto': conceptoFinal,
                              'operador': usuarioActual?['nombre'] ?? 'Admin',
                            });
                          }

                          await ref.update(updates);
                          await StockService.agregarMovimientos(logs);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("✅ Entrada confirmada")));
                          }
                        },
                  child: const Text("CONFIRMAR RECEPCIÓN",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
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
