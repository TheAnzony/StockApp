# Guía para Desarrolladores — Stock Disco Pro

Este documento detalla la lógica interna, constantes, servicios y comportamientos específicos de la app para facilitar el mantenimiento o la incorporación de nuevas funcionalidades.

---

## Sesión global (`session.dart`)

```dart
Map<String, dynamic>? usuarioActual;
```

Variable global que almacena los datos del usuario autenticado. Se asigna al hacer login y se limpia al cerrar sesión. Contiene los campos del documento de Firestore: `nombre`, `pin`, `rol`, `activo`.

```dart
bool esHorarioOficial()
```

Devuelve `true` si la hora actual corresponde al horario oficial de realizar stock: **domingo entre las 5:00 y las 12:00**. Se usa en `menu_principal.dart` para mostrar u ocultar el botón de realizar stock.

---

## Servicio de versiones (`version_service.dart`)

```dart
VersionService.isUpdateRequired() → Future<bool>
```

Al iniciar la app (`main.dart` → `VersionGate`), se compara la versión instalada (obtenida con `package_info_plus`) contra `ajustes/configuracion.min_version` en Firestore. Si la versión instalada es menor, devuelve `true` y se muestra `UpdateRequiredScreen`, bloqueando el acceso hasta que el usuario actualice.

La comparación es por segmentos (`1.0.5` → `[1, 0, 5]`), no lexicográfica.

Actualizar `min_version` en Firestore se hace automáticamente con `deploy.sh` mediante `node update_version.js <version>`.

---

## Servicio de stock (`stock_service.dart`)

Todos los accesos a Firestore pasan por esta clase. Métodos principales:

| Método | Descripción |
|---|---|
| `articulosStream()` | Stream en tiempo real de la colección `articulos` |
| `articulosRef()` | Referencia al documento único de `articulos` |
| `addArticulo(nombre)` | Añade un artículo nuevo con valor 0 |
| `deleteArticulo(ref, nombre)` | Elimina un campo del documento de artículos |
| `agregarMovimientos(lista)` | Añade movimientos al log del día actual (merge) |
| `guardarStock(...)` | Guarda stock final, movimientos y fugas del día (merge) |
| `logsStream()` | Stream de `logs_diarios` ordenado por fecha descendente |
| `configuracionStream()` | Stream del documento `ajustes/configuracion` |
| `setStockForzado(bool)` | Actualiza el campo `stock_forzado` en Firestore |
| `trabajadoresStream(activo)` | Stream de trabajadores filtrado por estado activo |
| `addTrabajador(data)` | Crea un nuevo documento en `trabajadores` |
| `updateTrabajador(ref, data)` | Actualiza campos de un trabajador |
| `deleteTrabajador(ref)` | Elimina un documento de trabajador |

### Firma de `guardarStock`

```dart
StockService.guardarStock({
  required Map<String, int> stockFinal,
  required Map<String, int> fugasRoturas,
  required Map<String, int> fugasPrestados,
  required Map<String, int> fugasDesconocido,
  required List<Map<String, dynamic>> movimientos,
})
```

Guarda en el documento del día actual (`logs_diarios/YYYY-M-D`) usando `SetOptions(merge: true)`, por lo que si ya existe el documento lo actualiza sin borrar datos previos. El campo `fugas` se estructura así:

```json
{
  "fugas": {
    "roturas":     { "cachimbas": -2 },
    "prestados":   {},
    "desconocido": { "bases": -1 }
  }
}
```

---

## Constantes (`constants.dart`)

### `ArticuloConstants`

```dart
ArticuloConstants.itemsRoturas
```
Lista fija de artículos que pueden registrarse como rotura:
`cazoletas`, `kalouds`, `cachimbas`, `bases`, `hornillos`, `boquilla mangueras`, `punzones`.

```dart
ArticuloConstants.cachimbas  // 'cachimbas'
ArticuloConstants.mangueras  // 'mangueras'
ArticuloConstants.mastil     // 'mastil'
```

Usadas para los comportamientos automáticos (ver reglas de negocio).

### `FirebaseCollections` y `FirebaseFields`

Todas las cadenas de texto usadas en Firestore están centralizadas aquí para evitar errores tipográficos.

```dart
FirebaseCollections.articulos       // 'articulos'
FirebaseCollections.trabajadores    // 'trabajadores'
FirebaseCollections.logsDiarios     // 'logs_diarios'
FirebaseCollections.ajustes         // 'ajustes'
FirebaseCollections.configuracion   // 'configuracion'
```

### `MotivoMovimiento` (enum)

| Valor | Label | Emoji |
|---|---|---|
| `alta` | `ALTA` | 🆕 |
| `general` | `GENERAL` | 📊 |
| `recibido` | `RECIBIDO` | 📥 |
| `roturas` | `ROTURAS` | ⚠️ |
| `prestado` | `PRESTADO` | 📤 |

### `RolUsuario` (enum)

```dart
RolUsuario.admin      // prioridad 1
RolUsuario.encargado  // prioridad 2
RolUsuario.trabajador // prioridad 3

RolUsuario.puedeEditar  // true si es admin o encargado
```

---

## Comportamientos automáticos

### Rotura de cachimba → mástil sube
En `roturas_screen.dart`, al confirmar:
```dart
if (k == ArticuloConstants.cachimbas) {
  updates[ArticuloConstants.mastil] = FieldValue.increment(c);
}
```
El mástil incrementa porque se separa del conjunto y se puede reutilizar.

### Préstamo de cachimbas → mangueras bajan
En `prestado_screen.dart`, al confirmar:
```dart
if (k.toLowerCase() == ArticuloConstants.cachimbas) {
  updates[ArticuloConstants.mangueras] = FieldValue.increment(val);
  // val es negativo
}
```
Las mangueras se descuentan automáticamente porque van incluidas con cada cachimba prestada. Se registra también un movimiento de mangueras con motivo `PRESTADO`.

---

## Flujo de datos de un movimiento

Cada movimiento que se guarda en `logs_diarios` tiene esta estructura:

```dart
{
  'articulo': 'CACHIMBAS',       // siempre en mayúsculas
  'cantidad': -2,                // negativo = salida, positivo = entrada
  'fecha': DateTime.now(),       // timestamp local
  'motivo': 'ROTURAS',           // ver enum MotivoMovimiento
  'operador': 'Juan',            // usuarioActual['nombre']
  'destino': 'Local Norte',      // solo en PRESTADO
  'concepto': 'STOCK NUEVO',     // solo en RECIBIDO
}
```

Los campos `destino` y `concepto` son opcionales y solo aparecen en sus respectivos contextos.

---

## Historial — lógica de filtrado

En `historial_filtrado_screen.dart`, los documentos de `logs_diarios` se filtran así:

```dart
// Para RECIBIDOS, ROTURAS, PRESTADOS:
data['movimientos'].any((m) => m['motivo'] == filtro)

// Para GENERAL:
data.containsKey('stock_final')
```

Los documentos de días con solo movimientos (sin realizar stock) no aparecen en GENERALES.

Los documentos con `fugas` en formato antiguo (mapa plano `{articulo: diferencia}`) se muestran todos bajo el segmento **Desconocido** para mantener compatibilidad con registros previos a v1.0.5.

---

## Responsive web

Todas las pantallas detectan si el ancho es mayor de 600px:

```dart
final bool dt = MediaQuery.of(context).size.width > 600;
```

En escritorio, el contenido se centra al 60% del ancho:

```dart
dt ? Align(
  alignment: Alignment.topCenter,
  child: SizedBox(width: sw * 0.6, child: bodyContent),
) : bodyContent
```

---

## Flavors Android

Configurados en `android/app/build.gradle.kts`:

```kotlin
flavorDimensions += "env"
productFlavors {
    create("prod") {
        dimension = "env"
        applicationId = "com.example.proyecto_stockapp"
    }
    create("beta") {
        dimension = "env"
        applicationId = "stockapp.beta"
    }
}
```

En `main.dart`, la selección de Firebase Options se hace mediante:

```dart
const _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

final options = _flavor == 'beta'
    ? BetaFirebaseOptions.currentPlatform
    : DefaultFirebaseOptions.currentPlatform;
```

---

## Scripts de utilidad

### `update_version.js`
Actualiza `ajustes/configuracion.min_version` en Firestore de producción. Se llama automáticamente desde `deploy.sh`.
```bash
node update_version.js 1.0.5
```

### `copy_db_to_beta.js`
Copia las colecciones `articulos`, `trabajadores`, `ajustes` y `logs_diarios` del proyecto de producción al proyecto beta. Requiere:
- `serviceAccount.json` — service account de producción
- `serviceAccount_beta.json` — service account del proyecto beta

Ambos ficheros deben obtenerse desde **Firebase Console → Configuración del proyecto → Cuentas de servicio → Generar nueva clave privada**.

```bash
node copy_db_to_beta.js
```

---

## Añadir un artículo nuevo al catálogo

1. Desde la app: pantalla **Catálogo** (admin) → añadir artículo.
2. El artículo se guarda en mayúsculas como campo del documento único de `articulos` con valor 0.
3. Si el artículo tiene comportamiento especial (como cachimbas o mástil), hay que añadir la lógica correspondiente en `roturas_screen.dart`, `prestado_screen.dart` y `ArticuloConstants`.
4. Si debe aparecer en la lista de roturas, añadirlo a `ArticuloConstants.itemsRoturas` en `constants.dart`.

---

## Añadir un nuevo rol

1. Añadir el valor al enum `RolUsuario` en `constants.dart` con su label y prioridad.
2. Actualizar los condicionales de visibilidad en `menu_principal.dart` (`isAdmin`, `esEncargado`).
3. Actualizar la tabla de roles en este documento y en `README.md`.
