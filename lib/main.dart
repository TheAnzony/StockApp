import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/update_required_screen.dart';
import 'services/version_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  @override
  void initState() {
    super.initState();
    _checkVersion();
  }

  Future<void> _checkVersion() async {
    final required = await VersionService.isUpdateRequired();
    setState(() {
      _updateRequired = required;
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
    return const LoginScreen();
  }
}
