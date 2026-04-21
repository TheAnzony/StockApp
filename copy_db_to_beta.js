const admin = require('firebase-admin');

const serviceAccountProd = require('./serviceAccount.json');
const serviceAccountBeta = require('./serviceAccount_beta.json');

const prodApp = admin.initializeApp({
  credential: admin.credential.cert(serviceAccountProd),
}, 'prod');

const betaApp = admin.initializeApp({
  credential: admin.credential.cert(serviceAccountBeta),
}, 'beta');

const prodDb = admin.firestore(prodApp);
const betaDb = admin.firestore(betaApp);

const COLECCIONES = ['articulos', 'trabajadores', 'ajustes', 'logs_diarios'];

async function copiarColeccion(coleccion) {
  console.log(`Copiando colección: ${coleccion}...`);
  const snap = await prodDb.collection(coleccion).get();
  if (snap.empty) {
    console.log(`  → Vacía, saltando.`);
    return;
  }

  const batch = betaDb.batch();
  snap.docs.forEach(doc => {
    const ref = betaDb.collection(coleccion).doc(doc.id);
    batch.set(ref, doc.data());
  });
  await batch.commit();
  console.log(`  → ${snap.size} documento(s) copiado(s).`);
}

async function main() {
  console.log('Iniciando copia de producción → beta...\n');
  for (const col of COLECCIONES) {
    await copiarColeccion(col);
  }
  console.log('\nCopia completada.');
  process.exit(0);
}

main().catch(err => {
  console.error('Error:', err.message);
  process.exit(1);
});
