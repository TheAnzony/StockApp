import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/carta_constants.dart';
import '../services/stock_service.dart';

class CartaScreen extends StatefulWidget {
  const CartaScreen({super.key});
  @override
  State<CartaScreen> createState() => _CartaScreenState();
}

class _CartaScreenState extends State<CartaScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  Future<void> _init() async {
    final sabores = {for (var s in CartaConstants.saboresUnicos) s: 0};
    await StockService.initSaboresIfNeeded(sabores);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CARTA'),
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

        Widget content = ListView.builder(
          itemCount: sabores.length,
          itemBuilder: (context, index) {
            final nombre = sabores[index];
            final cantidad = (data[nombre] as num?)?.toInt() ?? 0;
            return ListTile(
              title: Text(nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: cantidad == 0
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: cantidad == 0 ? Colors.redAccent : Colors.blueAccent,
                  ),
                ),
                child: Text(
                  '$cantidad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color:
                        cantidad == 0 ? Colors.redAccent : Colors.blueAccent,
                  ),
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
}
