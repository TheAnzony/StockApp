# Stock Disco Pro

**Versión actual: 2.1.1**

Aplicación móvil y web para la gestión de stock de cachimbas en una discoteca. Permite controlar el inventario en tiempo real, registrar entradas, roturas y préstamos, gestionar sabores con marca y formato, generar pedidos inteligentes y consultar el historial de movimientos por categoría.

---

## Historial de versiones

### v2.1.1 — Prioridad alta automática para stock en 0

#### PEDIDO — reglas de prioridad
- Cualquier ítem (artículo o sabor) con cantidad **0** se muestra siempre como prioridad **alta**, independientemente de su formato o regla base:
  - Artículos: BASES, CACHIMBAS, MANGUERAS y HORNILLOS escalan a alta si llegan a 0
  - Sabores: cualquier sabor a 0 unidades es alta sin importar si es 50gr, 100gr o 200gr
- La lista de sugerencias se ordena de mayor a menor prioridad: 🔴 alta → 🟠 media → 🟡 baja → ⚪ manual

---

### v2.1.0 — Gestión de sabores mejorada + Pantalla de Pedido

#### Sabores — nueva estructura
- Los sabores ahora almacenan **nombre, marca, formato y cantidad** (`{marca, formato, cantidad}` por documento)
- Catálogo inicial de 15 sabores migrado con marca (Alfaker / SK / Dozaj) y formato (50gr / 100gr / 200gr)
- En **CARTA → Sabores**: cada sabor muestra su marca y formato como subtítulo
- En **CATÁLOGO → Sabores**: al añadir un sabor se solicitan nombre, marca, formato y cantidad inicial; la lista muestra el detalle completo
- Al usar un sabor o hacer reajuste se usa dot-notation (`nombre.cantidad`) para actualizar solo la cantidad sin alterar marca/formato

#### Pantalla PEDIDO _(admin / encargado)_
- Nuevo botón **PEDIDO** en el menú principal, accesible para admin y encargado
- Sugerencias automáticas basadas en reglas de stock en tiempo real:
  - **CAZOLETAS**: rojo si < 50, naranja si < cachimbas − 15
  - **BASES**: rojo si mástil > bases y mástil > 5; naranja si mástil > bases y mástil ≤ 5
  - **LÍQUIDO BASES**: rojo si = 0, naranja si = 1
  - **CACHIMBAS**: rojo si cachimbas + mástil < 40; naranja si entre 40 y 50
  - **MANGUERAS**: rojo si diferencia con cachimbas ≥ 10; naranja si diferencia > 0
  - **HORNILLOS**: naranja si ≤ 2
  - **Sabores 50gr**: rojo si = 0, naranja si < 10, amarillo si < 20
  - **Sabores 100gr**: naranja si < 2
  - **Sabores 200gr**: naranja si < 5 (Magic Love y Snowy Fucsia Green: naranja si < 10)
- Prioridad visual con borde de color: 🔴 rojo (alta), 🟠 naranja (media), 🟡 amarillo (baja)
- Cantidad editable por ítem (comienza en 0, es sugerencia)
- Botón **+** para añadir artículos o sabores manualmente, con buscador
- Botón **CONFIRMAR PEDIDO** que guarda la lista en la colección `pedidos` con fecha y operador
- Tras confirmar, los ítems manuales se limpian y se muestra confirmación

#### Historial de PEDIDOS
- Nueva entrada **PEDIDOS** en la pantalla de selección de historiales
- Misma estructura de meses colapsables que los demás historiales
- Mes actual expandido por defecto; el resto colapsados
- Filtro de año en el AppBar si hay datos de más de un año
- Cada pedido muestra fecha, operador y número de artículos; al expandir muestra cada ítem con su chip de prioridad en color y la cantidad pedida

#### RECIBIR MATERIAL — soporte para sabores
- La pantalla ahora tiene dos botones: **ARTÍCULO** (azul) y **SABOR** (índigo)
- El selector de sabores muestra nombre, marca y formato; el campo seleccionado muestra `Nombre · Marca · Formato` compacto en una línea
- Al confirmar: los artículos actualizan stock y se registran en `logs_diarios` como antes; los sabores incrementan su cantidad directamente en `articulos/sabores`

---

### v2.0.0 — Sistema de autenticación, sesión persistente y reajuste de stock
- Autenticación invisible con Firebase Auth Email/Password (email generado: `nombre@stockapp.com`, contraseña: PIN + "00")
- Sesión persistente en web: la página puede recargarse sin cerrar sesión
- Cierre de sesión automático tras 1 hora de inactividad (cualquier toque reinicia el contador)
- Recuperación del conteo de stock en curso si la página se recarga antes de confirmar
- Reajuste directo de stock para admin (sin registro en historial de movimientos)
- Pantalla de login sin texto de rol (los colores identifican el nivel)
- Gestión de staff con menú de tres puntos (editar, desactivar, cambiar PIN)
- Historial con agrupación por mes, meses colapsables y filtro por año
- Botón "USAR" en sabores accesible para todos los roles

---

### v1.0.9 — Refactor estructura Firestore + Catálogo con pestañas
- Los sabores se almacenan ahora en `articulos/sabores` (misma colección que `articulos/stock`)
- Eliminada la colección separada `sabores/inventario`
- `GestionCatalogoScreen` rediseñado con dos pestañas: STOCK y SABORES
- `StockService` refactorizado: referencias síncronas directas

### v1.0.8 — Nueva pantalla Carta
- Pantalla Carta accesible desde el menú principal para todos los roles
- Pestaña MEZCLAS: lista de recetas con ingredientes, porcentajes y barra visual de color
- Pestaña SABORES: stock en tiempo real con botón USAR para todos los roles

### v1.0.7 — Corrección de errores en realizar stock
- El conteo se realiza ahora exclusivamente mediante el campo de texto numérico

### v1.0.6 — Realizar stock rediseñado + documentación completa
- Campos de conteo inician a 0
- Clasificación de diferencias por motivo al confirmar
- Descuadres divididos en tres segmentos: roturas, prestados y desconocido

### v1.0.5 — Interfaz adaptativa web
- Diseño responsivo: en escritorio el contenido se centra al 60% del ancho
- Favicon actualizado con el icono oficial de la app

### v1.0.4 — Icono y colores por rol
- Icono de app en la pantalla de login
- Colores diferenciados según el rol del usuario

### v1.0.3 — Seguridad Firebase
- Autenticación anónima con Firebase y reglas de seguridad en Firestore

### v1.0.2 — Versión visible
- Número de versión visible en la pantalla de login

### v1.0.1 — Base funcional
- Gestión completa de stock: ver, realizar, recibir, roturas, prestado
- Historiales por categoría con descuadres y gestión de catálogo y personal

---

## Roles y permisos

| Rol | Permisos |
|---|---|
| `trabajador` | Ver stock, registrar recibidos, roturas, préstamos y usar sabores |
| `encargado` | Todo lo anterior + realizar stock + ver historiales + gestionar pedidos |
| `admin` | Acceso completo + catálogo + gestión de staff + configuración + reajuste directo |

---

## Pantallas y funcionalidades

### Login
- El usuario selecciona su nombre de una lista cargada desde Firestore (`trabajadores`).
- Introduce su PIN mediante un teclado numérico. Los colores del avatar identifican el rol.
- Sesión persistente: al recargar la web se restaura la sesión si ha habido actividad en la última hora.
- Cierre automático por inactividad tras 1 hora.

### Ver Stock
- Inventario actual en tiempo real, ordenado alfabéticamente, solo lectura.

### Realizar Stock
- Disponible para `encargado` y `admin` en horario oficial (domingos 5:00–12:00) o con stock forzado.
- El conteo recupera automáticamente el estado anterior si la sesión se interrumpe.

### Recibir Material
- Permite añadir artículos y sabores a una lista antes de confirmar.
- **Artículos**: artículo, cantidad, concepto (STOCK NUEVO / DEVOLUCIÓN PRESTADO) y origen.
- **Sabores**: selector con nombre, marca y formato; incrementa `cantidad` en `articulos/sabores`.
- Al confirmar: artículos actualizan stock y generan log; sabores actualizan cantidad directamente.

### Roturas
- Lista fija de artículos. Al romper una cachimba, el mástil sube automáticamente.

### Prestado
- Al prestar cachimbas, las mangueras se descuentan automáticamente.

### Carta
- **MEZCLAS**: recetas con ingredientes, porcentajes y barra visual de color.
- **SABORES**: stock en tiempo real con marca y formato; botón USAR para todos los roles; reajuste directo para admin.

### Pedido _(admin / encargado)_
- Sugerencias automáticas basadas en reglas de stock con indicador de prioridad (rojo / naranja / amarillo).
- Cantidad editable por ítem (sugerencia, comienza en 0).
- Añadir artículos o sabores manualmente con buscador.
- CONFIRMAR PEDIDO guarda la lista en la colección `pedidos` con fecha y operador.

### Historiales _(encargado / admin)_
Cinco categorías, todas con meses colapsables y filtro por año:

| Categoría | Contenido |
|---|---|
| RECIBIDOS | Movimientos con motivo `RECIBIDO` |
| ROTURAS | Movimientos con motivo `ROTURAS` |
| PRESTADOS | Movimientos con motivo `PRESTADO` |
| GENERALES | Resultado del realizar stock diario con stock final, roturas y descuadres |
| PEDIDOS | Pedidos confirmados con artículos, sabores, prioridad y cantidad |

### Catálogo _(admin)_
- **STOCK**: añadir y eliminar artículos del inventario.
- **SABORES**: añadir sabores (nombre, marca, formato, cantidad inicial) y eliminarlos. La lista muestra marca, formato y stock actual.

### Gestión de Staff _(admin)_
- Alta, edición, cambio de PIN y desactivación de trabajadores.

### Configuración _(admin)_
- Activar stock forzado fuera del horario oficial.

---

## Reglas de negocio

- **Mástil**: al registrar una rotura de cachimba, el mástil sube automáticamente la misma cantidad.
- **Mangueras automáticas**: al prestar cachimbas, las mangueras se descuentan automáticamente.
- **Horario de stock**: domingos entre las 5:00 y las 12:00. El admin puede forzar la apertura.
- **Descuadres**: al cerrar el stock se clasifican en roturas, prestados y desconocido (`fugas` en el log).
- **Pedido inteligente**: las reglas se evalúan en tiempo real contra el stock actual. Los ítems sugeridos desaparecen si el stock sube por encima del umbral.
- **Versión mínima**: `ajustes/configuracion.min_version` bloquea versiones anteriores.

---

## Tecnologías

- [Flutter](https://flutter.dev/) — framework multiplataforma (Android / web)
- [Firebase Auth](https://firebase.google.com/docs/auth) — autenticación Email/Password invisible
- [Firebase Firestore](https://firebase.google.com/docs/firestore) — base de datos en tiempo real
- [Firebase Hosting](https://firebase.google.com/docs/hosting) — versión web
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution) — distribución APK
- Dart SDK `^3.11.5`

---

## Estructura del proyecto

```
lib/
  constants/
    constants.dart                   # Constantes Firebase, artículos y roles
    carta_constants.dart             # Recetas y lista de sabores de la carta
  models/
    sabor.dart                       # Modelo Sabor (nombre, marca, formato, cantidad)
    articulo.dart                    # Modelo de artículo de stock
  screens/
    login_screen.dart                # Selección de usuario y PIN
    menu_principal.dart              # Panel de control con botones por rol
    inventario_screen.dart           # Ver stock / Realizar stock
    recibidos_screen.dart            # Registro de entrada de material (artículos y sabores)
    roturas_screen.dart              # Registro de roturas
    prestado_screen.dart             # Registro de préstamos
    carta_screen.dart                # Recetas (MEZCLAS) y sabores con stock (SABORES)
    pedido_screen.dart               # Sugerencias de pedido con reglas automáticas
    historial_seleccion_screen.dart  # Menú de selección de tipo de historial
    historial_filtrado_screen.dart   # Logs de movimientos con meses colapsables
    historial_pedidos_screen.dart    # Historial de pedidos confirmados
    configuracion_screen.dart        # Ajustes del sistema (admin)
    gestion_catalogo_screen.dart     # Gestión de artículos y sabores del catálogo
    gestion_personal_screen.dart     # Gestión de trabajadores (admin)
    update_required_screen.dart      # Pantalla de bloqueo por versión desactualizada
  services/
    stock_service.dart               # Capa de acceso a Firestore
    auth_service.dart                # Firebase Auth (login / logout)
    session_service.dart             # Sesión persistente e inactividad
    version_service.dart             # Comprobación de versión mínima
  session.dart                       # Estado global (usuarioActual, esHorarioOficial)
  main.dart                          # Inicialización, VersionGate y restauración de sesión
```

---

## Estructura de Firestore

### `articulos/stock`
Documento único con artículos como campos en mayúsculas:
```json
{ "CACHIMBAS": 73, "MANGUERAS": 73, "MASTIL": 0, "CAZOLETAS": 68 }
```

### `articulos/sabores`
Documento único con sabores como mapa anidado:
```json
{
  "Magic Love":   { "marca": "Alfaker", "formato": "200gr", "cantidad": 28 },
  "Happy bound":  { "marca": "SK",      "formato": "50gr",  "cantidad": 11 },
  "Yellow":       { "marca": "Alfaker", "formato": "200gr", "cantidad": 10 }
}
```

### `trabajadores`
Un documento por trabajador:
```json
{ "nombre": "Juan", "email_auth": "juan@stockapp.com", "rol": "encargado", "activo": true }
```

### `logs_diarios`
Un documento por día con ID `YYYY-M-D`:
```json
{
  "fecha_id": "2026-5-2",
  "timestamp": "...",
  "movimientos": [
    { "articulo": "CACHIMBAS", "cantidad": -2, "motivo": "ROTURAS", "operador": "Juan", "fecha": "..." }
  ],
  "stock_final": { "CACHIMBAS": 71 },
  "fugas": { "roturas": {}, "prestados": {}, "desconocido": { "CACHIMBAS": -1 } }
}
```

### `pedidos`
Un documento por pedido confirmado (ID auto-generado):
```json
{
  "fecha": "Timestamp",
  "operador": "Antonio",
  "items": [
    { "nombre": "CAZOLETAS", "esSabor": false, "prioridad": "alta",   "cantidad": 50 },
    { "nombre": "Magic Love", "esSabor": true,  "prioridad": "media",  "cantidad": 10 }
  ]
}
```

### `ajustes/configuracion`
```json
{ "stock_forzado": false, "min_version": "2.1.0" }
```

---

## Deploy

### Web
```bash
flutter build web --release --pwa-strategy=none
firebase deploy --only hosting --project stock-cachimbas
```

### App móvil (producción)
```bash
bash deploy.sh
```
Construye el APK con flavor `prod`, lo sube a Firebase App Distribution al grupo `testers` y actualiza `min_version` en Firestore.

---

## Puesta en marcha desde cero

### Requisitos
- Flutter `>=3.x`
- Node.js (para scripts de deploy y migración)
- Firebase CLI instalado y autenticado
- `serviceAccount.json` en la raíz (para scripts de admin)

### Instalación
```bash
git clone <repo>
cd StockApp
flutter pub get
npm install
```

### Inicializar Firestore
1. **`articulos/stock`** — documento con los artículos en mayúsculas
2. **`articulos/sabores`** — ejecutar `node seed_sabores.js` para cargar el catálogo inicial
3. **`trabajadores`** — un documento por persona con `email_auth`, `rol` y `activo: true`
4. **`ajustes/configuracion`** — `{ "stock_forzado": false, "min_version": "2.1.0" }`
