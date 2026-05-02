# Copias de seguridad de Firestore

## Qué contiene esta carpeta

| Archivo | Descripción |
|---|---|
| `backup_YYYY-MM-DD_HH-MM-SS.json` | Copias exportadas de Firestore |
| `backup.md` | Esta guía |
| `restore_db.js` | Script para restaurar un backup |

El script de exportación (`backup_db.js`) está en la raíz del proyecto.

---

## Cómo hacer una copia

Desde la raíz del proyecto:

```bash
node copia-firestore/backup_db.js
```

Genera un archivo `backup_YYYY-MM-DD_HH-MM-SS.json` directamente dentro de esta carpeta.

El script exporta las siguientes colecciones:
- `articulos` — stock actual y sabores
- `trabajadores` — lista de empleados
- `logs_diarios` — historial de movimientos
- `ajustes` — configuración (stock forzado, versión mínima)
- `pedidos` — pedidos confirmados

Los `Timestamp` de Firestore se serializan como `{ "__type": "Timestamp", "seconds": ..., "nanoseconds": ... }` para poder restaurarlos exactamente.

---

## Requisitos

- Node.js instalado
- `serviceAccount.json` en la raíz del proyecto (clave de servicio de Firebase)
- Dependencias instaladas: `npm install` en la raíz

No es necesario tener las reglas de Firestore abiertas ni ningún usuario activo. El Admin SDK tiene acceso completo independientemente de las reglas de seguridad.

---

## Cómo restaurar una copia

```bash
node copia-firestore/restore_db.js copia-firestore/backup_2026-05-02_18-47-07.json
```

El script:
1. Lee el archivo JSON indicado
2. Para cada colección del backup, hace un `set()` de cada documento (sobreescribe si ya existe)
3. Los Timestamps se deserializan de vuelta al tipo nativo de Firestore
4. Usa batches de 400 operaciones para no superar el límite de Firestore (500 por batch)

**Advertencia**: la restauración sobreescribe los documentos existentes con los mismos IDs. No borra documentos que estén en Firestore pero no en el backup.

---

## Copias disponibles

| Archivo | Fecha | Tamaño |
|---|---|---|
| `backup_2026-05-02_18-47-07.json` | 2026-05-02 18:47 | 6.2 KB |
