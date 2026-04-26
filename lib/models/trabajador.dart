import '../constants/constants.dart';

class Trabajador {
  final String id;
  final String nombre;
  final String emailAuth;
  final RolUsuario rol;
  final bool activo;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.emailAuth,
    required this.rol,
    required this.activo,
  });

  factory Trabajador.fromMap(Map<String, dynamic> map, String id) {
    return Trabajador(
      id: id,
      nombre: map['nombre'] ?? '',
      emailAuth: map['email_auth'] ?? '',
      rol: RolUsuario.fromString(map['rol'] ?? 'trabajador'),
      activo: map['activo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'email_auth': emailAuth,
        'rol': rol.label,
        'activo': activo,
      };
}
