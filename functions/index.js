const { onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

initializeApp();

// Al eliminar un trabajador de Firestore, borra también su cuenta de Firebase Auth
exports.eliminarUsuarioAuth = onDocumentDeleted(
  { document: "trabajadores/{docId}", region: "europe-west1" },
  async (event) => {
    const data = event.data.data();
    const email = data?.email_auth;
    if (!email) return;

    try {
      const user = await getAuth().getUserByEmail(email);
      await getAuth().deleteUser(user.uid);
      console.log(`Usuario Auth eliminado: ${email}`);
    } catch (err) {
      if (err.code !== "auth/user-not-found") {
        console.error(`Error eliminando ${email}:`, err);
      }
    }
  }
);

// Cambia el PIN (contraseña) de un trabajador. Solo accesible estando autenticado.
exports.cambiarPin = onCall(
  { region: "europe-west1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Debes estar autenticado.");
    }

    const { email, nuevoPin } = request.data;
    if (!email || !nuevoPin) {
      throw new HttpsError("invalid-argument", "Email y PIN son requeridos.");
    }

    try {
      const user = await getAuth().getUserByEmail(email);
      await getAuth().updateUser(user.uid, { password: `${nuevoPin}00` });
      return { success: true };
    } catch (err) {
      throw new HttpsError("internal", err.message);
    }
  }
);
