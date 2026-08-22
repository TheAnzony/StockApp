// Migracion unica: mueve las recetas hardcodeadas de carta_constants.dart a
// Firestore (articulos/mezclas), limpiando los sufijos "(Marca)" del nombre
// del ingrediente para que coincidan exactamente con las claves reales del
// documento articulos/sabores.
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const recetas = [
  { nombre: 'Cítrica', ingredientes: [
    { nombre: 'Yellow', porcentaje: 90 },
    { nombre: 'Polar freeze', porcentaje: 10 },
  ]},
  { nombre: 'Batido de Menta', ingredientes: [
    { nombre: 'Polar freeze', porcentaje: 10 },
    { nombre: 'Green velvet', porcentaje: 40 },
    { nombre: 'Big Green', porcentaje: 40 },
    { nombre: 'Ivory gold', porcentaje: 10 },
  ]},
  { nombre: 'Frutos Rojos', ingredientes: [
    { nombre: 'Exotic escape', porcentaje: 60 },
    { nombre: 'Snowy Fucsia Green', porcentaje: 40 },
  ]},
  { nombre: 'Tropical Vibes', ingredientes: [
    { nombre: 'Tropic Treat', porcentaje: 20 },
    { nombre: 'Sexy Sheba', porcentaje: 40 },
    { nombre: 'Magic Love', porcentaje: 40 },
  ]},
  { nombre: 'Paraíso Frutal', ingredientes: [
    { nombre: 'Magic Love', porcentaje: 100 },
  ]},
  { nombre: 'Dulce', ingredientes: [
    { nombre: 'Happy hound', porcentaje: 100 },
  ]},
  { nombre: 'Sandía Melón', ingredientes: [
    { nombre: 'Plata o plomo', porcentaje: 50 },
    { nombre: 'Malone', porcentaje: 50 },
  ]},
  { nombre: 'Floral', ingredientes: [
    { nombre: 'Yellow', porcentaje: 40 },
    { nombre: 'Grapio Green', porcentaje: 40 },
    { nombre: 'Japanise Sunrise', porcentaje: 20 },
  ]},
];

async function main() {
  const ref = db.collection('articulos').doc('mezclas');
  const snap = await ref.get();
  if (snap.exists) {
    console.log('articulos/mezclas ya existe, no se sobreescribe. Contenido actual:');
    console.log(JSON.stringify(snap.data(), null, 2));
    return;
  }
  await ref.set({ recetas });
  console.log(`Migradas ${recetas.length} recetas a articulos/mezclas`);
}

main().then(() => process.exit(0)).catch(err => { console.error(err); process.exit(1); });
