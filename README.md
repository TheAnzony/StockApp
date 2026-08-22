# Stock Disco Pro

**Versión actual: 2.3.0**

Aplicación móvil y web para la gestión de stock de cachimbas en una discoteca. Permite controlar el inventario en tiempo real, registrar entradas, roturas y préstamos, gestionar sabores con marca y formato, generar pedidos y consultar el historial de movimientos por categoría.

---

## Historial de versiones

### v2.3.0 — Mezclas editables en Carta y edición de pedidos del día

#### CARTA — mezclas movidas a Firestore
- Las recetas de MEZCLAS ya no están hardcodeadas en el código; viven en el documento `articulos/mezclas`
- Admin puede **crear, editar y eliminar mezclas** desde la propia app (botón NUEVA MEZCLA + lápiz/papelera por receta), seleccionando sabores del catálogo y su porcentaje
- Validaciones al guardar: nombre no vacío ni duplicado, al menos un sabor, cada sabor con porcentaje > 0, y los porcentajes deben sumar exactamente 100%
- **Corregido el bug reportado**: renombrar un sabor desde Catálogo ahora actualiza en cascada su nombre en cualquier mezcla que lo use, en la misma escritura atómica — antes había que editar el código a mano y redesplegar
- Migración única (`migrate_mezclas.js`) para llevar las 8 recetas existentes a Firestore, limpiando los sufijos "(Marca)" del nombre de los ingredientes para que coincidan exactamente con las claves de `articulos/sabores`

#### PEDIDO — edición de pedidos ya confirmados
- En el historial de PEDIDOS aparece un botón de editar (lápiz) junto a la fecha, solo si el usuario es **admin** y el pedido es **del día actual**
- Abre la pantalla de PEDIDO precargada con las cantidades ya guardadas; al confirmar, actualiza el `items` del pedido existente en vez de crear uno nuevo

---

### v2.2.0 — Rework de Pedido, Recibir, Prestado, Roturas y Catálogo

#### PEDIDO — rediseño sin sugerencias
- Eliminadas las reglas automáticas de sugerencia y el concepto de prioridad (alta/media/baja/manual)
- Ahora se listan **todos** los artículos y sabores del catálogo en dos secciones separadas (ARTÍCULOS y SABORES), cada uno con su stock actual y un campo de cantidad a pedir
- Buscador para filtrar la lista
- Al confirmar se muestra un resumen (solo ítems con cantidad > 0) con opción de VOLVER a editar o CONFIRMAR
- El campo `prioridad` ya no se guarda en los documentos de `pedidos`

#### RECIBIR MATERIAL — rediseño con concepto por ítem
- Ya no hay diálogos por artículo: se listan todos los artículos y sabores (con stock actual) de una vez, igual que en PEDIDO
- El concepto (STOCK NUEVO / DEVOLUCIÓN PRESTADO) se elige **por ítem**, no para todo el lote — permite mezclar en una misma recepción, por ejemplo, tabaco de pedido semanal con una devolución de otro local
- El campo "¿de dónde viene?" aparece solo en los ítems marcados como devolución
- Los sabores recibidos ahora también generan entrada en el historial de RECIBIDOS con su concepto (antes solo se sumaba la cantidad sin dejar rastro)
- Resumen de confirmación antes de guardar, igual que en PEDIDO

#### ROTURAS — lista dinámica
- Ya no usa una lista fija en código (`itemsRoturas`); ahora lista automáticamente todos los campos del documento `articulos/stock` (los sabores no aparecen, viven en otro documento)
- Muestra el stock actual de cada artículo junto a la casilla de selección

#### PRESTADO — rediseño con validación de stock
- Lista todos los artículos con su stock actual y un campo de cantidad, igual que PEDIDO/RECIBIR
- La cantidad a prestar no puede ser negativa ni superar el stock disponible (se recorta automáticamente)
- Eliminado el descuento automático de mangueras al prestar cachimbas: ahora mangueras aparece en la lista y hay que registrarla manualmente si corresponde
- Resumen de confirmación con destino y artículos antes de guardar

#### CATÁLOGO — edición de artículos y sabores
- Nuevo botón de editar (lápiz) en cada ítem de STOCK y SABORES
- Artículos: se puede renombrar (conserva el stock actual)
- Sabores: se puede renombrar, cambiar de marca y de formato (conserva la cantidad actual)
- Validación anti-colisión: no deja renombrar a un nombre ya usado por otro ítem

#### Corrección: orden de días en Historiales
- Los días dentro de cada mes se ordenaban como texto en vez de como fecha (p. ej. el día 19 aparecía antes que el día 2). Corregido para ordenar numéricamente.

---

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
- Lista completa de artículos y sabores (con su stock actual) en dos secciones, con un campo de cantidad recibida por ítem; solo se procesan los ítems con cantidad > 0.
- Cada ítem lleva su propio concepto (STOCK NUEVO / DEVOLUCIÓN PRESTADO), con campo de origen si es devolución — permite mezclar conceptos distintos en una misma recepción.
- Resumen antes de confirmar, con opción de volver a editar.
- Al confirmar: artículos y sabores actualizan stock y generan log en `logs_diarios` con motivo RECIBIDO y su concepto.

### Roturas
- Lista dinámica con todos los artículos del stock (excepto tabaco), mostrando el stock actual de cada uno. Al romper una cachimba, el mástil sube automáticamente.

### Prestado
- Lista con todos los artículos del stock y su stock actual; la cantidad a prestar no puede superar el stock disponible. Las mangueras deben registrarse manualmente si se prestan junto con las cachimbas (ya no se descuentan solas).

### Carta
- **MEZCLAS**: recetas con ingredientes, porcentajes y barra visual de color, leídas en tiempo real desde `articulos/mezclas`. Admin puede crear, editar y eliminar mezclas (botón NUEVA MEZCLA + lápiz/papelera por receta); al guardar se valida que los porcentajes sumen 100% y que cada sabor tenga más de 0%.
- Si se renombra un sabor desde Catálogo, cualquier mezcla que lo use se actualiza automáticamente (ya no hace falta editar código).
- **SABORES**: stock en tiempo real con marca y formato; botón USAR para todos los roles; reajuste directo para admin.

### Pedido _(admin / encargado)_
- Lista completa de artículos y sabores (con su stock actual) en dos secciones separadas, con buscador y un campo de cantidad a pedir por ítem.
- Resumen antes de confirmar, con opción de volver a editar la lista.
- CONFIRMAR PEDIDO guarda en la colección `pedidos` (solo ítems con cantidad > 0) con fecha y operador.

### Historiales _(encargado / admin)_
Cinco categorías, todas con meses colapsables y filtro por año:

| Categoría | Contenido |
|---|---|
| RECIBIDOS | Movimientos con motivo `RECIBIDO` |
| ROTURAS | Movimientos con motivo `ROTURAS` |
| PRESTADOS | Movimientos con motivo `PRESTADO` |
| GENERALES | Resultado del realizar stock diario con stock final, roturas y descuadres |
| PEDIDOS | Pedidos confirmados con artículos, sabores y cantidad |

### Catálogo _(admin)_
- **STOCK**: añadir, editar (renombrar) y eliminar artículos del inventario.
- **SABORES**: añadir sabores (nombre, marca, formato, cantidad inicial), editar (nombre, marca, formato) y eliminarlos. La lista muestra marca, formato y stock actual.

### Gestión de Staff _(admin)_
- Alta, edición, cambio de PIN y desactivación de trabajadores.

### Configuración _(admin)_
- Activar stock forzado fuera del horario oficial.

---

## Reglas de negocio

- **Mástil**: al registrar una rotura de cachimba, el mástil sube automáticamente la misma cantidad.
- **Préstamo de mangueras**: es manual; si se prestan cachimbas junto con mangueras hay que registrar ambas por separado (ya no hay descuento automático).
- **Horario de stock**: domingos entre las 5:00 y las 12:00. El admin puede forzar la apertura.
- **Descuadres**: al cerrar el stock se clasifican en roturas, prestados y desconocido (`fugas` en el log).
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
    pedido_screen.dart               # Lista completa de artículos/sabores para pedir
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
  "Happy hound":  { "marca": "SK",      "formato": "50gr",  "cantidad": 11 },
  "Yellow":       { "marca": "Alfaker", "formato": "200gr", "cantidad": 10 }
}
```

### `articulos/mezclas`
Documento único con un array `recetas` (el orden del array define el orden de visualización en la Carta); el nombre de cada ingrediente debe coincidir exactamente con una clave de `articulos/sabores` para que el rebranding en cascada funcione:
```json
{
  "recetas": [
    { "nombre": "Cítrica", "ingredientes": [
      { "nombre": "Yellow", "porcentaje": 90 },
      { "nombre": "Polar freeze", "porcentaje": 10 }
    ]}
  ]
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
    { "nombre": "CAZOLETAS", "esSabor": false, "cantidad": 50 },
    { "nombre": "Magic Love", "esSabor": true,  "cantidad": 10 }
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
3. **`articulos/mezclas`** — ejecutar `node migrate_mezclas.js` para cargar las recetas iniciales de la Carta (no sobreescribe si el documento ya existe)
4. **`trabajadores`** — un documento por persona con `email_auth`, `rol` y `activo: true`
5. **`ajustes/configuracion`** — `{ "stock_forzado": false, "min_version": "2.1.0" }`
