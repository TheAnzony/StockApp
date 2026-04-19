import '../constants/constants.dart';
import 'movimiento.dart';

class LogDiario {
  final String id;
  final DateTime fecha;
  final List<Movimiento> movimientos;
  final Map<String, int>? stockFinal;
  final Map<String, int>? fugas;

  LogDiario({
    required this.id,
    required this.fecha,
    required this.movimientos,
    this.stockFinal,
    this.fugas,
  });

  factory LogDiario.fromMap(Map<String, dynamic> map, String id) {
    final movsList = (map['movimientos'] as List?)
            ?.map((m) => Movimiento.fromMap(m as Map<String, dynamic>))
            .toList() ??
        [];
    final stockFinalMap = map['stock_final'] as Map<String, dynamic>?;
    final fugasMap = map['fugas'] as Map<String, dynamic>?;

    return LogDiario(
      id: id,
      fecha: DateTime.now(),
      movimientos: movsList,
      stockFinal: stockFinalMap?.map((k, v) => MapEntry(k, (v as num).toInt())),
      fugas: fugasMap?.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  Map<String, dynamic> toMap() => {
        'fecha_id': id,
        'timestamp': DateTime.now(),
        'movimientos': movimientos.map((m) => m.toMap()).toList(),
        if (stockFinal != null) 'stock_final': stockFinal,
        if (fugas != null) 'fugas': fugas,
      };

  bool get hayDescuadre => fugas != null && fugas!.isNotEmpty;

  List<Movimiento> get roturas =>
      movimientos.where((m) => m.motivo == MotivoMovimiento.roturas).toList();

  List<Movimiento> get altas =>
      movimientos.where((m) => m.motivo == MotivoMovimiento.alta).toList();

  List<Movimiento> get movimientosLogisticos => movimientos
      .where((m) =>
          m.motivo == MotivoMovimiento.recibido ||
          m.motivo == MotivoMovimiento.prestado)
      .toList();

  Map<String, int> calcularDescuadreReal() {
    final descuadres = <String, int>{};
    if (fugas == null) return descuadres;

    for (final entry in fugas!.entries) {
      final articulo = entry.key.toLowerCase();
      final ajuste = entry.value;

      if (articulo == ArticuloConstants.cachimbas) {
        final ajusteMastil = fugas?[ArticuloConstants.mastil] ?? 0;
        final netoCachimbas = ajuste + ajusteMastil;
        if (netoCachimbas != 0) descuadres[entry.key] = netoCachimbas;
      } else if (articulo == ArticuloConstants.mastil) {
        continue;
      } else {
        final totalRoto = roturas
            .where((m) => m.articulo == entry.key.toUpperCase())
            .fold<int>(0, (sum, m) => sum + m.cantidad);
        final neto = ajuste - totalRoto;
        if (neto != 0) descuadres[entry.key] = neto;
      }
    }

    return descuadres;
  }
}
