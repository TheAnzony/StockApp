import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sabor.dart';
import '../services/stock_service.dart';
import '../session.dart';

class Ingrediente {
  final String nombre;
  final int porcentaje;
  const Ingrediente(this.nombre, this.porcentaje);

  factory Ingrediente.fromMap(Map<String, dynamic> m) => Ingrediente(
        m['nombre'] as String? ?? '',
        (m['porcentaje'] as num?)?.toInt() ?? 0,
      );
}

class Receta {
  final String nombre;
  final List<Ingrediente> ingredientes;
  final Map<String, dynamic> raw;
  const Receta(this.nombre, this.ingredientes, this.raw);

  factory Receta.fromMap(Map<String, dynamic> m) => Receta(
        m['nombre'] as String? ?? '',
        ((m['ingredientes'] as List?) ?? [])
            .map((i) => Ingrediente.fromMap(Map<String, dynamic>.from(i as Map)))
            .toList(),
        m,
      );
}

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
  }

  void _dialogoUsarSabor(String nombre, int stockActual) {
    int cantidad = 1;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, st) => AlertDialog(
          title: Text(nombre),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock actual: $stockActual',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                    onPressed: cantidad > 1
                        ? () => st(() => cantidad--)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text('$cantidad',
                      style: const TextStyle(
                          fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        size: 32, color: Colors.blueAccent),
                    onPressed: cantidad < stockActual
                        ? () => st(() => cantidad++)
                        : null,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange),
              onPressed: stockActual == 0
                  ? null
                  : () async {
                      Navigator.pop(c);
                      await StockService.saboresRef().update({
                        '$nombre.cantidad': FieldValue.increment(-cantidad),
                      });
                    },
              child: const Text('USAR',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarReajusteSabores(Map<String, dynamic> currentData) async {
    final Map<String, dynamic> updates = {};
    _tempReajusteSabores.forEach((k, v) {
      final map = currentData[k] as Map<String, dynamic>? ?? {};
      final current = (map['cantidad'] as num?)?.toInt() ?? 0;
      if (v != current) updates['$k.cantidad'] = v;
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

  Future<List<Sabor>?> _cargarSabores() async {
    final snap = await StockService.saboresRef().get();
    if (!snap.exists || !mounted) return null;
    final data = snap.data() as Map<String, dynamic>;
    return data.entries.map((e) => Sabor.fromEntry(e.key, e.value)).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  Future<Set<String>> _nombresMezclasExistentes({String? excluir}) async {
    final snap = await StockService.mezclasRef().get();
    if (!snap.exists) return {};
    final data = snap.data() as Map<String, dynamic>;
    final recetas = (data['recetas'] as List?) ?? [];
    return recetas
        .map((r) => (r as Map)['nombre'] as String? ?? '')
        .where((n) => n.isNotEmpty && n != excluir)
        .toSet();
  }

  Future<void> _abrirNuevaMezcla() async {
    final sabores = await _cargarSabores();
    if (sabores == null || !mounted) return;
    final nombresExistentes = await _nombresMezclasExistentes();
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => _BottomSheetMezcla(
        sabores: sabores,
        nombresExistentes: nombresExistentes,
      ),
    );
  }

  Future<void> _abrirEditarMezcla(Receta receta) async {
    final sabores = await _cargarSabores();
    if (sabores == null || !mounted) return;
    final nombresExistentes =
        await _nombresMezclasExistentes(excluir: receta.nombre);
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => _BottomSheetMezcla(
        sabores: sabores,
        nombresExistentes: nombresExistentes,
        existente: receta,
      ),
    );
  }

  void _dialogoEliminarMezcla(Receta receta) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar mezcla'),
        content: Text('¿Borrar la mezcla "${receta.nombre}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('NO')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              StockService.deleteMezcla(receta.raw);
              Navigator.pop(c);
            },
            child: const Text('SÍ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
                      for (final entry in current.entries) {
                        final map = entry.value as Map<String, dynamic>? ?? {};
                        _tempReajusteSabores[entry.key] =
                            (map['cantidad'] as num?)?.toInt() ?? 0;
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
      floatingActionButton: isAdmin
          ? AnimatedBuilder(
              animation: _tabController,
              builder: (_, child) {
                if (_tabController.index != 0) return const SizedBox.shrink();
                return FloatingActionButton.extended(
                  onPressed: _abrirNuevaMezcla,
                  backgroundColor: Colors.purple,
                  icon: const Icon(Icons.add),
                  label: const Text('NUEVA MEZCLA'),
                );
              },
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMezclasTab(dt, sw, isAdmin),
          _buildSaboresTab(dt, sw),
        ],
      ),
    );
  }

  Widget _buildMezclasTab(bool dt, double sw, bool isAdmin) {
    return StreamBuilder<DocumentSnapshot>(
      stream: StockService.mezclasStream(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.exists
            ? snap.data!.data() as Map<String, dynamic>
            : <String, dynamic>{};
        final recetas = ((data['recetas'] as List?) ?? [])
            .map((r) => Receta.fromMap(Map<String, dynamic>.from(r as Map)))
            .toList();

        Widget content = recetas.isEmpty
            ? const Center(child: Text('Sin mezclas todavía'))
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: recetas.length,
                itemBuilder: (context, index) {
                  final receta = recetas[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  receta.nombre,
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              if (isAdmin) ...[
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blueGrey, size: 20),
                                  onPressed: () => _abrirEditarMezcla(receta),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent, size: 20),
                                  onPressed: () => _dialogoEliminarMezcla(receta),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
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
      },
    );
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

        final sabores = data.entries
            .map((e) => Sabor.fromEntry(e.key, e.value))
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

        Widget listContent = ListView.builder(
          itemCount: sabores.length,
          itemBuilder: (context, index) {
            final s = sabores[index];
            final nombre = s.nombre;
            final cantidad = s.cantidad;
            return ListTile(
              onTap: _modoReajusteSabores
                  ? null
                  : () => _dialogoUsarSabor(nombre, cantidad),
              title: Text(nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: s.marca.isNotEmpty
                  ? Text('${s.marca}  ·  ${s.formato}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey))
                  : null,
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

// ─── Bottom sheet para crear o editar una mezcla ─────────────────────────────

class _BottomSheetMezcla extends StatefulWidget {
  final List<Sabor> sabores;
  final Set<String> nombresExistentes;
  final Receta? existente;
  const _BottomSheetMezcla({
    required this.sabores,
    required this.nombresExistentes,
    this.existente,
  });

  @override
  State<_BottomSheetMezcla> createState() => _BottomSheetMezclaState();
}

class _BottomSheetMezclaState extends State<_BottomSheetMezcla> {
  late final _nombreCtrl =
      TextEditingController(text: widget.existente?.nombre ?? '');
  late final Map<String, int> _seleccionados = {
    for (final i in widget.existente?.ingredientes ?? <Ingrediente>[])
      i.nombre: i.porcentaje,
  };
  String _busqueda = '';

  bool get _esEdicion => widget.existente != null;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    super.dispose();
  }

  int get _total => _seleccionados.values.fold(0, (a, b) => a + b);

  Future<void> _guardar() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ponle un nombre a la mezcla')));
      return;
    }
    if (widget.nombresExistentes
        .any((n) => n.toLowerCase() == nombre.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ya existe una mezcla llamada "$nombre"')));
      return;
    }
    if (_seleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añade al menos un sabor')));
      return;
    }
    if (_seleccionados.values.any((p) => p <= 0)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Todos los sabores deben tener un porcentaje mayor a 0')));
      return;
    }
    if (_total != 100) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Los porcentajes deben sumar 100% (llevas $_total%)')));
      return;
    }

    final ingredientes = _seleccionados.entries
        .map((e) => {'nombre': e.key, 'porcentaje': e.value})
        .toList();

    if (_esEdicion) {
      await StockService.updateMezcla(
        nombreViejo: widget.existente!.nombre,
        nombreNuevo: nombre,
        ingredientes: ingredientes,
      );
    } else {
      await StockService.addMezcla(nombre, ingredientes);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final disponibles = widget.sabores
        .where((s) =>
            !_seleccionados.containsKey(s.nombre) &&
            s.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (c, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(_esEdicion ? 'EDITAR MEZCLA' : 'NUEVA MEZCLA',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1)),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (_total == 100 ? Colors.green : Colors.orange)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: _total == 100 ? Colors.green : Colors.orange),
                    ),
                    child: Text('$_total%',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _total == 100 ? Colors.green : Colors.orange)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _nombreCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nombre de la mezcla',
                    border: OutlineInputBorder(),
                    isDense: true),
                textCapitalization: TextCapitalization.words,
              ),
            ),
            if (_seleccionados.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('INGREDIENTES',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white38, letterSpacing: 1)),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 170),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _seleccionados.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                              child: Text(e.key,
                                  style:
                                      const TextStyle(fontWeight: FontWeight.w600))),
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              key: Key('mez_${e.key}'),
                              initialValue: '${e.value}',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  suffixText: '%'),
                              onChanged: (v) => setState(
                                  () => _seleccionados[e.key] = int.tryParse(v) ?? 0),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.redAccent, size: 20),
                            onPressed: () =>
                                setState(() => _seleccionados.remove(e.key)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
            ],
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Buscar sabor para añadir...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _busqueda = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: disponibles.length,
                itemBuilder: (c, i) {
                  final s = disponibles[i];
                  return ListTile(
                    leading: const Icon(Icons.local_fire_department,
                        color: Colors.indigo),
                    title: Text(s.nombre),
                    subtitle: s.marca.isNotEmpty
                        ? Text('${s.marca} · ${s.formato}',
                            style: const TextStyle(fontSize: 11))
                        : null,
                    onTap: () => setState(() => _seleccionados[s.nombre] = 0),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: _guardar,
                  child: Text(_esEdicion ? 'GUARDAR CAMBIOS' : 'GUARDAR MEZCLA',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
