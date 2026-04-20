import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';

class InventarioScreen extends StatefulWidget {
  final bool modoEdicion;
  const InventarioScreen({super.key, required this.modoEdicion});
  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  Map<String, int> temp = {};

  void _confirmarGuardar(
      DocumentReference ref, Map<String, dynamic> currentDB) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("¿Confirmar Stock?"),
        content: const Text("Se registrarán los ajustes. ¿Estás seguro?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00ACC1)),
            onPressed: () {
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

  void _save(
      DocumentReference ref, Map<String, dynamic> currentStockDB) async {
    List<Map<String, dynamic>> logs = [];
    Map<String, int> stockFinal = {};
    Map<String, int> descuadres = {};

    temp.forEach((k, vContado) {
      final bool esNuevo = !currentStockDB.containsKey(k);
      final int vAnterior =
          esNuevo ? 0 : (currentStockDB[k] as num).toInt();
      final int diferencia = vContado - vAnterior;

      if (esNuevo) {
        logs.add({
          'articulo': k.toUpperCase(),
          'cantidad': vContado,
          'fecha': DateTime.now(),
          'motivo': 'ALTA',
          'operador': usuarioActual?['nombre'],
        });
      } else if (diferencia != 0) {
        logs.add({
          'articulo': k.toUpperCase(),
          'cantidad': diferencia,
          'fecha': DateTime.now(),
          'motivo': 'GENERAL',
          'operador': usuarioActual?['nombre'],
        });
        descuadres[k] = diferencia;
      }
      stockFinal[k] = vContado;
    });

    await StockService.guardarStock(
      stockFinal: stockFinal,
      descuadres: descuadres,
      movimientos: logs,
    );
    await ref.update(temp);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("✅ Stock actualizado")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return StreamBuilder(
      stream: StockService.articulosStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final doc = snap.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final List<String> keys = data.keys.toList()..sort();
        if (widget.modoEdicion && temp.isEmpty) {
          data.forEach((k, v) => temp[k] = (v as num).toInt());
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
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: widget.modoEdicion
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.cyan),
                                onPressed: () => setState(() {
                                      if ((temp[k] ?? 0) > 0) {
                                        temp[k] = temp[k]! - 1;
                                      }
                                    })),
                            SizedBox(
                              width: 50,
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
                                    isDense: true,
                                    border: InputBorder.none),
                                onChanged: (v) =>
                                    temp[k] = int.tryParse(v) ?? 0,
                              ),
                            ),
                            IconButton(
                                icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.cyan),
                                onPressed: () => setState(
                                    () => temp[k] = (temp[k] ?? 0) + 1)),
                          ],
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
                    onPressed: () =>
                        _confirmarGuardar(doc.reference, data),
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
        ]);

        return Scaffold(
          appBar: AppBar(
              title: Text(
                  widget.modoEdicion ? 'REALIZAR STOCK' : 'VER STOCK')),
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
