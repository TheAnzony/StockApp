import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../session.dart';
import '../services/stock_service.dart';
import 'menu_principal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      setState(() => _version = 'v${info.version}');
    });
  }

  int _obtenerPrioridad(String rol) {
    switch (rol.toLowerCase()) {
      case 'admin':
        return 1;
      case 'encargado':
        return 2;
      case 'trabajador':
        return 3;
      default:
        return 4;
    }
  }

  void _mostrarTeclado(BuildContext context, DocumentSnapshot doc) {
    String pinIntroducido = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void agregarNum(String n) =>
                setModalState(() => pinIntroducido += n);
            void borrarUno() => setModalState(() {
                  if (pinIntroducido.isNotEmpty) {
                    pinIntroducido =
                        pinIntroducido.substring(0, pinIntroducido.length - 1);
                  }
                });
            return Container(
              padding: const EdgeInsets.all(20),
              height: MediaQuery.of(context).size.height * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(doc['nombre'].toString().toUpperCase(),
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent)),
                    const SizedBox(height: 20),
                    Container(
                      height: 70,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          pinIntroducido.isEmpty
                              ? "----"
                              : "*" * pinIntroducido.length,
                          style: const TextStyle(
                              fontSize: 45,
                              letterSpacing: 10,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 30),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      mainAxisSpacing: 15,
                      crossAxisSpacing: 15,
                      childAspectRatio: 1.4,
                      children: [
                        for (var i = 1; i <= 9; i++)
                          _btnN(i.toString(), () => agregarNum(i.toString())),
                        _btnI(Icons.close, Colors.red,
                            () => Navigator.pop(context)),
                        _btnN("0", () => agregarNum("0")),
                        _btnI(Icons.backspace, Colors.orange, borrarUno),
                        _btnN("C",
                            () => setModalState(() => pinIntroducido = ""),
                            color: Colors.blueGrey),
                        const SizedBox.shrink(),
                        _btnI(Icons.check_circle, Colors.green, () {
                          if (pinIntroducido == doc['pin'].toString()) {
                            usuarioActual = {
                              'nombre': doc['nombre'],
                              'rol': doc['rol'],
                              'id': doc.id,
                            };
                            Navigator.pop(context);
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MenuPrincipal()));
                          } else {
                            setModalState(() => pinIntroducido = "");
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('❌ PIN INCORRECTO'),
                                    backgroundColor: Colors.red));
                          }
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _btnN(String t, VoidCallback onTap, {Color? color}) => ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: color ?? const Color(0xFF333333),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: onTap,
      child: Text(t,
          style:
              const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)));

  Widget _btnI(IconData i, Color c, VoidCallback onTap) => ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: c.withOpacity(0.15),
          side: BorderSide(color: c),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
      onPressed: onTap,
      child: Icon(i, color: c, size: 30));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: StockService.trabajadoresStream(activo: true),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          List<DocumentSnapshot> usuarios = snapshot.data!.docs;
          usuarios.sort((a, b) {
            int pA = _obtenerPrioridad(a['rol'] ?? 'trabajador');
            int pB = _obtenerPrioridad(b['rol'] ?? 'trabajador');
            if (pA != pB) return pA.compareTo(pB);
            return a['nombre']
                .toString()
                .toLowerCase()
                .compareTo(b['nombre'].toString().toLowerCase());
          });
          return Column(
            children: [
              const SizedBox(height: 100),
              const Icon(Icons.nightlife, size: 80, color: Colors.blueAccent),
              const SizedBox(height: 20),
              const Text('CONTROL DE ACCESO',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    var user = usuarios[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading:
                            const Icon(Icons.person, color: Colors.blueGrey),
                        title: Text(user['nombre'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(user['rol'].toString().toUpperCase()),
                        onTap: () => _mostrarTeclado(context, user),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _version,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
