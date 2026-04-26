import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _kLastActivity = 'last_activity';
  static const _kNombre = 'u_nombre';
  static const _kRol = 'u_rol';
  static const _kId = 'u_id';
  static const _kStockTemp = 'stock_temp';
  static const _timeout = Duration(hours: 1);

  static Timer? _timer;
  static VoidCallback? onTimeout;

  // ── Actividad ────────────────────────────────────────────────────────────────

  static Future<void> updateActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kLastActivity, DateTime.now().millisecondsSinceEpoch);
    _resetTimer();
  }

  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_kLastActivity);
    if (ts == null) return false;
    final last = DateTime.fromMillisecondsSinceEpoch(ts);
    return DateTime.now().difference(last) < _timeout;
  }

  static void startTimer() => _resetTimer();

  static void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_timeout, () => onTimeout?.call());
  }

  static void cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Info de usuario ──────────────────────────────────────────────────────────

  static Future<void> saveUserInfo(Map<String, dynamic> info) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kNombre, info['nombre'] ?? '');
    await prefs.setString(_kRol, info['rol'] ?? '');
    await prefs.setString(_kId, info['id'] ?? '');
    await prefs.setInt(_kLastActivity, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<Map<String, dynamic>?> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final nombre = prefs.getString(_kNombre);
    if (nombre == null || nombre.isEmpty) return null;
    return {
      'nombre': nombre,
      'rol': prefs.getString(_kRol) ?? 'trabajador',
      'id': prefs.getString(_kId) ?? '',
    };
  }

  // ── Conteo parcial de stock ──────────────────────────────────────────────────

  static Future<void> saveStockTemp(Map<String, int> temp) async {
    if (temp.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kStockTemp, jsonEncode(temp));
  }

  static Future<Map<String, int>?> loadStockTemp() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStockTemp);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearStockTemp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kStockTemp);
  }

  // ── Limpieza total ───────────────────────────────────────────────────────────

  static Future<void> clear() async {
    cancelTimer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLastActivity);
    await prefs.remove(_kNombre);
    await prefs.remove(_kRol);
    await prefs.remove(_kId);
  }

  // Sólo en debug — no se usa en producción
  static void debugLog(String msg) {
    if (kDebugMode) debugPrint('[SessionService] $msg');
  }
}
