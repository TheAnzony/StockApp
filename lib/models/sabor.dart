class Sabor {
  final String nombre;
  final String marca;
  final String formato;
  final int cantidad;

  const Sabor({
    required this.nombre,
    required this.marca,
    required this.formato,
    required this.cantidad,
  });

  factory Sabor.fromEntry(String nombre, dynamic value) {
    if (value is Map<String, dynamic>) {
      return Sabor(
        nombre: nombre,
        marca: value['marca'] as String? ?? '',
        formato: value['formato'] as String? ?? '',
        cantidad: (value['cantidad'] as num?)?.toInt() ?? 0,
      );
    }
    return Sabor(nombre: nombre, marca: '', formato: '', cantidad: (value as num?)?.toInt() ?? 0);
  }

  Map<String, dynamic> toMap() => {
        'marca': marca,
        'formato': formato,
        'cantidad': cantidad,
      };
}
