import 'package:flutter/material.dart';
import 'historial_filtrado_screen.dart';

class SeleccionHistorialScreen extends StatelessWidget {
  const SeleccionHistorialScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('HISTORIALES')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _item(context, 'RECIBIDOS', Colors.green, 'RECIBIDO'),
            _item(context, 'ROTURAS', Colors.red, 'ROTURAS'),
            _item(context, 'PRESTADOS', Colors.orange, 'PRESTADO'),
            _item(context, 'GENERALES', Colors.blue, 'GENERAL'),
          ],
        ),
      );

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
}
