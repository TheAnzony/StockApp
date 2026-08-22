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

  static Future<void> updateArticulo({
    required String nombreViejo,
    required String nombreNuevo,
    required int valorActual,
  }) {
    final nuevo = nombreNuevo.trim().toUpperCase();
    if (nuevo == nombreViejo) return Future.value();
    return _stockRef.update({
      nombreViejo: FieldValue.delete(),
      nuevo: valorActual,
    });
  }

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

  static Future<void> updateSabor({
    required String nombreViejo,
    required String nombreNuevo,
    required String marca,
    required String formato,
    required int cantidad,
  }) {
    final nuevo = nombreNuevo.trim();
    if (nuevo == nombreViejo) {
      return _saboresRef.update({
        '$nombreViejo.marca': marca.trim(),
        '$nombreViejo.formato': formato.trim(),
      });
    }
    return _saboresRef.update({
      nombreViejo: FieldValue.delete(),
      nuevo: {'marca': marca.trim(), 'formato': formato.trim(), 'cantidad': cantidad},
    });
  }

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

  static Future<DocumentSnapshot?> getUltimoStock() async {
    final currentId = _fechaId();
    final q = await _db
        .collection(FirebaseCollections.logsDiarios)
        .orderBy(FirebaseFields.timestamp, descending: true)
        .limit(60)
        .get();
    for (final doc in q.docs) {
      if (doc.id == currentId) continue;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (data.containsKey(FirebaseFields.stockFinal)) return doc;
    }
    return null;
  }

  static Future<void> guardarStock({
    required Map<String, int> stockAnterior,
    required Map<String, int> stockFinal,
    String? stockAnteriorId,
  }) async {
    final id = _fechaId();
    await _db.collection(FirebaseCollections.logsDiarios).doc(id).set(
      {
        FirebaseFields.fechaId: id,
        FirebaseFields.timestamp: FieldValue.serverTimestamp(),
        FirebaseFields.stockAnterior: stockAnterior,
        FirebaseFields.stockFinal: stockFinal,
        FirebaseFields.stockAnteriorId: stockAnteriorId ?? '',
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
