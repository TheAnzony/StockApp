# Stock Disco Pro

Aplicación móvil para la gestión de stock de cachimbas en una discoteca. Permite controlar el inventario en tiempo real, registrar entradas, roturas y préstamos, y consultar el historial de movimientos por categoría.

---

## Características

- **Login por PIN** — cada trabajador selecciona su nombre e introduce su PIN personal
- **Ver Stock** — visualización del inventario actual en tiempo real
- **Realizar Stock** — conteo oficial del inventario (restringido a domingos 5h–12h, o activable manualmente por el admin)
- **Recibido** — registro de entrada de material (stock nuevo o devolución de préstamo)
- **Roturas** — baja de artículos rotos (al romper una cachimba, el mástil se contabiliza por separado)
- **Prestado** — salida de material hacia otro local (las mangueras se descuentan automáticamente al prestar cachimbas)
- **Historiales** — consulta de logs por categoría: recibidos, roturas, prestados y stocks generales
- **Catálogo** — gestión del listado de artículos (admin)
- **Gestión de Staff** — alta, baja y edición de trabajadores (admin)
- **Configuración** — activar/desactivar el stock manual fuera de horario (admin)

---

## Roles

| Rol | Permisos |
|---|---|
| `trabajador` | Ver stock, registrar recibidos, roturas y préstamos |
| `encargado` | Todo lo anterior + realizar stock + ver historiales |
| `admin` | Acceso completo + catálogo + staff + configuración |

---

## Tecnologías

- [Flutter](https://flutter.dev/) — framework multiplataforma (Android / iOS)
- [Firebase Firestore](https://firebase.google.com/docs/firestore) — base de datos en tiempo real
- Dart SDK `^3.11.5`

---

## Estructura del proyecto

```
lib/
  constants/
    constants.dart              # Enums (roles, motivos, artículos) y constantes Firebase
  models/
    articulo.dart               # Modelo de artículo de stock
    trabajador.dart             # Modelo de trabajador/usuario
    movimiento.dart             # Modelo de movimiento de stock
    log_diario.dart             # Modelo de log diario con cálculo de descuadres
    configuracion.dart          # Modelo de configuración del sistema
  screens/
    login_screen.dart           # Pantalla de selección de usuario y PIN
    menu_principal.dart         # Panel de control principal
    inventario_screen.dart      # Ver stock / Realizar stock
    recibidos_screen.dart       # Registrar entrada de material
    roturas_screen.dart         # Registrar roturas
    prestado_screen.dart        # Registrar préstamos a otros locales
    historial_seleccion_screen.dart  # Selección de tipo de historial
    historial_filtrado_screen.dart   # Listado de logs con detalle y descuadres
    configuracion_screen.dart   # Ajustes del sistema (admin)
    gestion_catalogo_screen.dart     # Gestión de artículos del catálogo (admin)
    gestion_personal_screen.dart     # Gestión de trabajadores (admin)
  services/
    stock_service.dart          # Capa de acceso a Firestore (todas las operaciones)
  session.dart                  # Estado de sesión global (usuarioActual, esHorarioOficial)
  main.dart                     # Inicialización de Firebase y MaterialApp
  firebase_options.dart         # Configuración generada por FlutterFire CLI
```

---

## Colecciones en Firestore

| Colección | Descripción |
|---|---|
| `articulos` | Documento único con los artículos y sus cantidades actuales |
| `trabajadores` | Un documento por trabajador con nombre, PIN, rol y estado activo |
| `logs_diarios` | Un documento por día (`YYYY-M-D`) con movimientos, stock final y descuadres |
| `ajustes/configuracion` | Configuración global (ej: `stock_forzado`) |

---

## Reglas de negocio

- **Mástil**: al registrar una rotura de cachimba, el mástil sube de forma automática (se separa del conjunto).
- **Mangueras automáticas**: al prestar cachimbas, las mangueras se descuentan automáticamente en la misma cantidad.
- **Horario de stock**: el stock oficial solo puede realizarse los **domingos entre las 5:00 y las 12:00**. El admin puede forzar la apertura desde Configuración.
- **Descuadres**: al cerrar el stock, se calcula la diferencia entre el conteo manual y el último stock registrado. Los descuadres se guardan en `fugas` del log diario.

---

## Puesta en marcha

### Requisitos

- Flutter `>=3.x`
- Proyecto Firebase con Firestore habilitado
- FlutterFire CLI configurado

### Instalación

```bash
git clone <repo>
cd Proyecto_StockApp
flutter pub get
```

Asegúrate de tener el archivo `lib/firebase_options.dart` generado con:

```bash
flutterfire configure
```

### Ejecutar

```bash
flutter run
```

---

## Inicialización de Firestore

Antes del primer uso, crea manualmente en Firestore:

1. **Colección `articulos`** — un documento con los artículos como campos:
   ```json
   { "cachimbas": 10, "bases": 10, "mangueras": 10, ... }
   ```

2. **Colección `trabajadores`** — un documento por persona:
   ```json
   { "nombre": "Juan", "pin": "1234", "rol": "admin", "activo": true }
   ```

3. **Colección `ajustes`** — documento `configuracion`:
   ```json
   { "stock_forzado": false }
   ```
