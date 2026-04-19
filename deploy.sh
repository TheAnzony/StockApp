#!/bin/bash

APP_ID="1:1016052971435:android:2ade449e1f79598e8504ee"
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"

echo "Introduce las notas de esta version:"
read NOTES

echo ""
echo "Construyendo APK..."
flutter build apk --release

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

echo ""
echo "Listo! Tu compañero recibira una notificacion."
