import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';
import '../session.dart';
import '../services/stock_service.dart';
import '../services/session_service.dart';

class InventarioScreen extends StatefulWidget {
  final bool modoEdicion;
  const InventarioScreen({super.key, required this.modoEdicion});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  Map<String, int> temp = {};
  bool _modoReajuste = false;
  Map<String, int> _tempReajuste = {};
  @override
  void initState() {
    super.initState();
    if (widget.modoEdicion) _cargarTemp();
  }

  Future<void> _cargarTemp() async {
    final saved = await SessionService.loadStockTemp();
    if (saved != null && mounted) {
      setState(() => temp = saved);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('♻️ Conteo anterior recuperado'),
          duration: Duration(seconds: 3),
        ));
      });
    }
  }

  Future<void> _guardarReajuste(
      DocumentReference ref, Map<String, dynamic> currentData) async {
    final Map<String, dynamic> updates = {};
    _tempReajuste.forEach((k, v) {
      if (currentData[k] is num && v != (currentData[k] as num).toInt()) {
        updates[k] = v;
      }
    });
    if (updates.isNotEmpty) await ref.update(updates);
    if (mounted) {
      setState(() {
        _modoReajuste = false;
        _tempReajuste.clear();
      });
      if (updates.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ Reajuste guardado')));
      }
    }
  }

  void _confirmarGuardar(DocumentReference ref, Map<String, dynamic> currentDB) {
    final List<MapEntry<String, int>> cambios = [];
    temp.forEach((k, vContado) {
      if (currentDB[k] is! num) return;
      final int vAnterior = (currentDB[k] as num).toInt();
      if (vContado != vAnterior) cambios.add(MapEntry(k, vContado));
    });

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Confirmar Stock"),
        content: cambios.isEmpty
            ? const Text("No hay cambios que guardar.")
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Cambios detectados:",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...cambios.map((e) {
                      final int vAnterior = (currentDB[e.key] as num).toInt();
                      final int diff = e.value - vAnterior;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(children: [
                          Expanded(
                            child: Text(e.key.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            "$vAnterior → ${e.value}  (${diff > 0 ? '+' : ''}$diff)",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: diff < 0 ? Colors.redAccent : Colors.green,
                            ),
                          ),
                        ]),
                      );
                    }),
                  ],
                ),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1)),
            onPressed: cambios.isEmpty
                ? null
                : () {
                    Navigator.pop(c);
                    _save(ref, currentDB);
                  },
            child: const Text("SÍ, CONFIRMAR",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _save(
      DocumentReference ref, Map<String, dynamic> currentStockDB) async {
    final Map<String, int> stockFinal = {};
    final Map<String, dynamic> updates = {};

    temp.forEach((k, vContado) {
      if (currentStockDB[k] is! num) return;
      stockFinal[k] = vContado;
      final int vAnterior = (currentStockDB[k] as num).toInt();
      if (vContado != vAnterior) updates[k] = vContado;
    });

    // Buscar el stock_final del último stock realizado para usarlo como base
    final ultimoDoc = await StockService.getUltimoStock();
    final Map<String, int> stockAnterior = {};
    if (ultimoDoc != null) {
      final data = ultimoDoc.data() as Map<String, dynamic>? ?? {};
      final sf = data[FirebaseFields.stockFinal] as Map<String, dynamic>? ?? {};
      sf.forEach((k, v) => stockAnterior[k] = (v as num).toInt());
    }

    await StockService.guardarStock(
      stockAnterior: stockAnterior,
      stockFinal: stockFinal,
      stockAnteriorId: ultimoDoc?.id,
    );
    if (updates.isNotEmpty) await ref.update(updates);

    if (mounted) {
      await SessionService.clearStockTemp();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Stock actualizado")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = (usuarioActual?['rol'] ?? '') == 'admin';
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return StreamBuilder(
      stream: StockService.articulosStream(),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final doc = snap.data!;
        final data = doc.data() as Map<String, dynamic>;
        final List<String> keys = data.keys.toList()..sort();
        if (widget.modoEdicion) {
          data.forEach((k, v) {
            if (v is num && !temp.containsKey(k)) temp[k] = 0;
          });
        }

        Widget bodyContent = Column(children: [
          Expanded(
            child: ListView(
              children: keys.map((k) {
                if (data[k] is! num) return const SizedBox.shrink();
                final int val = widget.modoEdicion
                    ? (temp[k] ?? 0)
                    : (data[k] as num).toInt();
                return ListTile(
                  title: Text(k.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: widget.modoEdicion
                      ? SizedBox(
                          width: 70,
                          child: TextFormField(
                            key: Key('in_$k'),
                            initialValue: '$val',
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan),
                            decoration: const InputDecoration(
                                isDense: true, border: OutlineInputBorder()),
                            onChanged: (v) {
                              temp[k] = int.tryParse(v) ?? 0;
                              SessionService.saveStockTemp(temp);
                            },
                          ),
                        )
                      : _modoReajuste
                          ? SizedBox(
                              width: 70,
                              child: TextFormField(
                                key: Key('rj_$k'),
                                initialValue:
                                    '${_tempReajuste[k] ?? (data[k] as num).toInt()}',
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                                decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                onChanged: (v) =>
                                    _tempReajuste[k] = int.tryParse(v) ?? 0,
                              ),
                            )
                          : Text('$val',
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent)),
                );
              }).toList(),
            ),
          ),
          if (widget.modoEdicion)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  border: Border(top: BorderSide(color: Colors.white10))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      SessionService.clearStockTemp();
                      Navigator.pop(context);
                    },
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
                    onPressed: () => _confirmarGuardar(doc.reference, data),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00838F),
                        minimumSize: const Size(0, 50)),
                    child: const Text("CONFIRMAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white)),
                  ),
                ),
              ]),
            ),
          if (_modoReajuste)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  border: Border(top: BorderSide(color: Colors.white10))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _modoReajuste = false;
                      _tempReajuste.clear();
                    }),
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
                    onPressed: () => _guardarReajuste(doc.reference, data),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(0, 50)),
                    child: const Text("GUARDAR",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white)),
                  ),
                ),
              ]),
            ),
        ]);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.modoEdicion
                ? 'REALIZAR STOCK'
                : _modoReajuste
                    ? 'REAJUSTE DE STOCK'
                    : 'VER STOCK'),
            actions: [
              if (!widget.modoEdicion && isAdmin && !_modoReajuste)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Reajuste',
                  onPressed: () {
                    final init = <String, int>{};
                    data.forEach((k, v) {
                      if (v is num) init[k] = v.toInt();
                    });
                    setState(() {
                      _modoReajuste = true;
                      _tempReajuste = init;
                    });
                  },
                ),
            ],
          ),
          body: dt
              ? Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: sw * 0.6, child: bodyContent))
              : bodyContent,
        );
      },
    );
  }
}
