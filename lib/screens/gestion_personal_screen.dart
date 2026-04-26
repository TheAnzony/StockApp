import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/stock_service.dart';
import '../services/auth_service.dart';

class GestionPersonalScreen extends StatelessWidget {
  const GestionPersonalScreen({super.key});

  void _dialogoCambiarPin(BuildContext context, String email) {
    final pinCtrl = TextEditingController();
    bool guardando = false;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, st) => AlertDialog(
          title: const Text('Cambiar PIN'),
          content: TextField(
            controller: pinCtrl,
            decoration: const InputDecoration(
              labelText: 'Nuevo PIN',
              helperText: '4 dígitos numéricos',
              prefixIcon: Icon(Icons.lock_reset),
            ),
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
          ),
          actions: [
            TextButton(
              onPressed: guardando ? null : () => Navigator.pop(c),
              child: const Text('CANCELAR'),
            ),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (pinCtrl.text.trim().length != 4) return;
                      st(() => guardando = true);
                      try {
                        await AuthService.cambiarPin(email, pinCtrl.text.trim());
                        if (context.mounted) {
                          Navigator.pop(c);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('PIN actualizado')),
                          );
                        }
                      } catch (ex) {
                        st(() => guardando = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $ex'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: guardando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }

  void _dialogo(BuildContext context, {DocumentSnapshot? doc}) {
    final n = TextEditingController(text: doc?['nombre'] ?? '');
    final p = TextEditingController();
    final docData = doc != null ? (doc.data() as Map<String, dynamic>? ?? {}) : <String, dynamic>{};
    final e = TextEditingController(
        text: doc != null
            ? (docData['email_auth'] as String? ?? '').replaceAll('@stockapp.com', '')
            : '');
    String r = doc?['rol'] ?? 'trabajador';
    bool guardando = false;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, st) {
          // Reconstruir preview cuando cambia el campo email
          e.addListener(() => st(() {}));

          final prefijoActual = e.text.trim().toLowerCase();
          final emailCompleto = prefijoActual.isNotEmpty
              ? '$prefijoActual@stockapp.com'
              : null;

          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(doc == null ? 'Nuevo Miembro' : 'Editar'),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: guardando ? null : () => Navigator.pop(c),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // ── Nombre visible en el menú ──────────────────────────────
                TextField(
                  controller: n,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    helperText: 'Nombre que aparece en el menú de acceso',
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                // PIN solo se pide al crear — no se almacena en Firestore
                if (doc == null) ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: p,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      helperText: '4 dígitos numéricos',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 4),
                // ── Email único ────────────────────────────────────────────
                TextField(
                  controller: e,
                  enabled: doc == null,
                  decoration: InputDecoration(
                    labelText: 'Identificador único',
                    helperText: doc == null
                        ? 'Nombre + iniciales apellidos. Ej: antonioGM'
                        : 'No editable tras la creación',
                    prefixIcon: const Icon(Icons.alternate_email),
                    suffixText: '@stockapp.com',
                    suffixStyle: TextStyle(
                      color: doc == null ? Colors.blueAccent : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  // Solo letras y números, sin espacios
                  onChanged: (_) => st(() {}),
                ),
                // Preview del email completo
                if (doc == null && emailCompleto != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.email, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            emailCompleto,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // ── Rol ────────────────────────────────────────────────────
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        size: 20, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButton<String>(
                        value: r,
                        isExpanded: true,
                        underline: const Divider(height: 1),
                        items: ['trabajador', 'encargado', 'admin']
                            .map((v) => DropdownMenuItem(
                                value: v, child: Text(v.toUpperCase())))
                            .toList(),
                        onChanged: (v) => st(() => r = v!),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: guardando ? null : () => Navigator.pop(c),
                child: const Text('CANCELAR'),
              ),
              // Cambiar PIN solo disponible al editar un trabajador existente
              if (doc != null)
                TextButton.icon(
                  icon: const Icon(Icons.lock_reset, size: 18),
                  label: const Text('CAMBIAR PIN'),
                  onPressed: guardando
                      ? null
                      : () => _dialogoCambiarPin(context, docData['email_auth'] as String? ?? ''),
                ),
              ElevatedButton(
                onPressed: guardando
                    ? null
                    : () async {
                        final esNuevo = doc == null;
                        if (n.text.trim().isEmpty) return;
                        if (esNuevo && p.text.trim().isEmpty) return;

                        st(() => guardando = true);

                        final data = {
                          'nombre': n.text.trim(),
                          'rol': r,
                          'activo': doc?['activo'] ?? true,
                        };

                        try {
                          if (esNuevo) {
                            final prefijo = e.text.trim().toLowerCase();
                            if (prefijo.isEmpty) {
                              st(() => guardando = false);
                              return;
                            }
                            final email = '$prefijo@stockapp.com';
                            data['email_auth'] = email;

                            await AuthService.crearUsuarioAuth(
                                email, p.text.trim());
                            await StockService.addTrabajador(data);
                          } else {
                            await StockService.updateTrabajador(
                                doc.reference, data);
                          }
                          if (context.mounted) Navigator.pop(c);
                        } catch (ex) {
                          st(() => guardando = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $ex'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('GUARDAR'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final bool dt = sw > 600;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('STAFF'),
          bottom: const TabBar(
              tabs: [Tab(text: 'ACTIVOS'), Tab(text: 'INACTIVOS')]),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _dialogo(context),
          child: const Icon(Icons.person_add),
        ),
        body: dt
            ? Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: sw * 0.6,
                  child: TabBarView(
                      children: [_lista(context, true), _lista(context, false)]),
                ))
            : TabBarView(
                children: [_lista(context, true), _lista(context, false)]),
      ),
    );
  }

  Widget _lista(BuildContext context, bool activo) => StreamBuilder(
        stream: StockService.trabajadoresStream(activo: activo),
        builder: (context, AsyncSnapshot<QuerySnapshot> sn) {
          if (!sn.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final l = sn.data!.docs.toList()
            ..sort((a, b) =>
                a['nombre'].toString().compareTo(b['nombre'].toString()));
          return ListView(
            children: l.map((t) {
              final d = t.data() as Map<String, dynamic>? ?? {};
              final rol = (d['rol'] ?? '').toString();
              final email = d['email_auth'] as String? ?? '';
              final colorRol = rol == 'admin'
                  ? Colors.red
                  : rol == 'encargado'
                      ? Colors.amber
                      : Colors.green;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorRol,
                  child: Text(
                    (d['nombre'] as String? ?? '?')[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(d['nombre'] ?? ''),
                subtitle: Text('${rol.toUpperCase()} | $email'),
                onTap: () => _dialogo(context, doc: t),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (opcion) async {
                    switch (opcion) {
                      case 'pin':
                        if (email.isNotEmpty) {
                          _dialogoCambiarPin(context, email);
                        }
                        break;
                      case 'baja':
                        await StockService.updateTrabajador(
                            t.reference, {'activo': false});
                        break;
                      case 'alta':
                        await StockService.updateTrabajador(
                            t.reference, {'activo': true});
                        break;
                      case 'eliminar':
                        final confirmar = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Eliminar trabajador'),
                            content: Text(
                                '¿Seguro que quieres eliminar a ${d['nombre']}?\nEsta acción no se puede deshacer.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('CANCELAR'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('ELIMINAR'),
                              ),
                            ],
                          ),
                        );
                        if (confirmar == true) {
                          await StockService.deleteTrabajador(t.reference);
                        }
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'pin',
                      child: ListTile(
                        leading: Icon(Icons.lock_reset),
                        title: Text('Editar PIN'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (activo)
                      const PopupMenuItem(
                        value: 'baja',
                        child: ListTile(
                          leading: Icon(Icons.person_remove,
                              color: Colors.orange),
                          title: Text('Dar de baja'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'alta',
                        child: ListTile(
                          leading: Icon(Icons.person_add,
                              color: Colors.green),
                          title: Text('Dar de alta'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: ListTile(
                        leading: Icon(Icons.delete_forever, color: Colors.red),
                        title: Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      );
}
