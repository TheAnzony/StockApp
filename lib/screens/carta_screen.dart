import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/carta_constants.dart';
import '../services/stock_service.dart';
import '../session.dart';

class CartaScreen extends StatefulWidget {
  const CartaScreen({super.key});
  @override
  State<CartaScreen> createState() => _CartaScreenState();
}

class _CartaScreenState extends State<CartaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _modoReajusteSabores = false;
  final Map<String, int> _tempReajusteSabores = {};

  static const List<Color> _colores = [
    Color(0xFF4FC3F7),
    Color(0xFF81C784),
    Color(0xFFFFB74D),
    Color(0xFFBA68C8),
    Color(0xFFFF8A65),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  Future<void> _guardarReajusteSabores(Map<String, dynamic> currentData) async {
    final Map<String, dynamic> updates = {};
    _tempReajusteSabores.forEach((k, v) {
      final current = (currentData[k] as num?)?.toInt() ?? 0;
      if (v != current) updates[k] = v;
    });
    if (updates.isNotEmpty) await StockService.saboresRef().update(updates);
    if (mounted) {
      setState(() {
        _modoReajusteSabores = false;
        _tempReajusteSabores.clear();
      });
      if (updates.isNotEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('✅ Reajuste guardado')));
      }
    }
  }

  Future<void> _init() async {
    final sabores = {for (var s in CartaConstants.saboresUnicos) s: 0};
    await StockService.initSaboresIfNeeded(sabores); // usa articulos/sabores
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = (usuarioActual?['rol'] ?? '') == 'admin';
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CARTA'),
        actions: [
          if (isAdmin)
            AnimatedBuilder(
              animation: _tabController,
              builder: (_, child) {
                if (_tabController.index != 1 || _modoReajusteSabores) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Reajuste sabores',
                  onPressed: () async {
                    final snap =
                        await StockService.saboresRef().get();
                    final current = snap.exists
                        ? snap.data() as Map<String, dynamic>
                        : <String, dynamic>{};
                    setState(() {
                      _modoReajusteSabores = true;
                      _tempReajusteSabores.clear();
                      for (final s in CartaConstants.saboresUnicos) {
                        _tempReajusteSabores[s] =
                            (current[s] as num?)?.toInt() ?? 0;
                      }
                    });
                  },
                );
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'MEZCLAS'),
            Tab(text: 'SABORES'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMezclasTab(dt, sw),
          _buildSaboresTab(dt, sw),
        ],
      ),
    );
  }

  Widget _buildMezclasTab(bool dt, double sw) {
    Widget content = ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: CartaConstants.recetas.length,
      itemBuilder: (context, index) {
        final receta = CartaConstants.recetas[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  receta.nombre,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: receta.ingredientes.asMap().entries.map((e) {
                    final color = _colores[e.key % _colores.length];
                    final ing = e.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color, width: 1.5),
                      ),
                      child: Text(
                        '${ing.nombre}  ${ing.porcentaje}%',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 13),
                      ),
                    );
                  }).toList(),
                ),
                if (receta.ingredientes.length > 1) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Row(
                      children: receta.ingredientes.asMap().entries.map((e) {
                        return Expanded(
                          flex: e.value.porcentaje,
                          child: Container(
                            height: 8,
                            color: _colores[e.key % _colores.length],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
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
  }

  Widget _buildSaboresTab(bool dt, double sw) {
    return StreamBuilder<DocumentSnapshot>(
      stream: StockService.saboresStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};

        final sabores = CartaConstants.saboresUnicos;

        Widget listContent = ListView.builder(
          itemCount: sabores.length,
          itemBuilder: (context, index) {
            final nombre = sabores[index];
            final cantidad = (data[nombre] as num?)?.toInt() ?? 0;
            return ListTile(
              title: Text(nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: _modoReajusteSabores
                  ? SizedBox(
                      width: 70,
                      child: TextFormField(
                        key: Key('sab_$nombre'),
                        initialValue:
                            '${_tempReajusteSabores[nombre] ?? cantidad}',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange),
                        decoration: const InputDecoration(
                            isDense: true, border: OutlineInputBorder()),
                        onChanged: (v) =>
                            _tempReajusteSabores[nombre] =
                                int.tryParse(v) ?? 0,
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: cantidad == 0
                            ? Colors.red.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cantidad == 0
                              ? Colors.redAccent
                              : Colors.blueAccent,
                        ),
                      ),
                      child: Text(
                        '$cantidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cantidad == 0
                              ? Colors.redAccent
                              : Colors.blueAccent,
                        ),
                      ),
                    ),
            );
          },
        );

        Widget content = _modoReajusteSabores
            ? Column(children: [
                Expanded(child: listContent),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      border:
                          Border(top: BorderSide(color: Colors.white10))),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() {
                          _modoReajusteSabores = false;
                          _tempReajusteSabores.clear();
                        }),
                        style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            side: const BorderSide(color: Colors.grey)),
                        child: const Text('CANCELAR',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _guardarReajusteSabores(data),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(0, 50)),
                        child: const Text('GUARDAR',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.white)),
                      ),
                    ),
                  ]),
                ),
              ])
            : listContent;

        return dt
            ? Align(
                alignment: Alignment.topCenter,
                child: SizedBox(width: sw * 0.6, child: content))
            : content;
      },
    );
  }
}
