import 'package:flutter/material.dart';
import 'historial_filtrado_screen.dart';
import 'historial_pedidos_screen.dart';

class SeleccionHistorialScreen extends StatelessWidget {
  const SeleccionHistorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    Widget bodyContent = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _item(context, 'RECIBIDOS', Colors.green, 'RECIBIDO'),
        _item(context, 'ROTURAS', Colors.red, 'ROTURAS'),
        _item(context, 'PRESTADOS', Colors.orange, 'PRESTADO'),
        _item(context, 'GENERALES', Colors.blue, 'GENERAL'),
        _itemPedidos(context),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('HISTORIALES')),
      body: dt
          ? Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: sw * 0.6, child: bodyContent))
          : bodyContent,
    );
  }

  Widget _item(BuildContext context, String titulo, Color color, String filtro) =>
      Card(
        child: ListTile(
          leading: Icon(Icons.folder, color: color),
          title: Text(titulo),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HistorialFiltradoScreen(
                      filtro: filtro, titulo: titulo))),
        ),
      );

  Widget _itemPedidos(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.shopping_cart_checkout, color: Colors.deepOrange),
          title: const Text('PEDIDOS'),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const HistorialPedidosScreen())),
        ),
      );
}
