import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

class Movimiento {
  final String articulo;
  final int cantidad;
  final DateTime fecha;
  final MotivoMovimiento motivo;
  final String operador;
  final String? concepto;
  final String? destino;
  final String? origen;

  Movimiento({
    required this.articulo,
    required this.cantidad,
    required this.fecha,
    required this.motivo,
    required this.operador,
    this.concepto,
    this.destino,
    this.origen,
  });

  factory Movimiento.fromMap(Map<String, dynamic> map) {
    return Movimiento(
      articulo: map['articulo'] ?? '',
      cantidad: (map['cantidad'] as num).toInt(),
      fecha: map['fecha'] is Timestamp
          ? (map['fecha'] as Timestamp).toDate()
          : DateTime.now(),
      motivo: MotivoMovimiento.fromString(map['motivo'] ?? 'GENERAL'),
      operador: map['operador'] ?? 'Admin',
      concepto: map['concepto'],
      destino: map['destino'],
      origen: map['origen'],
    );
  }

  Map<String, dynamic> toMap() => {
        'articulo': articulo,
        'cantidad': cantidad,
        'fecha': fecha,
        'motivo': motivo.label,
        'operador': operador,
        if (concepto != null) 'concepto': concepto,
        if (destino != null) 'destino': destino,
        if (origen != null) 'origen': origen,
      };
}
