import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_service.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  int? _anio;
  final Set<int> _mesesColapsados = {};
  bool _inicializado = false;

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  static const Map<String, Color> _coloresPrioridad = {
    'alta':   Color(0xFFFF5252),
    'media':  Colors.orange,
    'baja':   Colors.amber,
    'manual': Colors.blueGrey,
  };

  static const Map<String, String> _labelPrioridad = {
    'alta':   'ALTA',
    'media':  'MEDIA',
    'baja':   'BAJA',
    'manual': 'MANUAL',
  };

  String _formatFecha(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.year}  '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: StockService.pedidosStream(),
        builder: (context, sn) {
          if (!sn.hasData) {
            return Scaffold(
              appBar: AppBar(title: const Text('PEDIDOS')),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          final docs = sn.data!.docs;

          // Años disponibles
          final anios = docs
              .map((d) {
                final ts = d['fecha'] as Timestamp?;
                return ts?.toDate().year ?? 0;
              })
              .where((y) => y > 0)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final anioActual = _anio ?? (anios.isNotEmpty ? anios.first : DateTime.now().year);

          // Filtrar por año
          final docsFiltrados = docs.where((d) {
            final ts = d['fecha'] as Timestamp?;
            return (ts?.toDate().year ?? 0) == anioActual;
          }).toList();

          // Agrupar por mes
          final Map<int, List<QueryDocumentSnapshot>> porMes = {};
          for (final d in docsFiltrados) {
            final ts = d['fecha'] as Timestamp?;
            final mes = ts?.toDate().month ?? 0;
            porMes.putIfAbsent(mes, () => []).add(d);
          }
          final mesesOrdenados = porMes.keys.toList()..sort((a, b) => a.compareTo(b));

          // Inicializar colapso: todos los meses menos el actual ocultos
          if (!_inicializado && mesesOrdenados.isNotEmpty) {
            final mesActual = DateTime.now().month;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _mesesColapsados.addAll(mesesOrdenados.where((m) => m != mesActual));
                  _inicializado = true;
                });
              }
            });
          }

          Widget body;
          if (docsFiltrados.isEmpty) {
            body = const Center(child: Text('Sin pedidos registrados'));
          } else {
            Widget listView = ListView.builder(
              itemCount: mesesOrdenados.length,
              itemBuilder: (context, i) {
                final mes = mesesOrdenados[i];
                final pedidos = porMes[mes]!
                  ..sort((a, b) {
                    final ta = (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(0);
                    final tb = (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(0);
                    return tb.compareTo(ta); // más reciente primero
                  });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        if (_mesesColapsados.contains(mes)) {
                          _mesesColapsados.remove(mes);
                        } else {
                          _mesesColapsados.add(mes);
                        }
                      }),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.deepOrange,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _meses[mes].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.deepOrange,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${pedidos.length} pedido${pedidos.length == 1 ? '' : 's'})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Spacer(),
                            Icon(
                              _mesesColapsados.contains(mes)
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.deepOrange,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_mesesColapsados.contains(mes))
                      ...pedidos.map((d) => _buildPedidoCard(d)),
                    const SizedBox(height: 4),
                  ],
                );
              },
            );

            body = dt
                ? Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(width: sw * 0.6, child: listView))
                : listView;
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('PEDIDOS'),
              actions: [
                if (anios.length > 1)
                  PopupMenuButton<int>(
                    tooltip: 'Filtrar año',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('$anioActual',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    onSelected: (v) => setState(() {
                      _anio = v;
                      _inicializado = false;
                      _mesesColapsados.clear();
                    }),
                    itemBuilder: (_) => anios
                        .map((a) => PopupMenuItem(
                              value: a,
                              child: Text('$a',
                                  style: TextStyle(
                                      fontWeight: a == anioActual
                                          ? FontWeight.bold
                                          : FontWeight.normal)),
                            ))
                        .toList(),
                  ),
              ],
            ),
            body: body,
          );
        },
      ),
    );
  }

  Widget _buildPedidoCard(QueryDocumentSnapshot doc) {
    final ts = doc['fecha'] as Timestamp?;
    final fecha = ts != null ? _formatFecha(ts.toDate()) : '—';
    final operador = doc['operador'] as String? ?? '?';
    final items = (doc['items'] as List? ?? []).cast<Map<String, dynamic>>();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        leading: const Icon(Icons.shopping_cart_checkout, color: Colors.deepOrange),
        title: Text(fecha, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Por: $operador · ${items.length} artículo${items.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        children: items.map((item) {
          final nombre = item['nombre'] as String? ?? '';
          final prioridad = item['prioridad'] as String? ?? 'manual';
          final cantidad = (item['cantidad'] as num?)?.toInt() ?? 0;
          final esSabor = item['esSabor'] as bool? ?? false;
          final color = _coloresPrioridad[prioridad] ?? Colors.blueGrey;
          final label = _labelPrioridad[prioridad] ?? prioridad.toUpperCase();

          return ListTile(
            dense: true,
            leading: Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Row(
              children: [
                _chip(label, color),
                if (esSabor) ...[
                  const SizedBox(width: 4),
                  _chip('SABOR', Colors.indigo),
                ],
              ],
            ),
            trailing: cantidad > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('x$cantidad',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  )
                : const Text('—',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
          );
        }).toList(),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.bold, color: color)),
      );
}
