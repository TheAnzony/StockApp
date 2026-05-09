// Enums para Motivos de Movimientos
enum MotivoMovimiento {
  alta('ALTA', '🆕'),
  general('GENERAL', '📊'),
  recibido('RECIBIDO', '📥'),
  roturas('ROTURAS', '⚠️'),
  prestado('PRESTADO', '📤');

  final String label;
  final String emoji;
  
  const MotivoMovimiento(this.label, this.emoji);
  
  static MotivoMovimiento fromString(String value) {
    return MotivoMovimiento.values.firstWhere(
      (e) => e.label == value,
      orElse: () => MotivoMovimiento.general,
    );
  }
}

// Enum para Concepto de Recibidos
enum ConceptoRecibido {
  stockNuevo('STOCK NUEVO'),
  devolucionPrestado('DEVOLUCIÓN PRESTADO');

  final String label;
  
  const ConceptoRecibido(this.label);
}

// Enum para Roles
enum RolUsuario {
  admin('admin', 1),
  encargado('encargado', 2),
  trabajador('trabajador', 3);

  final String label;
  final int prioridad;
  
  const RolUsuario(this.label, this.prioridad);
  
  static RolUsuario fromString(String value) {
    return RolUsuario.values.firstWhere(
      (e) => e.label == value.toLowerCase(),
      orElse: () => RolUsuario.trabajador,
    );
  }
  
  bool get esAdmin => this == RolUsuario.admin;
  bool get esEncargado => this == RolUsuario.encargado;
  bool get puedeEditar => this == RolUsuario.admin || this == RolUsuario.encargado;
}

// Constantes de Articulos
class ArticuloConstants {
  static const List<String> itemsRoturas = [
    'cazoletas',
    'kalouds',
    'cachimbas',
    'bases',
    'hornillos',
    'boquilla mangueras',
    'punzones'
  ];
  
  static const String cachimbas = 'cachimbas';
  static const String mangueras = 'mangueras';
  static const String mastil = 'mastil';
}

// Constantes de Colecciones Firebase
class FirebaseCollections {
  static const String articulos = 'articulos';
  static const String trabajadores = 'trabajadores';
  static const String logsDiarios = 'logs_diarios';
  static const String ajustes = 'ajustes';
  static const String configuracion = 'configuracion';
  static const String pedidos = 'pedidos';
}

// Constantes de Campos en Firebase
class FirebaseFields {
  static const String activo = 'activo';
  static const String nombre = 'nombre';
  static const String emailAuth = 'email_auth';
  static const String rol = 'rol';
  static const String id = 'id';
  static const String fechaId = 'fecha_id';
  static const String timestamp = 'timestamp';
  static const String movimientos = 'movimientos';
  static const String stockAnterior = 'stock_anterior';
  static const String stockAnteriorId = 'stock_anterior_id';
  static const String stockFinal = 'stock_final';
  static const String articulo = 'articulo';
  static const String cantidad = 'cantidad';
  static const String fecha = 'fecha';
  static const String motivo = 'motivo';
  static const String operador = 'operador';
  static const String concepto = 'concepto';
  static const String destino = 'destino';
  static const String origen = 'origen';
  static const String stockForzado = 'stock_forzado';
}

// Mensajes de la Aplicación
class AppMessages {
  static const String stockActualizado = '✅ Stock actualizado';
  static const String entradaConfirmada = '✅ Entrada confirmada';
  static const String roturasRegistradas = '✅ Roturas registradas';
  static const String operacionRegistrada = '✅ {{motivo}} registrado';
  static const String pinIncorrecto = '❌ PIN INCORRECTO';
  static const String sinRegistros = 'Sin registros';
  static const String listaVacia = 'Lista vacía';
  static const String noHayDescuadre = 'NO HAY DESCUADRE';
  static const String descuadre = 'DESCUADRE';
  static const String faltan = 'Faltan {{cantidad}} unidades';
  static const String sobran = 'Sobran {{cantidad}} unidades';
  static const String vieneDePrestado = 'Viene de PRESTADO ({{lugar}})';
}
