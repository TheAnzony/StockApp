import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';

class HistorialFiltradoScreen extends StatefulWidget {
  final String filtro;
  final String titulo;

  const HistorialFiltradoScreen(
      {super.key, required this.filtro, required this.titulo});

  @override
  State<HistorialFiltradoScreen> createState() =>
      _HistorialFiltradoScreenState();
}

class _HistorialFiltradoScreenState extends State<HistorialFiltradoScreen> {
  int? _anio;
  final Set<int> _mesesColapsados = {};
  bool _inicializado = false;

  static const _meses = [
    '', 'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  String _formatFecha(String id) {
    final p = id.split('-');
    if (p.length != 3) return id;
    return '${p[2].padLeft(2, '0')}-${p[1].padLeft(2, '0')}-${p[0]}';
  }

  int _anioDeId(String id) => int.tryParse(id.split('-').first) ?? 0;
  int _mesDeId(String id) {
    final p = id.split('-');
    return p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0;
  }
  int _diaDeId(String id) {
    final p = id.split('-');
    return p.length > 2 ? (int.tryParse(p[2]) ?? 0) : 0;
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = (usuarioActual?['rol'] ?? '') == 'admin';
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      body: StreamBuilder(
        stream: StockService.logsStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> sn) {
          if (!sn.hasData) {
            return Scaffold(
              appBar: AppBar(title: Text(widget.titulo)),
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          // Filtrar documentos según el tipo de historial
          final docs = sn.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            if (widget.filtro == 'GENERAL') return data.containsKey('stock_final');
            return data.containsKey('movimientos') &&
                (data['movimientos'] as List)
                    .any((m) => m['motivo'] == widget.filtro);
          }).toList();

          // Años disponibles (desc)
          final anios = docs
              .map((d) => _anioDeId(d.id))
              .where((a) => a > 0)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final anioActual = _anio ?? (anios.isNotEmpty ? anios.first : DateTime.now().year);

          // Filtrar por año seleccionado
          final docsFiltrados = docs
              .where((d) => _anioDeId(d.id) == anioActual)
              .toList();

          // Agrupar por mes
          final Map<int, List<QueryDocumentSnapshot>> porMes = {};
          for (final d in docsFiltrados) {
            final mes = _mesDeId(d.id);
            porMes.putIfAbsent(mes, () => []).add(d);
          }
          final mesesOrdenados = porMes.keys.toList()
            ..sort((a, b) => a.compareTo(b));

          if (!_inicializado && mesesOrdenados.isNotEmpty) {
            final mesActual = DateTime.now().month;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _mesesColapsados.addAll(
                    mesesOrdenados.where((m) => m != mesActual),
                  );
                  _inicializado = true;
                });
              }
            });
          }

          Widget body;
          if (docsFiltrados.isEmpty) {
            body = const Center(child: Text('Sin registros'));
          } else {
            Widget listView = ListView.builder(
              itemCount: mesesOrdenados.length,
              itemBuilder: (context, i) {
                final mes = mesesOrdenados[i];
                final dias = porMes[mes]!
                  ..sort((a, b) => _diaDeId(b.id).compareTo(_diaDeId(a.id)));
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
                                color: Colors.blueAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _meses[mes].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blueAccent,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${dias.length} ${dias.length == 1 ? 'día' : 'días'})',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            const Spacer(),
                            Icon(
                              _mesesColapsados.contains(mes)
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              color: Colors.blueAccent,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_mesesColapsados.contains(mes))
                      ...dias.map((d) => _buildDiaCard(d, isAdmin)),
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
              title: Text(widget.titulo),
              actions: [
                if (anios.length > 1)
                  PopupMenuButton<int>(
                    tooltip: 'Filtrar año',
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '$anioActual',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                    onSelected: (v) => setState(() => _anio = v),
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

  Widget _buildDiaCard(QueryDocumentSnapshot d, bool isAdmin) {
    final data = d.data() as Map<String, dynamic>;
    final List totalMovs = data['movimientos'] as List? ?? [];

    if (widget.filtro == 'GENERAL') {
      return _buildGeneralCard(d.id, data, totalMovs);
    }

    // Otros historiales (RECIBIDO, ROTURAS, PRESTADO)
    final movsFiltrados =
        totalMovs.where((m) => m['motivo'] == widget.filtro).toList();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: Text("Día: ${_formatFecha(d.id)}"),
        children: movsFiltrados.map((m) {
          final DateTime dt = (m['fecha'] as Timestamp).toDate();
          return ListTile(
            title: Text(
                "${m['articulo']} (${m['cantidad'] > 0 ? "+" : ""}${m['cantidad']})"),
            subtitle: Text(
                "Por: ${m['operador'] ?? '-'} | ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${m['concepto'] ?? m['destino'] ?? ''}"),
            trailing: isAdmin
                ? IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () async {
                      await d.reference.update({
                        'movimientos': FieldValue.arrayRemove([m])
                      });
                    },
                  )
                : null,
          );
        }).toList(),
      ),
    );
  }

  List<MapEntry<String, int>> _calcularDescuadres(
      Map<String, dynamic> stockAnterior, Map<String, dynamic> stockFinal) {
    final descuadres = <MapEntry<String, int>>[];
    stockAnterior.forEach((k, v) {
      final int vAnterior = (v as num).toInt();
      final int vFinal = (stockFinal[k] as num?)?.toInt() ?? vAnterior;
      if (vFinal != vAnterior) descuadres.add(MapEntry(k, vFinal - vAnterior));
    });
    return descuadres;
  }

  Widget _buildDescuadreSection(
      Map<String, dynamic> stockAnterior,
      Map<String, dynamic> stockFinal,
      String? anteriorId) {
    // Si tenemos stock_anterior directo, calcular sin async
    if (stockAnterior.isNotEmpty) {
      return _descuadreWidget(_calcularDescuadres(stockAnterior, stockFinal));
    }
    // Si hay referencia al doc anterior, buscarlo
    if (anteriorId != null && anteriorId.isNotEmpty) {
      return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('logs_diarios')
            .doc(anteriorId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final anteriorData =
              snap.data!.data() as Map<String, dynamic>? ?? {};
          final sfAnterior =
              anteriorData['stock_final'] as Map<String, dynamic>? ?? {};
          return _descuadreWidget(_calcularDescuadres(sfAnterior, stockFinal));
        },
      );
    }
    return _descuadreWidget([]);
  }

  Widget _descuadreWidget(List<MapEntry<String, int>> descuadres) {
    if (descuadres.isEmpty) {
      return const ListTile(
        dense: true,
        title: Text("Sin descuadre",
            style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      );
    }
    return Column(
      children: descuadres.map((e) {
        final bool negativo = e.value < 0;
        return ListTile(
          dense: true,
          title: Text(e.key.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            "${e.value > 0 ? '+' : ''}${e.value}",
            style: TextStyle(
                color: negativo ? Colors.redAccent : Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 15),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGeneralCard(
      String docId, Map<String, dynamic> data, List totalMovs) {
    final stockAnterior =
        (data['stock_anterior'] as Map<String, dynamic>?) ?? {};
    final stockFinal =
        (data['stock_final'] as Map<String, dynamic>?) ?? {};
    final anteriorId = data['stock_anterior_id'] as String?;

    // Stock realizado = stock_final (contiene todos los artículos contados)
    final Map<String, int> stockRealizado = {};
    stockFinal.forEach((k, v) => stockRealizado[k] = (v as num).toInt());

    final movsRoturas =
        totalMovs.where((m) => m['motivo'] == 'ROTURAS').toList();
    final movsRecibidos =
        totalMovs.where((m) => m['motivo'] == 'RECIBIDO').toList();
    final movsPrestados =
        totalMovs.where((m) => m['motivo'] == 'PRESTADO').toList();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: Text("Día: ${_formatFecha(docId)}"),
        children: [
          // ── STOCK REALIZADO ───────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text("STOCK REALIZADO",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan,
                    letterSpacing: 1.2)),
          ),
          if (stockRealizado.isEmpty)
            const ListTile(
              dense: true,
              title: Text("Sin datos de stock",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            )
          else
            ...(stockRealizado.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key)))
                .map((e) => ListTile(
                      dense: true,
                      title: Text(e.key.toUpperCase(),
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: Text("${e.value}",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.cyan)),
                    )),

          const Divider(),

          // ── DESCUADRE ─────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("DESCUADRE",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                    letterSpacing: 1.2)),
          ),
          _buildDescuadreSection(stockAnterior, stockFinal, anteriorId),

          const Divider(),

          // ── ROTURAS ───────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("ROTURAS",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orangeAccent,
                    letterSpacing: 1.2)),
          ),
          if (movsRoturas.isEmpty)
            const ListTile(
              dense: true,
              title: Text("Sin roturas",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            )
          else
            ...movsRoturas.map((m) => ListTile(
                  dense: true,
                  title: Text(
                      "${m['articulo']} (${m['cantidad']})"),
                  subtitle: Text("${m['operador'] ?? '-'}"),
                )),

          const Divider(),

          // ── RECIBIDOS ─────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text("RECIBIDOS",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    letterSpacing: 1.2)),
          ),
          if (movsRecibidos.isEmpty)
            const ListTile(
              dense: true,
              title: Text("Sin recibidos",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            )
          else
            ...movsRecibidos.map((m) => ListTile(
                  dense: true,
                  title: Text(
                      "${m['articulo']} (+${m['cantidad']})"),
                  subtitle: Text(
                      "${m['operador'] ?? '-'}  ${m['concepto'] != null ? '· ${m['concepto']}' : ''}"),
                )),

          const Divider(),

          // ── PRESTADOS ─────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Text("PRESTADOS",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    letterSpacing: 1.2)),
          ),
          if (movsPrestados.isEmpty)
            const ListTile(
              dense: true,
              title: Text("Sin prestados",
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey)),
            )
          else
            ...movsPrestados.map((m) => ListTile(
                  dense: true,
                  title: Text(
                      "${m['articulo']} (${m['cantidad']})"),
                  subtitle: Text(
                      "${m['operador'] ?? '-'}  ${m['destino'] != null ? '· ${m['destino']}' : ''}"),
                )),
        ],
      ),
    );
  }
}
