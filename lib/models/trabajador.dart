import '../constants/constants.dart';

class Trabajador {
  final String id;
  final String nombre;
  final String pin;
  final RolUsuario rol;
  final bool activo;

  Trabajador({
    required this.id,
    required this.nombre,
    required this.pin,
    required this.rol,
    required this.activo,
  });

  factory Trabajador.fromMap(Map<String, dynamic> map, String id) {
    return Trabajador(
      id: id,
      nombre: map['nombre'] ?? '',
      pin: map['pin'].toString(),
      rol: RolUsuario.fromString(map['rol'] ?? 'trabajador'),
      activo: map['activo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'pin': pin,
        'rol': rol.label,
        'activo': activo,
      };
}
