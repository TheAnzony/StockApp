class Configuracion {
  final bool stockForzado;

  Configuracion({required this.stockForzado});

  factory Configuracion.fromMap(Map<String, dynamic> map) =>
      Configuracion(stockForzado: map['stock_forzado'] ?? false);

  Map<String, dynamic> toMap() => {'stock_forzado': stockForzado};
}
