Map<String, dynamic>? usuarioActual;

bool esHorarioOficial() {
  final ahora = DateTime.now();
  return ahora.weekday == DateTime.sunday && ahora.hour >= 5 && ahora.hour < 12;
}
