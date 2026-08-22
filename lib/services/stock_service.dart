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
  }) async {
    final nuevo = nombreNuevo.trim();
    if (nuevo == nombreViejo) {
      return _saboresRef.update({
        '$nombreViejo.marca': marca.trim(),
        '$nombreViejo.formato': formato.trim(),
      });
    }

    final batch = _db.batch();
    batch.update(_saboresRef, {
      nombreViejo: FieldValue.delete(),
      nuevo: {'marca': marca.trim(), 'formato': formato.trim(), 'cantidad': cantidad},
    });

    // Rebranding en cascada: si el sabor aparece como ingrediente en alguna
    // mezcla de la Carta, se actualiza su nombre ahí también.
    final mezclasSnap = await _mezclasRef.get();
    if (mezclasSnap.exists) {
      final data = mezclasSnap.data() as Map<String, dynamic>;
      final recetas = (data['recetas'] as List?) ?? [];
      bool cambiado = false;
      final nuevasRecetas = recetas.map((r) {
        final receta = Map<String, dynamic>.from(r as Map);
        final ingredientes = ((receta['ingredientes'] as List?) ?? [])
            .map((i) {
          final ing = Map<String, dynamic>.from(i as Map);
          if (ing['nombre'] == nombreViejo) {
            ing['nombre'] = nuevo;
            cambiado = true;
          }
          return ing;
        }).toList();
        receta['ingredientes'] = ingredientes;
        return receta;
      }).toList();
      if (cambiado) {
        batch.update(_mezclasRef, {'recetas': nuevasRecetas});
      }
    }

    await batch.commit();
  }

  // ── Mezclas (Carta) ───────────────────────────────────────────────────────

  static DocumentReference get _mezclasRef =>
      _db.collection(FirebaseCollections.articulos).doc('mezclas');

  static Stream<DocumentSnapshot> mezclasStream() => _mezclasRef.snapshots();

  static DocumentReference mezclasRef() => _mezclasRef;

  static Future<void> addMezcla(
          String nombre, List<Map<String, dynamic>> ingredientes) =>
      _mezclasRef.set({
        'recetas': FieldValue.arrayUnion([
          {'nombre': nombre.trim(), 'ingredientes': ingredientes}
        ])
      }, SetOptions(merge: true));

  static Future<void> deleteMezcla(Map<String, dynamic> receta) =>
      _mezclasRef.update({
        'recetas': FieldValue.arrayRemove([receta])
      });

  static Future<void> updateMezcla({
    required String nombreViejo,
    required String nombreNuevo,
    required List<Map<String, dynamic>> ingredientes,
  }) {
    return _db.runTransaction((tx) async {
      final snap = await tx.get(_mezclasRef);
      final data = snap.data() as Map<String, dynamic>? ?? {};
      final recetas = ((data['recetas'] as List?) ?? [])
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      final index = recetas.indexWhere((r) => r['nombre'] == nombreViejo);
      final nuevaReceta = {
        'nombre': nombreNuevo.trim(),
        'ingredientes': ingredientes,
      };
      if (index >= 0) {
        recetas[index] = nuevaReceta;
      } else {
        recetas.add(nuevaReceta);
      }
      tx.update(_mezclasRef, {'recetas': recetas});
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

  static Future<void> actualizarPedido(
          DocumentReference ref, List<Map<String, dynamic>> items) =>
      ref.update({'items': items});

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
