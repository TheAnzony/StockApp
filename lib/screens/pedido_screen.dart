import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sabor.dart';
import '../services/stock_service.dart';
import '../session.dart';

enum PrioridadPedido { alta, media, baja, manual }

class ItemPedido {
  final String nombre;
  final bool esSabor;
  final PrioridadPedido prioridad;
  int cantidad;

  ItemPedido({
    required this.nombre,
    required this.esSabor,
    required this.prioridad,
    this.cantidad = 0,
  });
}

class PedidoScreen extends StatefulWidget {
  const PedidoScreen({super.key});

  @override
  State<PedidoScreen> createState() => _PedidoScreenState();
}

class _PedidoScreenState extends State<PedidoScreen> {
  final List<ItemPedido> _manuales = [];
  Map<String, dynamic> _articulosCache = {};
  Map<String, dynamic> _saboresCache = {};
  // Persiste las cantidades introducidas entre rebuilds del stream
  final Map<String, int> _cantidades = {};

  // Case-insensitive lookup normalizando acentos
  int _get(Map<String, dynamic> data, String key) {
    final norm = _norm(key);
    for (final entry in data.entries) {
      if (_norm(entry.key) == norm) {
        return (entry.value as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  String _norm(String s) {
    const Map<String, String> map = {
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
      'ü': 'u', 'ñ': 'n',
    };
    return s.toLowerCase().split('').map((c) => map[c] ?? c).join('');
  }

  List<ItemPedido> _calcularSugerencias(
    Map<String, dynamic> art,
    Map<String, dynamic> sab,
  ) {
    final List<ItemPedido> lista = [];

    final cachimbas   = _get(art, 'cachimbas');
    final mastil      = _get(art, 'mastil');
    final cazoletas   = _get(art, 'cazoletas');
    final mangueras   = _get(art, 'mangueras');
    final bases       = _get(art, 'bases');
    final liquidoBases = _get(art, 'liquido bases');
    final hornillos   = _get(art, 'hornillos');

    // CAZOLETAS (0 ya queda cubierto por < 50 → alta)
    if (cazoletas < 50) {
      lista.add(ItemPedido(nombre: 'CAZOLETAS', esSabor: false, prioridad: PrioridadPedido.alta));
    } else if (cazoletas < cachimbas - 15) {
      lista.add(ItemPedido(nombre: 'CAZOLETAS', esSabor: false, prioridad: PrioridadPedido.media));
    }

    // BASES
    if (bases == 0 || mastil > bases) {
      lista.add(ItemPedido(
        nombre: 'BASES',
        esSabor: false,
        prioridad: (bases == 0 || mastil > 5) ? PrioridadPedido.alta : PrioridadPedido.media,
      ));
    }

    // LÍQUIDO BASES
    if (liquidoBases == 0) {
      lista.add(ItemPedido(nombre: 'LÍQUIDO BASES', esSabor: false, prioridad: PrioridadPedido.alta));
    } else if (liquidoBases == 1) {
      lista.add(ItemPedido(nombre: 'LÍQUIDO BASES', esSabor: false, prioridad: PrioridadPedido.media));
    }

    // CACHIMBAS
    final totalCachimbas = cachimbas + mastil;
    if (cachimbas == 0 || totalCachimbas < 40) {
      lista.add(ItemPedido(nombre: 'CACHIMBAS', esSabor: false, prioridad: PrioridadPedido.alta));
    } else if (totalCachimbas <= 50) {
      lista.add(ItemPedido(nombre: 'CACHIMBAS', esSabor: false, prioridad: PrioridadPedido.media));
    }

    // MANGUERAS (diferencia con cachimbas)
    final diffMangueras = cachimbas - mangueras;
    if (mangueras == 0 || diffMangueras >= 10) {
      lista.add(ItemPedido(nombre: 'MANGUERAS', esSabor: false, prioridad: PrioridadPedido.alta));
    } else if (diffMangueras > 0) {
      lista.add(ItemPedido(nombre: 'MANGUERAS', esSabor: false, prioridad: PrioridadPedido.media));
    }

    // HORNILLOS
    if (hornillos == 0) {
      lista.add(ItemPedido(nombre: 'HORNILLOS', esSabor: false, prioridad: PrioridadPedido.alta));
    } else if (hornillos <= 2) {
      lista.add(ItemPedido(nombre: 'HORNILLOS', esSabor: false, prioridad: PrioridadPedido.media));
    }

    // SABORES
    for (final entry in sab.entries) {
      final s = Sabor.fromEntry(entry.key, entry.value);
      PrioridadPedido? prioridad;

      if (s.cantidad == 0) {
        prioridad = PrioridadPedido.alta;
      } else if (s.formato == '50gr') {
        if (s.cantidad < 10) {
          prioridad = PrioridadPedido.media;
        } else if (s.cantidad < 20) {
          prioridad = PrioridadPedido.baja;
        }
      } else if (s.formato == '100gr') {
        if (s.cantidad < 2) prioridad = PrioridadPedido.media;
      } else if (s.formato == '200gr') {
        final umbral = (s.nombre == 'Magic Love' || s.nombre == 'Snowy Fucsia Green') ? 10 : 5;
        if (s.cantidad < umbral) prioridad = PrioridadPedido.media;
      }

      if (prioridad != null) {
        lista.add(ItemPedido(nombre: s.nombre, esSabor: true, prioridad: prioridad));
      }
    }

    lista.sort((a, b) => _ordenPrioridad(a.prioridad).compareTo(_ordenPrioridad(b.prioridad)));
    return lista;
  }

  int _ordenPrioridad(PrioridadPedido p) => p.index;

  Color _colorPrioridad(PrioridadPedido p) {
    switch (p) {
      case PrioridadPedido.alta:   return Colors.redAccent;
      case PrioridadPedido.media:  return Colors.orange;
      case PrioridadPedido.baja:   return Colors.amber;
      case PrioridadPedido.manual: return Colors.blueGrey;
    }
  }

  String _labelPrioridad(PrioridadPedido p) {
    switch (p) {
      case PrioridadPedido.alta:   return 'ALTA';
      case PrioridadPedido.media:  return 'MEDIA';
      case PrioridadPedido.baja:   return 'BAJA';
      case PrioridadPedido.manual: return 'MANUAL';
    }
  }

  void _dialogoAnadir() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => _BottomSheetAnadir(
        articulos: _articulosCache,
        saboresData: _saboresCache,
        yaEnLista: {..._manuales.map((e) => e.nombre)},
        onAnadir: (nombre, esSabor) {
          setState(() {
            _manuales.add(ItemPedido(
              nombre: nombre,
              esSabor: esSabor,
              prioridad: PrioridadPedido.manual,
            ));
          });
        },
      ),
    );
  }

  Future<void> _confirmarPedido(List<ItemPedido> todos) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar pedido'),
        content: Builder(builder: (context) {
          final conCantidad =
              todos.where((i) => (_cantidades[i.nombre] ?? 0) > 0).length;
          return Text(conCantidad == 0
              ? 'No hay artículos con cantidad mayor a 0.'
              : '¿Guardar este pedido con $conCantidad artículo${conCantidad == 1 ? '' : 's'}?');
        }),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('CANCELAR')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('CONFIRMAR',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final itemsAGuardar = todos
        .where((i) => (_cantidades[i.nombre] ?? 0) > 0)
        .map((i) => {
              'nombre': i.nombre,
              'esSabor': i.esSabor,
              'prioridad': i.prioridad.name,
              'cantidad': _cantidades[i.nombre]!,
            })
        .toList();

    if (itemsAGuardar.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Añade cantidades antes de confirmar')));
      }
      return;
    }

    await StockService.guardarPedido(
      operador: usuarioActual?['nombre'] ?? '?',
      items: itemsAGuardar,
    );

    if (mounted) {
      setState(() {
        _manuales.clear();
        _cantidades.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Pedido guardado en historial')));
    }
  }

  Widget _buildCard(ItemPedido item) {
    final color = _colorPrioridad(item.prioridad);
    final esManual = item.prioridad == PrioridadPedido.manual;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _chip(_labelPrioridad(item.prioridad), color),
                              if (item.esSabor) ...[
                                const SizedBox(width: 6),
                                _chip('SABOR', Colors.indigo),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(item.nombre,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 62,
                      child: TextFormField(
                        key: Key('ped_${item.nombre}'),
                        initialValue: '${_cantidades[item.nombre] ?? 0}',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                            isDense: true, border: OutlineInputBorder()),
                        onChanged: (v) =>
                            _cantidades[item.nombre] = int.tryParse(v) ?? 0,
                      ),
                    ),
                    if (esManual) ...[
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() =>
                            _manuales.removeWhere((m) => m.nombre == item.nombre)),
                      ),
                    ] else
                      const SizedBox(width: 44),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color, width: 1),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      );

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return Scaffold(
      appBar: AppBar(title: const Text('PEDIDO')),
      floatingActionButton: FloatingActionButton(
        onPressed: _dialogoAnadir,
        backgroundColor: Colors.blueGrey,
        tooltip: 'Añadir manualmente',
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: StockService.articulosStream(),
        builder: (context, snapArt) {
          return StreamBuilder<DocumentSnapshot>(
            stream: StockService.saboresStream(),
            builder: (context, snapSab) {
              if (!snapArt.hasData || !snapSab.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              _articulosCache = snapArt.data!.exists
                  ? snapArt.data!.data() as Map<String, dynamic>
                  : {};
              _saboresCache = snapSab.data!.exists
                  ? snapSab.data!.data() as Map<String, dynamic>
                  : {};

              final sugerencias = _calcularSugerencias(_articulosCache, _saboresCache);
              final nombresSugeridos = sugerencias.map((e) => e.nombre).toSet();
              final manualesFiltrados =
                  _manuales.where((m) => !nombresSugeridos.contains(m.nombre)).toList();

              final todos = [...sugerencias, ...manualesFiltrados];
              todos.sort((a, b) =>
                  _ordenPrioridad(a.prioridad).compareTo(_ordenPrioridad(b.prioridad)));

              if (todos.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 64),
                      SizedBox(height: 16),
                      Text('Todo el stock está en orden',
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('Usa + para añadir artículos manualmente',
                          style: TextStyle(fontSize: 13, color: Colors.white38)),
                    ],
                  ),
                );
              }

              Widget listView = ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: todos.length,
                itemBuilder: (context, i) => _buildCard(todos[i]),
              );

              final Widget lista = dt
                  ? Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(width: sw * 0.6, child: listView))
                  : listView;

              return Column(
                children: [
                  Expanded(child: lista),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1A1A1A),
                      border: Border(top: BorderSide(color: Colors.white10)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmarPedido(todos),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange),
                        icon: const Icon(Icons.check, color: Colors.white),
                        label: const Text('CONFIRMAR PEDIDO',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2)),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Bottom sheet para añadir manualmente ────────────────────────────────────

class _BottomSheetAnadir extends StatefulWidget {
  final Map<String, dynamic> articulos;
  final Map<String, dynamic> saboresData;
  final Set<String> yaEnLista;
  final void Function(String nombre, bool esSabor) onAnadir;

  const _BottomSheetAnadir({
    required this.articulos,
    required this.saboresData,
    required this.yaEnLista,
    required this.onAnadir,
  });

  @override
  State<_BottomSheetAnadir> createState() => _BottomSheetAnadirState();
}

class _BottomSheetAnadirState extends State<_BottomSheetAnadir>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articulosFiltrados = widget.articulos.keys
        .where((k) =>
            !widget.yaEnLista.contains(k) &&
            k.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList()
      ..sort();

    final saboresFiltrados = widget.saboresData.entries
        .map((e) => Sabor.fromEntry(e.key, e.value))
        .where((s) =>
            !widget.yaEnLista.contains(s.nombre) &&
            s.nombre.toLowerCase().contains(_busqueda.toLowerCase()))
        .toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.92,
      builder: (c, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tab,
            tabs: const [Tab(text: 'ARTÍCULOS'), Tab(text: 'SABORES')],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _busqueda = v),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                ListView.builder(
                  controller: scroll,
                  itemCount: articulosFiltrados.length,
                  itemBuilder: (c, i) => ListTile(
                    leading: const Icon(Icons.inventory_2, color: Colors.amber),
                    title: Text(articulosFiltrados[i]),
                    onTap: () {
                      widget.onAnadir(articulosFiltrados[i], false);
                      Navigator.pop(c);
                    },
                  ),
                ),
                ListView.builder(
                  itemCount: saboresFiltrados.length,
                  itemBuilder: (c, i) {
                    final s = saboresFiltrados[i];
                    return ListTile(
                      leading: const Icon(Icons.local_fire_department,
                          color: Colors.indigo),
                      title: Text(s.nombre),
                      subtitle: s.marca.isNotEmpty
                          ? Text('${s.marca}  ·  ${s.formato}',
                              style: const TextStyle(fontSize: 11))
                          : null,
                      onTap: () {
                        widget.onAnadir(s.nombre, true);
                        Navigator.pop(c);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
