import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';

class _ItemStock {
  final String nombre;
  final int stock;
  _ItemStock({required this.nombre, required this.stock});
}

class PrestadoScreen extends StatefulWidget {
  const PrestadoScreen({super.key});
  @override
  State<PrestadoScreen> createState() => _PrestadoScreenState();
}

class _PrestadoScreenState extends State<PrestadoScreen> {
  final Map<String, int> _cantidades = {};
  final TextEditingController _dest = TextEditingController();
  String _busqueda = '';

  @override
  void dispose() {
    _dest.dispose();
    super.dispose();
  }

  List<_ItemStock> _construirItems(Map<String, dynamic> art) {
    final lista = art.entries
        .where((e) => e.value is num)
        .map((e) => _ItemStock(nombre: e.key, stock: (e.value as num).toInt()))
        .toList();
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  Future<void> _confirmar(List<_ItemStock> todos) async {
    final items = todos.where((i) => (_cantidades[i.nombre] ?? 0) > 0).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Resumen de préstamo'),
        content: SizedBox(
          width: 380,
          child: items.isEmpty
              ? const Text('No hay artículos con cantidad mayor a 0.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        _dest.text.trim().isEmpty
                            ? 'Destino: (sin especificar)'
                            : 'Destino: ${_dest.text.trim()}',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.5),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: Colors.white12),
                        itemBuilder: (context, i) {
                          final item = items[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(item.nombre.toUpperCase(),
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                Text('-${_cantidades[item.nombre]}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, color: Colors.orange)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('VOLVER')),
          if (items.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('CONFIRMAR',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final Map<String, dynamic> updates = {};
    final List<Map<String, dynamic>> logs = [];

    for (final item in items) {
      final int cant = _cantidades[item.nombre]!.clamp(0, item.stock);
      if (cant == 0) continue;
      final int val = -cant;
      updates[item.nombre] = FieldValue.increment(val);
      logs.add({
        'articulo': item.nombre.toUpperCase(),
        'cantidad': val,
        'fecha': DateTime.now(),
        'motivo': 'PRESTADO',
        'operador': usuarioActual?['nombre'],
        'destino': _dest.text,
      });
    }

    if (updates.isNotEmpty) {
      await StockService.articulosRef().update(updates);
      await StockService.agregarMovimientos(logs);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ PRESTADO registrado")));
    }
  }

  Widget _buildCard(_ItemStock item) {
    final int cant = _cantidades[item.nombre] ?? 0;
    final bool sinStock = item.stock <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(item.nombre.toUpperCase(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: sinStock ? Colors.white24 : null)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('STOCK', style: TextStyle(fontSize: 9, color: Colors.white38)),
                  Text('${item.stock}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            SizedBox(
              width: 62,
              child: TextFormField(
                key: Key('pre_${item.nombre}'),
                enabled: !sinStock,
                initialValue: '$cant',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                onChanged: (v) => setState(() {
                  final n = int.tryParse(v) ?? 0;
                  _cantidades[item.nombre] = n.clamp(0, item.stock);
                }),
              ),
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
      appBar: AppBar(title: const Text('PRESTADO')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.exists
              ? snapshot.data!.data() as Map<String, dynamic>
              : <String, dynamic>{};
          final todos = _construirItems(data);
          final filtrados = _busqueda.isEmpty
              ? todos
              : todos
                  .where((i) => i.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
                  .toList();

          Widget destino = Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              controller: _dest,
              decoration: const InputDecoration(
                  labelText: "DESTINO", isDense: true, border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
            ),
          );

          Widget buscador = Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar artículo...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          );

          Widget listView = ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: filtrados.length,
            itemBuilder: (context, i) => _buildCard(filtrados[i]),
          );

          final Widget lista = dt
              ? Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: sw * 0.6, child: listView))
              : listView;

          Widget bodyContent = Column(children: [
            dt
                ? Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: sw * 0.6, child: destino))
                : destino,
            dt
                ? Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: sw * 0.6, child: buscador))
                : buscador,
            Expanded(child: lista),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => _confirmar(todos),
                  child: const Text("CONFIRMAR",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ]);

          return bodyContent;
        },
      ),
    );
  }
}
