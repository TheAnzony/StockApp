import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/constants.dart';

class StockService {
  static final _db = FirebaseFirestore.instance;

  // ── Artículos (stock) ──────────────────────────────────────────────────────

  static DocumentReference get _stockRef =>
      _db.collection(FirebaseCollections.articulos).doc('stock');

  static Stream<DocumentSnapshot> articulosStream() => _stockRef.snapshots();

  static DocumentReference articulosRef() => _stockRef;

  static Future<void> addArticulo(String nombre) =>
      _stockRef.update({nombre.trim().toUpperCase(): 0});

  static Future<void> deleteArticulo(DocumentReference ref, String nombre) =>
      ref.update({nombre: FieldValue.delete()});

  // ── Sabores ────────────────────────────────────────────────────────────────

  static DocumentReference get _saboresRef =>
      _db.collection(FirebaseCollections.articulos).doc('sabores');

  static Stream<DocumentSnapshot> saboresStream() => _saboresRef.snapshots();

  static DocumentReference saboresRef() => _saboresRef;

  static Future<void> addSabor(
          String nombre, String marca, String formato, int cantidad) =>
      _saboresRef.set({
        nombre.trim(): {'marca': marca.trim(), 'formato': formato.trim(), 'cantidad': cantidad}
      }, SetOptions(merge: true));

  static Future<void> deleteSabor(String nombre) =>
      _saboresRef.update({nombre: FieldValue.delete()});

  // ── Logs ───────────────────────────────────────────────────────────────────

  static String _fechaId() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  static Future<void> agregarMovimientos(
      List<Map<String, dynamic>> movimientos) async {
    final id = _fechaId();
    await _db.collection(FirebaseCollections.logsDiarios).doc(id).set(
      {
        FirebaseFields.fechaId: id,
        FirebaseFields.timestamp: FieldValue.serverTimestamp(),
        FirebaseFields.movimientos: FieldValue.arrayUnion(movimientos),
      },
      SetOptions(merge: true),
    );
  }

  static Future<void> guardarStock({
    required Map<String, int> stockFinal,
    required Map<String, int> fugasRoturas,
    required Map<String, int> fugasPrestados,
    required Map<String, int> fugasDesconocido,
    required List<Map<String, dynamic>> movimientos,
  }) async {
    final id = _fechaId();
    await _db.collection(FirebaseCollections.logsDiarios).doc(id).set(
      {
        FirebaseFields.fechaId: id,
        FirebaseFields.timestamp: FieldValue.serverTimestamp(),
        FirebaseFields.movimientos: FieldValue.arrayUnion(movimientos),
        FirebaseFields.stockFinal: stockFinal,
        FirebaseFields.fugas: {
          'roturas': fugasRoturas,
          'prestados': fugasPrestados,
          'desconocido': fugasDesconocido,
        },
      },
      SetOptions(merge: true),
    );
  }

  // ── Pedidos ────────────────────────────────────────────────────────────────

  static Future<void> guardarPedido({
    required List<Map<String, dynamic>> items,
    required String operador,
  }) =>
      _db.collection(FirebaseCollections.pedidos).add({
        'fecha': FieldValue.serverTimestamp(),
        'operador': operador,
        'items': items,
      });

  static Stream<QuerySnapshot> pedidosStream() => _db
      .collection(FirebaseCollections.pedidos)
      .orderBy('fecha', descending: true)
      .snapshots();

  static Stream<QuerySnapshot> logsStream() =>
      _db
          .collection(FirebaseCollections.logsDiarios)
          .orderBy(FirebaseFields.timestamp, descending: true)
          .snapshots();

  // ── Configuración ──────────────────────────────────────────────────────────

  static Stream<DocumentSnapshot> configuracionStream() =>
      _db
          .collection(FirebaseCollections.ajustes)
          .doc(FirebaseCollections.configuracion)
          .snapshots();

  static Future<void> setStockForzado(bool value) =>
      _db
          .collection(FirebaseCollections.ajustes)
          .doc(FirebaseCollections.configuracion)
          .set({FirebaseFields.stockForzado: value}, SetOptions(merge: true));

  // ── Trabajadores ───────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> trabajadoresStream({required bool activo}) =>
      _db
          .collection(FirebaseCollections.trabajadores)
          .where(FirebaseFields.activo, isEqualTo: activo)
          .snapshots();

  static Future<void> addTrabajador(Map<String, dynamic> data) =>
      _db.collection(FirebaseCollections.trabajadores).add(data);

  static Future<void> updateTrabajador(
          DocumentReference ref, Map<String, dynamic> data) =>
      ref.update(data);

  static Future<void> deleteTrabajador(DocumentReference ref) => ref.delete();
}
