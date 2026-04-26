import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../session.dart';
import '../services/stock_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
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

  void _mostrarNotificacionError(BuildContext context, String mensaje) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(mensaje,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(milliseconds: 1500), entry.remove);
  }

  void _mostrarTeclado(BuildContext context, DocumentSnapshot doc) {
    String pinIntroducido = '';
    bool cargando = false;

    final bool esEscritorio = MediaQuery.of(context).size.width > 600;
    final focusNode = FocusNode();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            void agregarNum(String n) {
              if (!cargando) setModalState(() => pinIntroducido += n);
            }

            void borrarUno() {
              if (!cargando && pinIntroducido.isNotEmpty) {
                setModalState(() => pinIntroducido =
                    pinIntroducido.substring(0, pinIntroducido.length - 1));
              }
            }

            Future<void> verificar() async {
              if (cargando || pinIntroducido.isEmpty) return;

              final data = doc.data() as Map<String, dynamic>? ?? {};
              final emailAuth = data['email_auth'] as String? ?? '';
              if (emailAuth.isEmpty) {
                _mostrarNotificacionError(context, 'SIN EMAIL_AUTH');
                return;
              }

              setModalState(() => cargando = true);

              final ok = await AuthService.login(emailAuth, pinIntroducido);

              if (!modalContext.mounted) return;

              if (ok) {
                final info = {
                  'nombre': doc['nombre'],
                  'rol': doc['rol'],
                  'id': doc.id,
                };
                usuarioActual = info;
                await SessionService.saveUserInfo(info);
                if (!modalContext.mounted) return;
                Navigator.pop(modalContext);
                if (context.mounted) {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const MenuPrincipal()));
                }
              } else {
                setModalState(() {
                  cargando = false;
                  pinIntroducido = '';
                });
                _mostrarNotificacionError(context, 'PIN INCORRECTO');
              }
            }

            Widget teclado = Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(doc['nombre'].toString().toUpperCase(),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent)),
                  const SizedBox(height: 12),
                  Container(
                    height: 58,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16)),
                    child: cargando
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 3))
                        : Text(
                            pinIntroducido.isEmpty
                                ? '----'
                                : '*' * pinIntroducido.length,
                            style: const TextStyle(
                                fontSize: 38,
                                letterSpacing: 10,
                                color: Colors.white)),
                  ),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                    children: [
                      for (var i = 1; i <= 9; i++)
                        _btnN(i.toString(), () => agregarNum(i.toString()),
                            disabled: cargando),
                      _btnI(Icons.close, Colors.red,
                          () => Navigator.pop(modalContext),
                          disabled: cargando),
                      _btnN('0', () => agregarNum('0'), disabled: cargando),
                      _btnI(Icons.backspace, Colors.orange, borrarUno,
                          disabled: cargando),
                      _btnN('C',
                          () => setModalState(() => pinIntroducido = ''),
                          color: Colors.blueGrey, disabled: cargando),
                      const SizedBox.shrink(),
                      _btnI(Icons.check_circle, Colors.green, verificar,
                          disabled: cargando),
                    ],
                  ),
                ],
              ),
            );

            // En escritorio capturamos el teclado físico
            final tecladoFinal = esEscritorio
                ? Focus(
                    focusNode: focusNode,
                    autofocus: true,
                    onKeyEvent: (_, event) {
                      if (event is! KeyDownEvent || cargando) {
                        return KeyEventResult.ignored;
                      }
                      final k = event.logicalKey;
                      // Dígitos fila numérica y teclado numérico
                      final label = k.keyLabel;
                      if (label.length == 1 &&
                          label.codeUnitAt(0) >= 48 &&
                          label.codeUnitAt(0) <= 57) {
                        agregarNum(label);
                        return KeyEventResult.handled;
                      }
                      if (k == LogicalKeyboardKey.backspace) {
                        borrarUno();
                        return KeyEventResult.handled;
                      }
                      if (k == LogicalKeyboardKey.enter ||
                          k == LogicalKeyboardKey.numpadEnter) {
                        verificar();
                        return KeyEventResult.handled;
                      }
                      if (k == LogicalKeyboardKey.escape) {
                        Navigator.pop(modalContext);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: teclado,
                  )
                : teclado;

            if (!esEscritorio) return tecladoFinal;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: tecladoFinal,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _btnN(String t, VoidCallback onTap,
          {Color? color, bool disabled = false}) =>
      ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: color ?? const Color(0xFF333333),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: disabled ? null : onTap,
          child: Text(t,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));

  Widget _btnI(IconData i, Color c, VoidCallback onTap,
          {bool disabled = false}) =>
      ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: c.withValues(alpha: 0.15),
              side: BorderSide(color: disabled ? Colors.grey : c),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          onPressed: disabled ? null : onTap,
          child: Icon(i, color: disabled ? Colors.grey : c, size: 24));

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool esEscritorio = screenWidth > 600;

    return Scaffold(
      body: StreamBuilder(
        stream: StockService.trabajadoresStream(activo: true),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error al conectar',
                    style: TextStyle(color: Colors.red)));
          }
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

          Widget content = Column(
            children: [
              SizedBox(height: esEscritorio ? 60 : 100),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset('assets/icons/StockApp_icon.png',
                    width: esEscritorio ? 60 : 80,
                    height: esEscritorio ? 60 : 80),
              ),
              SizedBox(height: esEscritorio ? 12 : 20),
              Text('CONTROL DE ACCESO',
                  style: TextStyle(
                      fontSize: esEscritorio ? 18 : 22,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: esEscritorio ? 24 : 40),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                      horizontal: esEscritorio ? 0 : 30),
                  itemCount: usuarios.length,
                  itemBuilder: (context, index) {
                    var user = usuarios[index];
                    final rol = user['rol'].toString().toLowerCase();
                    final color = rol == 'admin'
                        ? Colors.red
                        : rol == 'encargado'
                            ? Colors.yellow
                            : Colors.cyan;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        leading: Icon(Icons.person, color: color),
                        title: Text(user['nombre'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(user['rol'].toString().toUpperCase(),
                            style: TextStyle(color: color)),
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

          if (!esEscritorio) return content;

          return Center(
            child: SizedBox(
              width: screenWidth * 0.6,
              child: content,
            ),
          );
        },
      ),
    );
  }
}
