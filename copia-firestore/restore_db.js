const admin = require('firebase-admin');
const fs    = require('fs');
const path  = require('path');
const serviceAccount = require('../serviceAccount.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const archivo = process.argv[2];
if (!archivo) {
  console.error('❌ Uso: node copia-firestore/restore_db.js <ruta-del-backup.json>');
  process.exit(1);
}

function deserializarTimestamps(obj) {
  if (obj === null || obj === undefined) return obj;
  if (typeof obj === 'object' && obj.__type === 'Timestamp') {
    return new admin.firestore.Timestamp(obj.seconds, obj.nanoseconds);
  }
  if (Array.isArray(obj)) return obj.map(deserializarTimestamps);
  if (typeof obj === 'object') {
    const result = {};
    for (const [k, v] of Object.entries(obj)) result[k] = deserializarTimestamps(v);
    return result;
  }
  return obj;
}

async function restaurarColeccion(nombre, docs) {
  const batch = db.batch();
  let count = 0;
  for (const [id, data] of Object.entries(docs)) {
    const ref = db.collection(nombre).doc(id);
    batch.set(ref, deserializarTimestamps(data));
    count++;
    if (count % 400 === 0) {
      await batch.commit();
      console.log(`    ... ${count} documentos escritos`);
    }
  }
  await batch.commit();
  return count;
}

async function main() {
  const rutaAbsoluta = path.resolve(archivo);
  if (!fs.existsSync(rutaAbsoluta)) {
    console.error(`❌ Archivo no encontrado: ${rutaAbsoluta}`);
    process.exit(1);
  }

  const backup = JSON.parse(fs.readFileSync(rutaAbsoluta, 'utf8'));
  console.log(`\n🔄 Restaurando backup del ${backup.meta?.fecha ?? 'fecha desconocida'}`);
  console.log(`   Proyecto: ${backup.meta?.proyecto ?? '?'}\n`);

  const colecciones = Object.keys(backup).filter(k => k !== 'meta');

  for (const col of colecciones) {
    process.stdout.write(`  Restaurando ${col}...`);
    try {
      const total = await restaurarColeccion(col, backup[col]);
      console.log(` ✅ (${total} documentos)`);
    } catch (err) {
      console.log(` ❌ Error: ${err.message}`);
    }
  }

  console.log('\n✅ Restauración completada\n');
}

main().catch(err => { console.error('❌', err.message); process.exit(1); });
