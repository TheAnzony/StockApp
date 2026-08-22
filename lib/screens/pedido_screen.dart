import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sabor.dart';
import '../services/stock_service.dart';
import '../session.dart';

class _ItemStock {
  final String nombre;
  final bool esSabor;
  final int stock;
  final String? subtitulo;

  _ItemStock({
    required this.nombre,
    required this.esSabor,
    required this.stock,
    this.subtitulo,
  });
}

class PedidoScreen extends StatefulWidget {
  const PedidoScreen({super.key});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  // Persiste las cantidades introducidas entre rebuilds del stream
  final Map<String, int> _cantidades = {};
  String _busqueda = '';

  List<_ItemStock> _construirArticulos(Map<String, dynamic> art) {
    final lista = art.entries
        .map((entry) => _ItemStock(
              nombre: entry.key,
              esSabor: false,
              stock: (entry.value as num?)?.toInt() ?? 0,
            ))
        .toList();
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  List<_ItemStock> _construirSabores(Map<String, dynamic> sab) {
    final lista = sab.entries.map((entry) {
      final s = Sabor.fromEntry(entry.key, entry.value);
      return _ItemStock(
        nombre: s.nombre,
        esSabor: true,
        stock: s.cantidad,
        subtitulo: s.marca.isNotEmpty ? '${s.marca} · ${s.formato}' : null,
      );
    }).toList();
    lista.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return lista;
  }

  Future<void> _confirmarPedido(List<_ItemStock> todos) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) {
        final items = todos.where((i) => (_cantidades[i.nombre] ?? 0) > 0).toList();
        return AlertDialog(
          title: const Text('Resumen del pedido'),
          content: SizedBox(
            width: 360,
            child: items.isEmpty
                ? const Text('No hay artículos con cantidad mayor a 0.')
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${items.length} artículo${items.length == 1 ? '' : 's'} en este pedido:',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                            final nombre =
                                item.esSabor ? item.nombre : item.nombre.toUpperCase();
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(nombre,
                                        style: const TextStyle(fontWeight: FontWeight.w600)),
                                  ),
                                  Text('x${_cantidades[item.nombre]}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange)),
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
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('VOLVER')),
            if (items.isNotEmpty)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
                onPressed: () => Navigator.pop(c, true),
                child: const Text('CONFIRMAR',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    final itemsAGuardar = todos
        .where((i) => (_cantidades[i.nombre] ?? 0) > 0)
        .map((i) => {
              'nombre': i.nombre,
              'esSabor': i.esSabor,
              'cantidad': _cantidades[i.nombre]!,
            })
        .toList();

    if (itemsAGuardar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Añade cantidades antes de confirmar')));
      }
      return;
    }

    await StockService.guardarPedido(
      operador: usuarioActual?['nombre'] ?? '?',
      items: itemsAGuardar,
    );

    if (mounted) {
      setState(() => _cantidades.clear());
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pedido guardado en historial')));
    }
  }

  Widget _buildCard(_ItemStock item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.esSabor ? item.nombre : item.nombre.toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  if (item.subtitulo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item.subtitulo!,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.white54)),
                    ),
                ],
              ),
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
                  const Text('STOCK',
                      style: TextStyle(fontSize: 9, color: Colors.white38)),
                  Text('${item.stock}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              ),
            ),
            SizedBox(
              width: 62,
              child: TextFormField(
                key: Key('ped_${item.nombre}'),
                initialValue: '${_cantidades[item.nombre] ?? 0}',
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                    isDense: true, border: OutlineInputBorder()),
                onChanged: (v) =>
                    _cantidades[item.nombre] = int.tryParse(v) ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.deepOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.deepOrange,
                    letterSpacing: 1.5)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('PEDIDO')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snapArt) {
          return StreamBuilder<DocumentSnapshot>(
            stream: StockService.saboresStream(),
            builder: (context, snapSab) {
              if (!snapArt.hasData || !snapSab.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final articulosCache = snapArt.data!.exists
                  ? snapArt.data!.data() as Map<String, dynamic>
                  : <String, dynamic>{};
              final saboresCache = snapSab.data!.exists
                  ? snapSab.data!.data() as Map<String, dynamic>
                  : <String, dynamic>{};

              final articulos = _construirArticulos(articulosCache);
              final sabores = _construirSabores(saboresCache);
              final todos = [...articulos, ...sabores];

              bool coincide(_ItemStock i) => _busqueda.isEmpty ||
                  i.nombre.toLowerCase().contains(_busqueda.toLowerCase());
              final articulosFiltrados = articulos.where(coincide).toList();
              final saboresFiltrados = sabores.where(coincide).toList();

              Widget listView = ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  if (articulosFiltrados.isNotEmpty) ...[
                    _buildHeader('ARTÍCULOS'),
                    ...articulosFiltrados.map(_buildCard),
                  ],
                  if (saboresFiltrados.isNotEmpty) ...[
                    _buildHeader('SABORES'),
                    ...saboresFiltrados.map(_buildCard),
                  ],
                ],
              );

              final Widget lista = dt
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: sw * 0.6, child: listView))
                  : listView;

              Widget buscador = Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Buscar artículo o sabor...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _busqueda = v),
                ),
              );

              return Column(
                children: [
                  dt
                      ? Align(
                          alignment: Alignment.topCenter,
                          child: SizedBox(width: sw * 0.6, child: buscador))
                      : buscador,
                  Expanded(child: lista),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmarPedido(todos),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('CONFIRMAR PEDIDO',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
