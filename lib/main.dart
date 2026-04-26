import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'firebase_options_beta.dart';
import 'screens/login_screen.dart';
import 'screens/menu_principal.dart';
import 'screens/update_required_screen.dart';
import 'services/version_service.dart';
import 'services/auth_service.dart';
import 'services/session_service.dart';
import 'session.dart';

const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final options = _flavor == 'beta'
      ? BetaFirebaseOptions.currentPlatform
      : DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: options);
  await AuthService.configurarPersistencia();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StockApp',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardTheme: const CardThemeData(color: Color(0xFF1E1E1E)),
      ),
      home: const VersionGate(),
    );
  }
}

class VersionGate extends StatefulWidget {
  const VersionGate({super.key});

  @override
  State<VersionGate> createState() => _VersionGateState();
}

class _VersionGateState extends State<VersionGate> {
  bool _checking = true;
  bool _updateRequired = false;
  bool _sessionRestored = false;

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final required = await VersionService.isUpdateRequired();
    bool restored = false;

    if (!required) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final valid = await SessionService.isSessionValid();
        if (valid) {
          final info = await SessionService.loadUserInfo();
          if (info != null) {
            usuarioActual = info;
            restored = true;
          } else {
            await AuthService.signOut();
            await SessionService.clear();
          }
        } else {
          await AuthService.signOut();
          await SessionService.clear();
        }
      }
    }

    setState(() {
      _updateRequired = required;
      _sessionRestored = restored;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_updateRequired) return const UpdateRequiredScreen();
    if (_sessionRestored) return const MenuPrincipal();
    return const LoginScreen();
  }
}
