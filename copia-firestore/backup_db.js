const admin = require('firebase-admin');
const fs    = require('fs');
const path  = require('path');
const serviceAccount = require('../serviceAccount.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const COLECCIONES = ['articulos', 'trabajadores', 'logs_diarios', 'ajustes', 'pedidos'];

async function exportColeccion(nombre) {
  const snap = await db.collection(nombre).get();
  const docs = {};
  snap.forEach(doc => { docs[doc.id] = doc.data(); });
  return docs;
}

function serializarTimestamps(obj) {
  if (obj === null || obj === undefined) return obj;
  if (obj instanceof admin.firestore.Timestamp) {
    return { __type: 'Timestamp', seconds: obj.seconds, nanoseconds: obj.nanoseconds };
  }
  if (Array.isArray(obj)) return obj.map(serializarTimestamps);
  if (typeof obj === 'object') {
    const result = {};
    for (const [k, v] of Object.entries(obj)) result[k] = serializarTimestamps(v);
    return result;
  }
  return obj;
}

async function main() {
  const ahora  = new Date();
  const fecha  = ahora.toISOString().slice(0, 10); // YYYY-MM-DD
  const hora   = ahora.toTimeString().slice(0, 8).replace(/:/g, '-'); // HH-MM-SS
  const nombre = path.join(__dirname, `backup_${fecha}_${hora}.json`);

  console.log(`\n📦 Iniciando backup — ${fecha} ${hora.replace(/-/g, ':')}\n`);

  const backup = { meta: { fecha: ahora.toISOString(), proyecto: serviceAccount.project_id } };

  for (const col of COLECCIONES) {
    process.stdout.write(`  Exportando ${col}...`);
    try {
      const datos = await exportColeccion(col);
      backup[col] = serializarTimestamps(datos);
      console.log(` ✅ (${Object.keys(datos).length} documentos)`);
    } catch (err) {
      console.log(` ❌ Error: ${err.message}`);
    }
  }

  fs.writeFileSync(nombre, JSON.stringify(backup, null, 2), 'utf8');
  const kb = (fs.statSync(nombre).size / 1024).toFixed(1);
  console.log(`\n✅ Backup guardado: ${nombre} (${kb} KB)\n`);
}

main().catch(err => { console.error('❌', err.message); process.exit(1); });
