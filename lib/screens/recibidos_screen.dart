import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sabor.dart';
import '../session.dart';
import '../services/stock_service.dart';

class RecibidosScreen extends StatefulWidget {
  const RecibidosScreen({super.key});
  @override
  State<RecibidosScreen> createState() => _RecibidosScreenState();
}

class _RecibidosScreenState extends State<RecibidosScreen> {
  // Cada item: articulo, cantidad, concepto?, origen?, esSabor
  final List<Map<String, dynamic>> _lista = [];

  // ── Selector de artículo ──────────────────────────────────────────────────

  void _abrirSelectorArticulo(List<String> catalogo) {
    String? art;
    final cantCtrl = TextEditingController(text: '1');
    final origenCtrl = TextEditingController();
    String concepto = 'STOCK NUEVO';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Añadir Artículo'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Artículo'),
                items: catalogo
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                    .toList(),
                onChanged: (v) => art = v,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: cantCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cantidad', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: concepto,
                decoration: const InputDecoration(labelText: 'Concepto'),
                items: ['STOCK NUEVO', 'DEVOLUCIÓN PRESTADO']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setSt(() => concepto = v!),
              ),
              if (concepto == 'DEVOLUCIÓN PRESTADO') ...[
                const SizedBox(height: 14),
                TextField(
                  controller: origenCtrl,
                  decoration: const InputDecoration(labelText: '¿De dónde viene?'),
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                if (art != null) {
                  setState(() => _lista.add({
                        'articulo': art,
                        'cantidad': int.tryParse(cantCtrl.text) ?? 1,
                        'concepto': concepto,
                        'origen': concepto == 'DEVOLUCIÓN PRESTADO'
                            ? origenCtrl.text
                            : null,
                        'esSabor': false,
                      }));
                  Navigator.pop(c);
                }
              },
              child: const Text('AÑADIR'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Selector de sabor ─────────────────────────────────────────────────────

  Future<void> _abrirSelectorSabor() async {
    final snap = await StockService.saboresRef().get();
    if (!snap.exists || !mounted) return;

    final data = snap.data() as Map<String, dynamic>;
    final sabores = data.entries
        .map((e) => Sabor.fromEntry(e.key, e.value))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    if (!mounted) return;

    Sabor? sabor;
    final cantCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setSt) => AlertDialog(
          title: const Text('Añadir Sabor'),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<Sabor>(
              decoration: const InputDecoration(labelText: 'Sabor'),
              isExpanded: true,
              // Texto compacto al seleccionar: "Nombre · Marca · Formato"
              selectedItemBuilder: (context) => sabores
                  .map((s) => Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${s.nombre}  ·  ${s.marca}  ·  ${s.formato}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ))
                  .toList(),
              items: sabores
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(s.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            if (s.marca.isNotEmpty)
                              Text('${s.marca}  ·  ${s.formato}',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setSt(() => sabor = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cantCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Cantidad recibida', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 4),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                if (sabor != null) {
                  setState(() => _lista.add({
                        'articulo': sabor!.nombre,
                        'cantidad': int.tryParse(cantCtrl.text) ?? 1,
                        'formato': sabor!.formato,
                        'marca': sabor!.marca,
                        'esSabor': true,
                      }));
                  Navigator.pop(c);
                }
              },
              child: const Text('AÑADIR'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Confirmar recepción ───────────────────────────────────────────────────

  Future<void> _confirmar() async {
    final articulos = _lista.where((p) => p['esSabor'] != true).toList();
    final sabores   = _lista.where((p) => p['esSabor'] == true).toList();

    // Artículos: actualizar stock + log
    if (articulos.isNotEmpty) {
      final Map<String, dynamic> updates = {};
      final List<Map<String, dynamic>> logs = [];
      for (final p in articulos) {
        final String art = p['articulo'];
        final int cant = p['cantidad'];
        updates[art] = FieldValue.increment(cant);
        String conceptoFinal = p['concepto'];
        if (p['origen'] != null && p['origen'].toString().isNotEmpty) {
          conceptoFinal += ' (${p['origen']})';
        }
        logs.add({
          'articulo': art.toUpperCase(),
          'cantidad': cant,
          'fecha': DateTime.now(),
          'motivo': 'RECIBIDO',
          'concepto': conceptoFinal,
          'operador': usuarioActual?['nombre'] ?? '?',
        });
      }
      await StockService.articulosRef().update(updates);
      await StockService.agregarMovimientos(logs);
    }

    // Sabores: incrementar .cantidad con dot notation
    if (sabores.isNotEmpty) {
      final Map<String, dynamic> saborUpdates = {};
      for (final p in sabores) {
        saborUpdates['${p['articulo']}.cantidad'] =
            FieldValue.increment(p['cantidad'] as int);
      }
      await StockService.saboresRef().update(saborUpdates);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('✅ Entrada confirmada')));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('RECIBIR MATERIAL')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final catalogo =
              (snap.data!.data() as Map).keys.whereType<String>().toList()..sort();

          Widget bodyContent = Column(children: [
            Expanded(
              child: _lista.isEmpty
                  ? const Center(child: Text('Lista vacía'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(10),
                      itemCount: _lista.length,
                      itemBuilder: (context, index) {
                        final p = _lista[index];
                        final esSabor = p['esSabor'] == true;
                        final titulo = esSabor
                            ? '${p['articulo']}  (x${p['cantidad']})'
                            : '${p['articulo'].toString().toUpperCase()}  (x${p['cantidad']})';
                        final subtitulo = esSabor
                            ? '${p['marca'] ?? ''}  ·  ${p['formato'] ?? ''}'
                            : '${p['concepto']}${p['origen'] != null ? '  [${p['origen']}]' : ''}';
                        final color = esSabor
                            ? Colors.indigo
                            : (p['origen'] != null ? Colors.cyan : Colors.green);

                        return Card(
                          child: ListTile(
                            leading: Icon(
                              esSabor
                                  ? Icons.local_fire_department
                                  : Icons.inventory_2,
                              color: color,
                            ),
                            title: Text(titulo,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(subtitulo,
                                style: TextStyle(color: color, fontSize: 12)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () =>
                                  setState(() => _lista.removeAt(index)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Column(children: [
                Row(children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: const Color(0xFF1976D2)),
                      onPressed: () => _abrirSelectorArticulo(catalogo),
                      icon: const Icon(Icons.inventory_2, size: 18),
                      label: const Text('ARTÍCULO',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          backgroundColor: Colors.indigo),
                      onPressed: _abrirSelectorSabor,
                      icon: const Icon(Icons.local_fire_department, size: 18),
                      label: const Text('SABOR',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: _lista.isEmpty ? null : _confirmar,
                  child: const Text('CONFIRMAR RECEPCIÓN',
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
