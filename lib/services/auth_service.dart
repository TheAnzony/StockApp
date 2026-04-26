import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static String _password(String pin) => '${pin}00';

  static Future<void> configurarPersistencia() async {
    if (kIsWeb) {
      await _auth.setPersistence(Persistence.LOCAL);
    }
  }

  static Future<bool> login(String emailAuth, String pin) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: emailAuth,
        password: _password(pin),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> cambiarPin(String email, String nuevoPin) async {
    final fn = FirebaseFunctions.instanceFor(region: 'europe-west1')
        .httpsCallable('cambiarPin');
    await fn.call({'email': email, 'nuevoPin': nuevoPin});
  }

  // Crea un usuario en Firebase Auth usando una app secundaria para no
  // cerrar la sesión del admin actual.
  static Future<void> crearUsuarioAuth(String email, String pin) async {
    final appName = 'tmp_${email.replaceAll(RegExp(r'[@.]'), '_')}';
    final secondaryApp = await Firebase.initializeApp(
      name: appName,
      options: Firebase.app().options,
    );
    try {
      await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
        email: email,
        password: _password(pin),
      );
    } finally {
      await secondaryApp.delete();
    }
  }
}
