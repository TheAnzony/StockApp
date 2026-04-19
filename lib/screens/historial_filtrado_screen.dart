import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';

class HistorialFiltradoScreen extends StatelessWidget {
  final String filtro;
  final String titulo;

  const HistorialFiltradoScreen(
      {super.key, required this.filtro, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = (usuarioActual?['rol'] ?? '') == 'admin';

    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: StreamBuilder(
        stream: StockService.logsStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> sn) {
          if (!sn.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = sn.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            if (filtro == 'GENERAL') return data.containsKey('stock_final');
            return data.containsKey('movimientos') &&
                (data['movimientos'] as List).any((m) => m['motivo'] == filtro);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text('Sin registros'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = d.data() as Map<String, dynamic>;
              final List totalMovs = data['movimientos'] as List;

              final movsRoturas =
                  totalMovs.where((m) => m['motivo'] == 'ROTURAS').toList();
              final movsAltas =
                  totalMovs.where((m) => m['motivo'] == 'ALTA').toList();
              final movsLogisticos = totalMovs
                  .where((m) =>
                      m['motivo'] == 'RECIBIDO' || m['motivo'] == 'PRESTADO')
                  .toList();

              final Map<String, dynamic> fugasMap = data['fugas'] ?? {};
              final Map<String, int> fugasReales = {};
              fugasMap.forEach((art, cantFuga) {
                final String key = art.toLowerCase();
                final int ajuste = (cantFuga as num).toInt();
                int totalRoto = 0;
                for (var m in totalMovs) {
                  if (m['articulo'] == art.toUpperCase() &&
                      m['motivo'] == 'ROTURAS') {
                    totalRoto += (m['cantidad'] as num).toInt();
                  }
                }
                if (key == 'cachimbas') {
                  final int ajusteMastil = (fugasMap['mastil'] ?? 0).toInt();
                  final int neto = ajuste + ajusteMastil;
                  if (neto != 0) fugasReales[art] = neto;
                } else if (key == 'mastil') {
                  return;
                } else {
                  final int neto = ajuste - totalRoto;
                  if (neto != 0) fugasReales[art] = neto;
                }
              });

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text("Día: ${d.id}"),
                  children: [
                    if (filtro == 'GENERAL' &&
                        data.containsKey('stock_final')) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text("📊 STOCK FINAL DEL DÍA",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan)),
                      ),
                      ...(data['stock_final'] as Map<String, dynamic>)
                          .entries
                          .map((entry) => ListTile(
                                dense: true,
                                title: Text(entry.key.toUpperCase()),
                                trailing: Text("${entry.value}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
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
                              leading: const Icon(Icons.star,
                                  color: Colors.blueAccent),
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
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey)),
                        ),
                      ...movsRoturas.map((m) => ListTile(
                            dense: true,
                            title:
                                Text("${m['articulo']} (${m['cantidad']})"),
                            subtitle: Text("${m['operador']}"),
                          )),
                      const Divider(thickness: 2),
                      if (fugasReales.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
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
                              Text("DESCUADRE",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent)),
                            ],
                          ),
                        ),
                        ...fugasReales.entries.map((entry) {
                          String? lugar;
                          for (var mov in totalMovs) {
                            if (mov['articulo'] ==
                                    entry.key.toUpperCase() &&
                                mov['motivo'] == 'PRESTADO') {
                              lugar = mov['destino'];
                              break;
                            }
                          }
                          return ListTile(
                            dense: true,
                            title: Text(entry.key.toUpperCase(),
                                style: const TextStyle(
                                    color: Colors.redAccent)),
                            trailing: Text(
                                entry.value < 0
                                    ? "${entry.value}"
                                    : "+${entry.value}",
                                style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(lugar != null
                                ? "Viene de PRESTADO ($lugar)."
                                : (entry.value < 0
                                    ? "Faltan ${entry.value.abs()} unidades."
                                    : "Sobran ${entry.value.abs()} unidades.")),
                          );
                        }),
                      ],
                      const Divider(),
                      ExpansionTile(
                        title: const Text("📦 MOVIMIENTOS LOGÍSTICOS",
                            style: TextStyle(
                                fontSize: 13, color: Colors.blueGrey)),
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
                    if (filtro != 'GENERAL')
                      ...totalMovs
                          .where((m) => m['motivo'] == filtro)
                          .map((m) {
                        final DateTime dt =
                            (m['fecha'] as Timestamp).toDate();
                        return ListTile(
                          title: Text(
                              "${m['articulo']} (${m['cantidad'] > 0 ? "+" : ""}${m['cantidad']})"),
                          subtitle: Text(
                              "Por: ${m['operador']} | ${dt.day}/${dt.month} - ${dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${m['concepto'] ?? ''}"),
                          trailing: isAdmin
                              ? IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () async {
                                    await d.reference.update({
                                      'movimientos':
                                          FieldValue.arrayRemove([m])
                                    });
                                  },
                                )
                              : null,
                        );
                      }),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
