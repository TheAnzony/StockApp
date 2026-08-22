class Ingrediente {
  final String nombre;
  final int porcentaje;
  const Ingrediente(this.nombre, this.porcentaje);
}

class Receta {
  final String nombre;
  final List<Ingrediente> ingredientes;
  const Receta(this.nombre, this.ingredientes);
}

class CartaConstants {
  static const List<Receta> recetas = [
    Receta('Cítrica', [
      Ingrediente('Yellow', 90),
      Ingrediente('Polar freeze', 10),
    ]),
    Receta('Batido de Menta', [
      Ingrediente('Polar freeze', 10),
      Ingrediente('Green velvet', 40),
      Ingrediente('Big Green', 40),
      Ingrediente('Ivory gold', 10),
    ]),
    Receta('Frutos Rojos', [
      Ingrediente('Exotic escape (Alfaker)', 60),
      Ingrediente('Snowy Fucsia Green (Alfaker)', 40),
    ]),
    Receta('Tropical Vibes', [
      Ingrediente('Tropic Treat (Alfaker)', 20),
      Ingrediente('Sexy Sheba (SK)', 40),
      Ingrediente('Magic Love (Alfaker)', 40),
    ]),
    Receta('Paraíso Frutal', [
      Ingrediente('Magic Love (Alfaker)', 100),
    ]),
    Receta('Dulce', [
      Ingrediente('Happy hound (SK)', 100),
    ]),
    Receta('Sandía Melón', [
      Ingrediente('Plata o plomo (SK)', 50),
      Ingrediente('Malone (Dozaj)', 50),
    ]),
    Receta('Floral', [
      Ingrediente('Yellow', 40),
      Ingrediente('Grapio Green', 40),
      Ingrediente('Japanise Sunrise', 20),
    ]),
  ];

  static List<String> get saboresUnicos {
    final Set<String> vistos = {};
    final List<String> result = [];
    for (final r in recetas) {
      for (final i in r.ingredientes) {
        if (vistos.add(i.nombre)) result.add(i.nombre);
      }
    }
    result.sort();
    return result;
  }
}
