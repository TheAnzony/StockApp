import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_service.dart';

class GestionCatalogoScreen extends StatefulWidget {
  const GestionCatalogoScreen({super.key});
  @override
  State<GestionCatalogoScreen> createState() => _GestionCatalogoScreenState();
}

class _GestionCatalogoScreenState extends State<GestionCatalogoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _dialogoAnadir({required bool esSabor}) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(esSabor ? 'Nuevo Sabor' : 'Nuevo Producto'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Nombre'),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.isNotEmpty) {
                if (esSabor) {
                  await StockService.addSabor(ctrl.text);
                } else {
                  await StockService.addArticulo(ctrl.text);
                }
                if (c.mounted) Navigator.pop(c);
              }
            },
            child: const Text('AÑADIR'),
          ),
        ],
      ),
    );
  }

  void _dialogoEliminar(
      BuildContext context, String nombre, bool esSabor, DocumentReference ref) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Eliminar"),
        content: Text("¿Borrar ${nombre.toUpperCase()}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text("NO")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (esSabor) {
                StockService.deleteSabor(nombre);
              } else {
                StockService.deleteArticulo(ref, nombre);
              }
              Navigator.pop(c);
            },
            child: const Text("SÍ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLista({
    required Stream<DocumentSnapshot> stream,
    required bool esSabor,
    required Color color,
    required double sw,
    required bool dt,
  }) {
    return StreamBuilder<DocumentSnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        final keys = data.keys.toList()..sort();

        Widget content = ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final String k = keys[index];
            return Card(
              child: ListTile(
                leading: Icon(
                  esSabor ? Icons.local_fire_department : Icons.label_outline,
                  color: color,
                ),
                title: Text(esSabor ? k : k.toUpperCase()),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: () =>
                      _dialogoEliminar(context, k, esSabor, snap.data!.reference),
                ),
              ),
            );
          },
        );

        return dt
            ? Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: sw * 0.6, child: content))
            : content;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;
    final bool esSabor = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CATÁLOGO'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'STOCK'),
            Tab(text: 'SABORES'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _dialogoAnadir(esSabor: esSabor),
        label: Text(esSabor ? 'AÑADIR SABOR' : 'AÑADIR PRODUCTO'),
        icon: const Icon(Icons.add),
        backgroundColor: esSabor ? Colors.indigo : Colors.amber,
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLista(
            stream: StockService.articulosStream(),
            esSabor: false,
            color: Colors.amber,
            sw: sw,
            dt: dt,
          ),
          _buildLista(
            stream: StockService.saboresStream(),
            esSabor: true,
            color: Colors.indigo,
            sw: sw,
            dt: dt,
          ),
        ],
      ),
    );
  }
}
