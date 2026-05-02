const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccount.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const sabores = {
  'Exotic escape':       { marca: 'Alfaker', formato: '50gr',  cantidad: 18 },
  'Grapio Green':        { marca: 'Alfaker', formato: '200gr', cantidad: 4  },
  'Green velvet':        { marca: 'Alfaker', formato: '50gr',  cantidad: 36 },
  'Happy bound':         { marca: 'SK',      formato: '50gr',  cantidad: 11 },
  'Ivory gold':          { marca: 'Alfaker', formato: '100gr', cantidad: 8  },
  'Japanise Sunrise':    { marca: 'Alfaker', formato: '50gr',  cantidad: 18 },
  'Magic Love':          { marca: 'Alfaker', formato: '200gr', cantidad: 28 },
  'Malone':              { marca: 'Dozaj',   formato: '200gr', cantidad: 0  },
  'Plata o plomo':       { marca: 'SK',      formato: '200gr', cantidad: 0  },
  'Polar freeze':        { marca: 'Alfaker', formato: '100gr', cantidad: 5  },
  'Sexy Sheba':          { marca: 'SK',      formato: '200gr', cantidad: 3  },
  'Showtime Symphony':   { marca: 'Alfaker', formato: '50gr',  cantidad: 20 },
  'Snowy Fucsia Green':  { marca: 'Alfaker', formato: '200gr', cantidad: 0  },
  'Tropic Treat':        { marca: 'Alfaker', formato: '50gr',  cantidad: 20 },
  'Yellow':              { marca: 'Alfaker', formato: '200gr', cantidad: 10 },
};

admin.firestore()
  .collection('articulos')
  .doc('sabores')
  .set(sabores)
  .then(() => {
    console.log('✅ Sabores migrados correctamente (15 sabores)');
    process.exit(0);
  })
  .catch(err => {
    console.error('❌ Error:', err.message);
    process.exit(1);
  });
