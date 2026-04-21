# Stock Disco Pro

**Versión actual: 1.0.7**

Aplicación móvil y web para la gestión de stock de cachimbas en una discoteca. Permite controlar el inventario en tiempo real, registrar entradas, roturas y préstamos, y consultar el historial de movimientos por categoría.

---

## Historial de versiones

### v1.0.7 — Corrección de errores en realizar stock
- Eliminados los botones + y - del conteo de stock (no funcionaban correctamente)
- El conteo se realiza ahora exclusivamente mediante el campo de texto numérico

### v1.0.6 — Realizar stock rediseñado + documentación completa
- Campos de conteo inician a 0: el usuario introduce solo lo que cuenta físicamente
- Artículos dejados a 0 se actualizan a 0 en la base de datos con aviso de confirmación
- Clasificación de diferencias por motivo al confirmar (ROTURAS / PRESTADO / DESCUADRE / RECIBIDO / AJUSTE)
- Descuadres divididos en tres segmentos: roturas, prestados y desconocido
- Movimientos de realizar stock con motivo ROTURAS o PRESTADO visibles en sus historiales correspondientes
- README y DEVELOPER_GUIDE completos con todas las funcionalidades y lógica interna
- Configuración de flavors prod/beta con proyectos Firebase independientes

### v1.0.5 — Interfaz adaptativa web + realizar stock mejorado
- Diseño responsivo aplicado a todas las pantallas: en escritorio el contenido se centra al 60% del ancho
- Teclado PIN redimensionado y corregido en versión web (sin recorte)
- Error de PIN incorrecto cambiado a notificación flotante en la parte superior
- Favicon de la web actualizado con el icono oficial de la app
- Realizar stock rediseñado: campos a 0 por defecto, clasificación de diferencias por motivo
- Descuadres divididos en segmentos: roturas, prestados y desconocido
- Configuración de flavors Android prod/beta con proyectos Firebase independientes

### v1.0.4 — Icono y colores por rol
- Icono de app añadido en la pantalla de login
- Colores diferenciados según el rol del usuario

### v1.0.3 — Seguridad Firebase
- Autenticación anónima con Firebase
- Reglas de seguridad en Firestore
- Despliegue en Firebase Hosting (web)

### v1.0.2 — Versión visible
- Número de versión visible en la pantalla de login y en configuración

### v1.0.1 — Base funcional
- Gestión completa de stock: ver, realizar, recibir, roturas, prestado
- Historiales por categoría con descuadres
- Gestión de catálogo y personal (admin)
- Configuración de horario de stock forzado

---

## Roles y permisos

| Rol | Permisos |
|---|---|
| `trabajador` | Ver stock, registrar recibidos, roturas y préstamos |
| `encargado` | Todo lo anterior + realizar stock + ver historiales |
| `admin` | Acceso completo + catálogo + gestión de staff + configuración |

---

## Pantallas y funcionalidades

### Login
- El usuario selecciona su nombre de una lista cargada desde Firestore (`trabajadores`).
- Introduce su PIN de 4 dígitos mediante un teclado numérico en pantalla.
- Si el PIN es incorrecto, aparece una notificación flotante en la parte superior.
- Solo los trabajadores con `activo: true` aparecen en la lista.
- La sesión se guarda en la variable global `usuarioActual` (`session.dart`).
- Al iniciar la app se comprueba la versión mínima requerida (`min_version` en Firestore). Si la app instalada es inferior, se muestra una pantalla de actualización bloqueante.

### Ver Stock
- Muestra el inventario actual en tiempo real mediante un `StreamBuilder` conectado a Firestore.
- Vista de solo lectura, ordenada alfabéticamente.

### Realizar Stock
Disponible para `encargado` y `admin`. Ver sección completa más abajo.

### Recibido
- El usuario añade artículos a una lista antes de confirmar (puede añadir varios).
- Por cada artículo se indica:
  - **Artículo** — seleccionado del catálogo
  - **Cantidad**
  - **Concepto**: `STOCK NUEVO` o `DEVOLUCIÓN PRESTADO`
  - **Origen** (solo si es devolución): nombre del local que devuelve
- Al confirmar, se incrementa el stock de cada artículo con `FieldValue.increment` y se registra un movimiento con motivo `RECIBIDO`.

### Roturas
- Lista fija de artículos definida en `ArticuloConstants.itemsRoturas`.
- El usuario marca con checkbox los artículos rotos y ajusta la cantidad.
- **Comportamiento especial**: si se rompe una cachimba, el mástil sube automáticamente la misma cantidad (se separa del conjunto y se reutiliza).
- Al confirmar, el stock de los artículos seleccionados se decrementa y se registra un movimiento con motivo `ROTURAS`.

### Prestado
- Muestra todos los artículos del catálogo excepto las mangueras (se gestionan automáticamente).
- El usuario especifica el **destino** (nombre del local) y selecciona artículos con su cantidad.
- **Comportamiento especial**: si se prestan cachimbas, las mangueras se descuentan automáticamente en la misma cantidad.
- Al confirmar, el stock se decrementa y se registra un movimiento con motivo `PRESTADO`.

### Historiales
Accesible para `encargado` y `admin`. Cuatro categorías:

| Categoría | Filtro aplicado |
|---|---|
| RECIBIDOS | Movimientos con motivo `RECIBIDO` |
| ROTURAS | Movimientos con motivo `ROTURAS` |
| PRESTADOS | Movimientos con motivo `PRESTADO` |
| GENERALES | Documentos del día que contienen `stock_final` (resultado de realizar stock) |

El historial **GENERAL** de cada día muestra:
- Stock final contado
- Artículos nuevos dados de alta (`ALTA`)
- Roturas del día
- Descuadres divididos en tres segmentos:
  - 🔧 **Roturas** — diferencias justificadas por rotura no registrada
  - 🔄 **Prestados** — diferencias justificadas por préstamo no registrado
  - ❓ **Desconocido** — diferencias sin motivo conocido
- Movimientos logísticos del día (recibidos y prestados)

Los movimientos registrados durante el **realizar stock** con motivo `ROTURAS` o `PRESTADO` también aparecen en sus respectivos historiales de ROTURAS y PRESTADOS.

### Catálogo _(admin)_
- Permite añadir y eliminar artículos del inventario.
- Los nombres se almacenan en mayúsculas en Firestore.
- Los artículos del catálogo son los campos del documento único en la colección `articulos`.

### Gestión de Staff _(admin)_
- Alta, edición y desactivación de trabajadores.
- Campos: `nombre`, `pin`, `rol` (`trabajador` / `encargado` / `admin`), `activo`.
- Los trabajadores desactivados no aparecen en el login.

### Configuración _(admin)_
- **Abrir stock manualmente**: activa o desactiva `stock_forzado` en Firestore, permitiendo realizar stock fuera del horario oficial.

---

## Cómo funciona el Realizar Stock

### 1. Apertura del conteo
- Solo disponible los **domingos entre las 5:00 y las 12:00**, o cuando el admin activa el modo manual desde Configuración.
- Accesible para `encargado` y `admin`.

### 2. Introducción de cantidades
- Todos los artículos aparecen con **cantidad 0** por defecto.
- El usuario introduce manualmente lo que cuenta físicamente.
- Los artículos dejados a 0 se interpretarán como **sin stock** y se actualizarán a 0 en la base de datos.

### 3. Confirmación y clasificación de diferencias
Al pulsar **CONFIRMAR**, aparece un resumen con todos los artículos cuya cantidad difiere del stock actual. Para cada uno hay que indicar el motivo:

| Tipo de diferencia | Opciones de motivo |
|---|---|
| Negativa (falta stock) | `DESCUADRE`, `ROTURAS`, `PRESTADO` |
| Positiva (sobra stock) | `RECIBIDO`, `AJUSTE` |

Si algún artículo se dejó a 0, aparece un **aviso en rojo** pidiendo confirmación explícita.

### 4. Actualización y registro
- El stock de cada artículo con diferencia se actualiza al valor contado.
- Los artículos sin diferencia no se tocan.
- Se registra un movimiento en el historial con el motivo seleccionado.
- Los descuadres se guardan en `fugas` del log diario, divididos en tres segmentos: `roturas`, `prestados`, `desconocido`.

### 5. Visibilidad en historiales
- Motivo `ROTURAS` → aparece en historial de ROTURAS y en GENERALES.
- Motivo `PRESTADO` → aparece en historial de PRESTADOS y en GENERALES.
- Motivo `RECIBIDO` → aparece en historial de RECIBIDOS y en GENERALES.
- El resumen completo con stock final y descuadres por segmento aparece en GENERALES.

---

## Reglas de negocio

- **Mástil**: al registrar una rotura de cachimba, el mástil sube automáticamente la misma cantidad (se separa del conjunto y se reutiliza).
- **Mangueras automáticas**: al prestar cachimbas, las mangueras se descuentan automáticamente en la misma cantidad.
- **Horario de stock**: el stock oficial solo puede realizarse los **domingos entre las 5:00 y las 12:00**. El admin puede forzar la apertura desde Configuración.
- **Descuadres**: al cerrar el stock se calcula la diferencia entre el conteo manual y el stock actual. Se clasifican en roturas, prestados y desconocido, y se guardan en `fugas` del log diario.
- **Versión mínima**: al iniciar la app se comprueba `ajustes/configuracion.min_version`. Si la versión instalada es inferior, se bloquea el acceso hasta que el usuario actualice.

---

## Tecnologías

- [Flutter](https://flutter.dev/) — framework multiplataforma (Android / web)
- [Firebase Firestore](https://firebase.google.com/docs/firestore) — base de datos en tiempo real
- [Firebase Hosting](https://firebase.google.com/docs/hosting) — despliegue de la versión web
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution) — distribución del APK al grupo de testers
- Dart SDK `^3.11.5`

---

## Estructura del proyecto

```
lib/
  constants/
    constants.dart              # Constantes Firebase, artículos y listas fijas (ej: itemsRoturas)
  screens/
    login_screen.dart           # Selección de usuario y PIN con teclado numérico
    menu_principal.dart         # Panel de control con botones por rol
    inventario_screen.dart      # Ver stock (solo lectura) / Realizar stock (conteo)
    recibidos_screen.dart       # Registro de entrada de material
    roturas_screen.dart         # Registro de roturas
    prestado_screen.dart        # Registro de préstamos a otros locales
    historial_seleccion_screen.dart  # Menú de selección de tipo de historial
    historial_filtrado_screen.dart   # Listado de logs con detalle y descuadres
    configuracion_screen.dart   # Ajustes del sistema (admin)
    gestion_catalogo_screen.dart     # Gestión de artículos del catálogo (admin)
    gestion_personal_screen.dart     # Gestión de trabajadores (admin)
    update_required_screen.dart      # Pantalla de bloqueo por versión desactualizada
  services/
    stock_service.dart          # Capa de acceso a Firestore (todas las operaciones)
    version_service.dart        # Comprobación de versión mínima requerida
  session.dart                  # Estado de sesión global (usuarioActual, esHorarioOficial)
  main.dart                     # Inicialización de Firebase, selección de flavor y VersionGate
  firebase_options.dart         # Config Firebase producción (generada por FlutterFire CLI)
  firebase_options_beta.dart    # Config Firebase beta
```

---

## Estructura de Firestore

### Colección `articulos`
Documento único con los artículos como campos:
```json
{ "cachimbas": 10, "bases": 8, "mangueras": 10, "mastil": 2 }
```

### Colección `trabajadores`
Un documento por trabajador:
```json
{ "nombre": "Juan", "pin": "1234", "rol": "encargado", "activo": true }
```

### Colección `logs_diarios`
Un documento por día con ID `YYYY-M-D`:
```json
{
  "fecha_id": "2026-4-20",
  "timestamp": "...",
  "movimientos": [
    {
      "articulo": "CACHIMBAS",
      "cantidad": -2,
      "fecha": "...",
      "motivo": "ROTURAS",
      "operador": "Juan",
      "destino": null,
      "concepto": null
    }
  ],
  "stock_final": { "cachimbas": 8, "bases": 8 },
  "fugas": {
    "roturas":     { "cachimbas": -1 },
    "prestados":   {},
    "desconocido": { "bases": -2 }
  }
}
```

Campos del objeto `movimientos`:

| Campo | Descripción |
|---|---|
| `articulo` | Nombre en mayúsculas |
| `cantidad` | Positivo = entrada, negativo = salida |
| `fecha` | Timestamp del momento del registro |
| `motivo` | `RECIBIDO`, `ROTURAS`, `PRESTADO`, `DESCUADRE`, `AJUSTE`, `ALTA`, `GENERAL` |
| `operador` | Nombre del trabajador que realizó la acción |
| `destino` | Solo en PRESTADO: nombre del local destinatario |
| `concepto` | Solo en RECIBIDO: `STOCK NUEVO` o `DEVOLUCIÓN PRESTADO (origen)` |

### Colección `ajustes`
Documento `configuracion`:
```json
{ "stock_forzado": false, "min_version": "1.0.5" }
```

---

## Flavors (entornos)

El proyecto tiene dos flavors Android configurados en `build.gradle.kts`:

| Flavor | Package | Proyecto Firebase |
|---|---|---|
| `prod` | `com.example.proyecto_stockapp` | `stock-cachimbas` |
| `beta` | `stockapp.beta` | `stock-cachimbas-beta` |

La selección de configuración Firebase se realiza en `main.dart` mediante `--dart-define=FLAVOR=prod/beta`.

Los `google-services.json` de cada entorno están en:
- `android/app/src/prod/google-services.json`
- `android/app/src/beta/google-services.json`

---

## Deploy

### Web
```bash
flutter build web --release
firebase deploy --only hosting --project stock-cachimbas
```

### App móvil (producción)
```bash
bash deploy.sh
```
Construye el APK con flavor `prod`, lo sube a Firebase App Distribution al grupo `testers` y actualiza `min_version` en Firestore.

### App móvil (beta)
```bash
bash deploy_beta.sh
```
Construye el APK con flavor `beta` y lo sube al proyecto `stock-cachimbas-beta`, grupo `beta`.

### Copiar base de datos de producción a beta
```bash
node copy_db_to_beta.js
```
Requiere `serviceAccount.json` (prod) y `serviceAccount_beta.json` (beta) en la raíz del proyecto. Copia las colecciones `articulos`, `trabajadores`, `ajustes` y `logs_diarios`.

---

## Puesta en marcha desde cero

### Requisitos
- Flutter `>=3.x`
- Node.js (para scripts de deploy)
- Firebase CLI instalado y autenticado
- Proyecto Firebase con Firestore habilitado

### Instalación
```bash
git clone <repo>
cd StockApp
flutter pub get
npm install
```

### Configurar Firebase
```bash
flutterfire configure
```
Genera `lib/firebase_options.dart` para el proyecto de producción.

### Inicializar Firestore
Antes del primer uso, crear manualmente en Firestore:

1. **Colección `articulos`** — documento único con los artículos:
   ```json
   { "cachimbas": 0, "bases": 0, "mangueras": 0, "mastil": 0 }
   ```

2. **Colección `trabajadores`** — un documento por persona:
   ```json
   { "nombre": "Admin", "pin": "0000", "rol": "admin", "activo": true }
   ```

3. **Colección `ajustes`** — documento `configuracion`:
   ```json
   { "stock_forzado": false, "min_version": "1.0.0" }
   ```

### Ejecutar en local
```bash
flutter run --flavor prod --dart-define=FLAVOR=prod   # Android
flutter run -d chrome                                  # Web
```
