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
                  ..sort((a, b) => b.id.compareTo(a.id));
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

    final movsRoturas =
        totalMovs.where((m) => m['motivo'] == 'ROTURAS').toList();
    final movsAltas =
        totalMovs.where((m) => m['motivo'] == 'ALTA').toList();
    final movsLogisticos = totalMovs
        .where((m) =>
            m['motivo'] == 'RECIBIDO' || m['motivo'] == 'PRESTADO')
        .toList();

    final Map<String, dynamic> fugasRaw = data['fugas'] ?? {};
    Map<String, int> fugasRoturas = {};
    Map<String, int> fugasPrestados = {};
    Map<String, int> fugasDesconocido = {};

    if (fugasRaw.containsKey('roturas') ||
        fugasRaw.containsKey('prestados') ||
        fugasRaw.containsKey('desconocido')) {
      (fugasRaw['roturas'] as Map? ?? {})
          .forEach((k, v) => fugasRoturas[k] = (v as num).toInt());
      (fugasRaw['prestados'] as Map? ?? {})
          .forEach((k, v) => fugasPrestados[k] = (v as num).toInt());
      (fugasRaw['desconocido'] as Map? ?? {})
          .forEach((k, v) => fugasDesconocido[k] = (v as num).toInt());
    } else {
      fugasRaw.forEach(
          (k, v) => fugasDesconocido[k] = (v as num).toInt());
    }

    final bool hayFugas = fugasRoturas.isNotEmpty ||
        fugasPrestados.isNotEmpty ||
        fugasDesconocido.isNotEmpty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        title: Text("Día: ${_formatFecha(d.id)}"),
        children: [
          if (widget.filtro == 'GENERAL' &&
              data.containsKey('stock_final')) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("📊 STOCK FINAL DEL DÍA",
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.cyan)),
            ),
            ...(data['stock_final'] as Map<String, dynamic>)
                .entries
                .map((entry) => ListTile(
                      dense: true,
                      title: Text(entry.key.toUpperCase()),
                      trailing: Text("${entry.value}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    )),
            if (movsAltas.isNotEmpty) ...[
              const Divider(color: Colors.blueAccent),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0),
                child: Text("🆕 ARTÍCULOS NUEVOS",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent)),
              ),
              ...movsAltas.map((m) => ListTile(
                    dense: true,
                    leading:
                        const Icon(Icons.star, color: Colors.blueAccent),
                    title: Text(m['articulo']),
                  )),
            ],
            const Divider(color: Colors.white54),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("⚠️ ROTURAS",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orangeAccent)),
            ),
            if (movsRoturas.isEmpty)
              const ListTile(
                title: Text("Sin roturas registradas",
                    style: TextStyle(
                        fontStyle: FontStyle.italic, color: Colors.grey)),
              ),
            ...movsRoturas.map((m) => ListTile(
                  dense: true,
                  title: Text("${m['articulo']} (${m['cantidad']})"),
                  subtitle: Text("${m['operador']}"),
                )),
            const Divider(thickness: 2),
            if (!hayFugas)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 10),
                    Text("NO HAY DESCUADRE",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Text("DESCUADRES",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent)),
                  ],
                ),
              ),
              if (fugasRoturas.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text("🔧 POR ROTURA",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orangeAccent)),
                ),
                ...fugasRoturas.entries.map((e) => ListTile(
                      dense: true,
                      title: Text(e.key.toUpperCase(),
                          style:
                              const TextStyle(color: Colors.orangeAccent)),
                      trailing: Text("${e.value}",
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "Faltan ${e.value.abs()} unidades por rotura."),
                    )),
              ],
              if (fugasPrestados.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text("🔄 POR PRESTADO",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent)),
                ),
                ...fugasPrestados.entries.map((e) => ListTile(
                      dense: true,
                      title: Text(e.key.toUpperCase(),
                          style:
                              const TextStyle(color: Colors.blueAccent)),
                      trailing: Text("${e.value}",
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          "Faltan ${e.value.abs()} unidades por préstamo."),
                    )),
              ],
              if (fugasDesconocido.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text("❓ DESCONOCIDO",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent)),
                ),
                ...fugasDesconocido.entries.map((e) => ListTile(
                      dense: true,
                      title: Text(e.key.toUpperCase(),
                          style:
                              const TextStyle(color: Colors.redAccent)),
                      trailing: Text(
                          e.value < 0 ? "${e.value}" : "+${e.value}",
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(e.value < 0
                          ? "Faltan ${e.value.abs()} unidades sin motivo conocido."
                          : "Sobran ${e.value.abs()} unidades sin motivo conocido."),
                    )),
              ],
            ],
            const Divider(),
            ExpansionTile(
              title: const Text("📦 MOVIMIENTOS LOGÍSTICOS",
                  style:
                      TextStyle(fontSize: 13, color: Colors.blueGrey)),
              children: movsLogisticos
                  .map((m) => ListTile(
                        dense: true,
                        leading: Icon(
                            m['motivo'] == 'RECIBIDO'
                                ? Icons.download
                                : Icons.upload,
                            color: m['motivo'] == 'RECIBIDO'
                                ? Colors.green
                                : Colors.orange,
                            size: 18),
                        title: Text(
                            "${m['articulo']} (${m['cantidad'] > 0 ? "+" : ""}${m['cantidad']})"),
                        subtitle: Text(
                            "${m['motivo']} ${m['destino'] ?? m['concepto'] ?? ''}"),
                      ))
                  .toList(),
            ),
          ],
          if (widget.filtro != 'GENERAL')
            ...totalMovs
                .where((m) => m['motivo'] == widget.filtro)
                .map((m) {
              final DateTime dt =
                  (m['fecha'] as Timestamp).toDate();
              return ListTile(
                title: Text(
                    "${m['articulo']} (${m['cantidad'] > 0 ? "+" : ""}${m['cantidad']})"),
                subtitle: Text(
                    "Por: ${m['operador'] ?? '-'} | ${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${m['concepto'] ?? m['destino'] ?? ''}"),
                trailing: isAdmin
                    ? IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.redAccent),
                        onPressed: () async {
                          await d.reference.update({
                            'movimientos': FieldValue.arrayRemove([m])
                          });
                        },
                      )
                    : null,
              );
            }),
        ],
      ),
    );
  }
}
