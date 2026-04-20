import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_service.dart';

class GestionCatalogoScreen extends StatelessWidget {
  const GestionCatalogoScreen({super.key});

  void _dialogo(BuildContext context) {
    final artCont = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Nuevo Producto'),
        content: TextField(
          controller: artCont,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (artCont.text.isNotEmpty) {
                await StockService.addArticulo(artCont.text);
                if (c.mounted) Navigator.pop(c);
              }
            },
            child: const Text('AÑADIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('CATÁLOGO')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogo(context),
        label: const Text('AÑADIR'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.amber,
      ),
      body: StreamBuilder(
        stream: StockService.articulosStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snap.data!.docs.first;
          final data = doc.data() as Map<String, dynamic>;
          final List<String> keys = data.keys.toList()..sort();

          Widget bodyContent = ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final String k = keys[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.label_outline,
                      color: Colors.amber),
                  title: Text(k.toUpperCase()),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_sweep,
                        color: Colors.redAccent),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text("Eliminar"),
                        content: Text("¿Borrar $k?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(c),
                              child: const Text("NO")),
                          ElevatedButton(
                            onPressed: () {
                              StockService.deleteArticulo(
                                  doc.reference, k);
                              Navigator.pop(c);
                            },
                            child: const Text("SÍ"),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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
