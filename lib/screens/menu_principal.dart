import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../session.dart';
import '../services/stock_service.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import 'login_screen.dart';
import 'inventario_screen.dart';
import 'recibidos_screen.dart';
import 'roturas_screen.dart';
import 'prestado_screen.dart';
import 'historial_seleccion_screen.dart';
import 'gestion_catalogo_screen.dart';
import 'gestion_personal_screen.dart';
import 'configuracion_screen.dart';
import 'carta_screen.dart';

class MenuPrincipal extends StatefulWidget {
  const MenuPrincipal({super.key});

  @override
  State<MenuPrincipal> createState() => _MenuPrincipalState();
}

class _MenuPrincipalState extends State<MenuPrincipal> {
  @override
  void initState() {
    super.initState();
    SessionService.onTimeout = _autoLogout;
    SessionService.startTimer();
  }

  @override
  void dispose() {
    SessionService.cancelTimer();
    super.dispose();
  }

  Future<void> _autoLogout() async {
    await AuthService.signOut();
    await SessionService.clear();
    usuarioActual = null;
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  Future<bool?> _dialogoCerrarSesion(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Seguro que quieres cerrar la sesión?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('NO')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('SÍ, SALIR'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String rol = usuarioActual?['rol'] ?? 'trabajador';
    final bool isAdmin = rol == 'admin';
    final bool esEncargado = rol == 'encargado';

    return Listener(
      onPointerDown: (_) => SessionService.updateActivity(),
      child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final salir = await _dialogoCerrarSesion(context);
        if (salir == true && context.mounted) {
          await AuthService.signOut();
          await SessionService.clear();
          usuarioActual = null;
          if (context.mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginScreen()));
          }
        }
      },
      child: StreamBuilder<DocumentSnapshot>(
        stream: StockService.configuracionStream(),
        builder: (context, snapConfig) {
          bool stockForzado = false;
          if (snapConfig.hasData && snapConfig.data!.exists) {
            stockForzado = snapConfig.data!['stock_forzado'] ?? false;
          }
          final bool puedeHacerStock = esHorarioOficial() || stockForzado;

          final double screenWidth = MediaQuery.of(context).size.width;
          final bool esEscritorio = screenWidth > 600;

          final grid = Padding(
            padding: const EdgeInsets.all(20.0),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: esEscritorio ? 2.8 : 1.0,
              children: [
                _btn(context, 'VER STOCK', Icons.inventory, Colors.blue,
                    const InventarioScreen(modoEdicion: false), esEscritorio: esEscritorio),
                if (puedeHacerStock && (isAdmin || esEncargado))
                  _btn(context, 'REALIZAR STOCK', Icons.fact_check,
                      Colors.cyan, const InventarioScreen(modoEdicion: true), esEscritorio: esEscritorio),
                _btn(context, 'CARTA', Icons.menu_book, Colors.indigo,
                    const CartaScreen(), esEscritorio: esEscritorio),
                _btn(context, 'RECIBIDO', Icons.download, Colors.green,
                    const RecibidosScreen(), esEscritorio: esEscritorio),
                _btn(context, 'ROTURAS', Icons.report_problem, Colors.red,
                    const RoturasScreen(), esEscritorio: esEscritorio),
                _btn(context, 'PRESTADO', Icons.swap_horiz, Colors.orange,
                    const PrestadoScreen(), esEscritorio: esEscritorio),
                if (isAdmin || esEncargado)
                  _btn(context, 'HISTORIALES', Icons.assignment,
                      Colors.purple, const SeleccionHistorialScreen(), esEscritorio: esEscritorio),
                if (isAdmin) ...[
                  _btn(context, 'CATÁLOGO', Icons.shopping_cart, Colors.amber,
                      const GestionCatalogoScreen(), esEscritorio: esEscritorio),
                  _btn(context, 'GESTIÓN STAFF', Icons.admin_panel_settings,
                      Colors.teal, const GestionPersonalScreen(), esEscritorio: esEscritorio),
                ],
              ],
            ),
          );

          return Scaffold(
            appBar: AppBar(
              title: const Text('PANEL DE CONTROL'),
              actions: [
                if (isAdmin)
                  IconButton(
                    icon: const Icon(Icons.settings, color: Colors.blueGrey),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ConfiguracionSistemaScreen())),
                  ),
                IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () async {
                      final salir = await _dialogoCerrarSesion(context);
                      if (salir == true && context.mounted) {
                        await AuthService.signOut();
                        await SessionService.clear();
                        usuarioActual = null;
                        if (context.mounted) {
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                        }
                      }
                    }),
              ],
            ),
            body: esEscritorio
                ? Center(
                    child: SizedBox(
                      width: screenWidth * 0.6,
                      child: grid,
                    ),
                  )
                : grid,
          );
        },
      ),
    ),   // PopScope
    );   // Listener
  }

  Widget _btn(
          BuildContext context, String titulo, IconData icono, Color color, Widget destino,
          {bool esEscritorio = false}) =>
      InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => destino)),
        child: Container(
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color, width: 2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, size: esEscritorio ? 28 : 40, color: color),
              const SizedBox(width: 10),
              Text(titulo,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: esEscritorio ? 14 : 13)),
            ],
          ),
        ),
      );
}
