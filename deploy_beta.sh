#!/bin/bash

APP_ID="1:5799277496:android:0c885bc390ca02412d154d"
APK_PATH="build/app/outputs/flutter-apk/app-beta-release.apk"

VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')

echo "Introduce las notas de esta version beta:"
read NOTES

echo ""
echo "Construyendo APK beta v$VERSION..."
flutter build apk --release --flavor beta --dart-define=FLAVOR=beta

if [ $? -ne 0 ]; then
  echo "Error al construir el APK beta"
  exit 1
fi

echo ""
echo "Subiendo a Firebase App Distribution (beta)..."
firebase appdistribution:distribute "$APK_PATH" \
  --app "$APP_ID" \
  --project "stock-cachimbas-beta" \
  --groups "beta" \
  --release-notes "$NOTES"

if [ $? -ne 0 ]; then
  echo "Error al subir a Firebase"
  exit 1
fi

echo ""
echo "Listo! Version beta $VERSION subida."
