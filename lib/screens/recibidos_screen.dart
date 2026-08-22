import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sabor.dart';
import '../session.dart';
import '../services/stock_service.dart';

const String _conceptoNuevo = 'STOCK NUEVO';
const String _conceptoDevolucion = 'DEVOLUCIÓN PRESTADO';

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

class RecibidosScreen extends StatefulWidget {
  const RecibidosScreen({super.key});
  @override
  State<RecibidosScreen> createState() => _RecibidosScreenState();
}

class _RecibidosScreenState extends State<RecibidosScreen> {
  // Persiste las cantidades y el concepto introducidos entre rebuilds del stream
  final Map<String, int> _cantidades = {};
  final Map<String, String> _conceptos = {};
  final Map<String, TextEditingController> _origenCtrls = {};
  String _busqueda = '';

  String _conceptoDe(String nombre) => _conceptos[nombre] ?? _conceptoNuevo;

  TextEditingController _origenCtrl(String nombre) =>
      _origenCtrls.putIfAbsent(nombre, () => TextEditingController());

  @override
  void dispose() {
    for (final c in _origenCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

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

  String _conceptoTexto(_ItemStock item) {
    final concepto = _conceptoDe(item.nombre);
    if (concepto == _conceptoDevolucion) {
      final origen = _origenCtrl(item.nombre).text.trim();
      return origen.isEmpty ? concepto : '$concepto ($origen)';
    }
    return concepto;
  }

  // ── Confirmar recepción ───────────────────────────────────────────────────

  Future<void> _confirmarRecepcion(List<_ItemStock> todos) async {
    final items = todos.where((i) => (_cantidades[i.nombre] ?? 0) > 0).toList();

    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Resumen de recepción'),
        content: SizedBox(
          width: 380,
          child: items.isEmpty
              ? const Text('No hay artículos ni sabores con cantidad mayor a 0.')
              : ConstrainedBox(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(nombre,
                                      style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                Text('+${_cantidades[item.nombre]}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, color: Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(_conceptoTexto(item),
                                style: const TextStyle(fontSize: 11, color: Colors.cyan)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('VOLVER')),
          if (items.isNotEmpty)
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () => Navigator.pop(c, true),
              child: const Text('CONFIRMAR',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final Map<String, dynamic> stockUpdates = {};
    final Map<String, dynamic> saborUpdates = {};
    final List<Map<String, dynamic>> logs = [];

    for (final item in items) {
      final cant = _cantidades[item.nombre]!;
      final conceptoFinal = _conceptoTexto(item);
      if (item.esSabor) {
        saborUpdates['${item.nombre}.cantidad'] = FieldValue.increment(cant);
      } else {
        stockUpdates[item.nombre] = FieldValue.increment(cant);
      }
      logs.add({
        'articulo': item.esSabor ? item.nombre : item.nombre.toUpperCase(),
        'cantidad': cant,
        'fecha': DateTime.now(),
        'motivo': 'RECIBIDO',
        'concepto': conceptoFinal,
        'operador': usuarioActual?['nombre'] ?? '?',
      });
    }

    if (stockUpdates.isNotEmpty) await StockService.articulosRef().update(stockUpdates);
    if (saborUpdates.isNotEmpty) await StockService.saboresRef().update(saborUpdates);
    if (logs.isNotEmpty) await StockService.agregarMovimientos(logs);

    if (mounted) {
      setState(() {
        _cantidades.clear();
        _conceptos.clear();
        for (final c in _origenCtrls.values) {
          c.clear();
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ Entrada confirmada')));
    }
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  Widget _buildHeader(String label) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 16, 2, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                    letterSpacing: 1.5)),
          ],
        ),
      );

  Widget _buildCard(_ItemStock item) {
    final bool activo = (_cantidades[item.nombre] ?? 0) > 0;
    final String concepto = _conceptoDe(item.nombre);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.esSabor ? item.nombre : item.nombre.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (item.subtitulo != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(item.subtitulo!,
                              style: const TextStyle(fontSize: 11, color: Colors.white54)),
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
                      const Text('STOCK', style: TextStyle(fontSize: 9, color: Colors.white38)),
                      Text('${item.stock}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 62,
                  child: TextFormField(
                    key: Key('rec_${item.nombre}'),
                    initialValue: '${_cantidades[item.nombre] ?? 0}',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration:
                        const InputDecoration(isDense: true, border: OutlineInputBorder()),
                    onChanged: (v) => setState(() {
                      _cantidades[item.nombre] = int.tryParse(v) ?? 0;
                    }),
                  ),
                ),
              ],
            ),
            if (activo) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('STOCK NUEVO', style: TextStyle(fontSize: 11)),
                      selected: concepto == _conceptoNuevo,
                      onSelected: (_) =>
                          setState(() => _conceptos[item.nombre] = _conceptoNuevo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('DEVOLUCIÓN', style: TextStyle(fontSize: 11)),
                      selected: concepto == _conceptoDevolucion,
                      onSelected: (_) =>
                          setState(() => _conceptos[item.nombre] = _conceptoDevolucion),
                    ),
                  ),
                ],
              ),
              if (concepto == _conceptoDevolucion) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _origenCtrl(item.nombre),
                  decoration: const InputDecoration(
                    labelText: '¿De dónde viene?',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ],
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
      appBar: AppBar(title: const Text('RECIBIR MATERIAL')),
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
                        onPressed: () => _confirmarRecepcion(todos),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32)),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('CONFIRMAR RECEPCIÓN',
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
