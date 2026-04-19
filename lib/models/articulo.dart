class Articulo {
  final String nombre;
  final int cantidad;

  Articulo({required this.nombre, required this.cantidad});

  factory Articulo.fromMapEntry(MapEntry<String, dynamic> entry) {
    return Articulo(
      nombre: entry.key,
      cantidad: (entry.value as num).toInt(),
    );
  }
}
