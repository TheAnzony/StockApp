#!/bin/bash

APP_ID="1:1016052971435:android:2ade449e1f79598e8504ee"
APK_PATH="build/app/outputs/flutter-apk/app-prod-release.apk"

VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "Introduce las notas de esta version:"
read NOTES

echo ""
echo "Construyendo APK v$VERSION..."
flutter build apk --release --flavor prod --dart-define=FLAVOR=prod

if [ $? -ne 0 ]; then
  echo "Error al construir el APK"
  exit 1
fi

echo ""
echo "Subiendo a Firebase App Distribution..."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --groups "testers" \
  --release-notes "$NOTES"

if [ $? -ne 0 ]; then
  echo "Error al subir a Firebase"
  exit 1
fi

echo ""
echo "Actualizando min_version en Firestore a $VERSION..."
node update_version.js "$VERSION"

if [ $? -ne 0 ]; then
  echo "Error al actualizar Firestore"
  exit 1
fi

echo ""
echo "Listo! Version $VERSION subida y Firestore actualizado."
