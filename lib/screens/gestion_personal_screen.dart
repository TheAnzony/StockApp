import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_service.dart';

class GestionPersonalScreen extends StatelessWidget {
  const GestionPersonalScreen({super.key});

  void _dialogo(BuildContext context, {DocumentSnapshot? doc}) {
    final n = TextEditingController(text: doc?['nombre'] ?? '');
    final p = TextEditingController(
        text: doc != null ? doc['pin'].toString() : '');
    String r = doc?['rol'] ?? 'trabajador';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, st) => AlertDialog(
          title: Text(doc == null ? 'Nuevo Miembro' : 'Editar'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: n,
                  decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(
                  controller: p,
                  decoration: const InputDecoration(labelText: 'PIN'),
                  keyboardType: TextInputType.number),
              DropdownButton<String>(
                value: r,
                isExpanded: true,
                items: ['trabajador', 'encargado', 'admin']
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (v) => st(() => r = v!),
              ),
            ]),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final data = {
                  'nombre': n.text,
                  'pin': p.text,
                  'rol': r,
                  'activo': doc?['activo'] ?? true,
                };
                doc == null
                    ? StockService.addTrabajador(data)
                    : StockService.updateTrabajador(doc.reference, data);
                Navigator.pop(c);
              },
              child: const Text('GUARDAR'),
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('STAFF'),
          bottom: const TabBar(
              tabs: [Tab(text: "ACTIVOS"), Tab(text: "INACTIVOS")]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _dialogo(context),
          child: const Icon(Icons.person_add),
        ),
        body: dt
            ? Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: sw * 0.6,
                  child: TabBarView(
                      children: [_lista(context, true), _lista(context, false)]),
                ))
            : TabBarView(
                children: [_lista(context, true), _lista(context, false)]),
      ),
    );
  }

  Widget _lista(BuildContext context, bool activo) => StreamBuilder(
        stream: StockService.trabajadoresStream(activo: activo),
        builder: (context, AsyncSnapshot<QuerySnapshot> sn) {
          if (!sn.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final l = sn.data!.docs.toList()
            ..sort((a, b) =>
                a['nombre'].toString().compareTo(b['nombre'].toString()));
          return ListView(
            children: l
                .map((t) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t['rol'] == 'admin'
                            ? Colors.red
                            : (t['rol'] == 'encargado'
                                ? Colors.amber
                                : Colors.green),
                        child: Text(t['nombre'][0]),
                      ),
                      title: Text(t['nombre']),
                      subtitle:
                          Text("${t['rol'].toUpperCase()} | PIN: ${t['pin']}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(activo
                                ? Icons.person_remove
                                : Icons.person_add),
                            onPressed: () => StockService.updateTrabajador(
                                t.reference, {'activo': !activo}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.redAccent),
                            onPressed: () =>
                                StockService.deleteTrabajador(t.reference),
                          ),
                        ],
                      ),
                      onTap: () => _dialogo(context, doc: t),
                    ))
                .toList(),
          );
        },
      );
}
