const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');

const version = process.argv[2];
if (!version) {
  console.error('Falta la version como argumento');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

admin.firestore()
  .collection('ajustes')
  .doc('configuracion')
  .update({ min_version: version })
  .then(() => {
    console.log(`min_version actualizada a ${version} en Firestore`);
    process.exit(0);
  })
  .catch((err) => {
    console.error('Error actualizando Firestore:', err.message);
    process.exit(1);
  });
