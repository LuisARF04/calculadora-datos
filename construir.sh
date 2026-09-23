#!/usr/bin/env bash
# Uso: bash construir.sh usuario     (APK para tus clientes)
#      bash construir.sh admin       (APK de administrador, solo para ti)
set -euo pipefail

VARIANTE="${1:?Falta la variante: usuario o admin}"
case "$VARIANTE" in
  usuario)
    APP_ID="com.calculadora.importacion"
    APP_NOMBRE="Calculadora"
    ICONO="app-icon.png"
    FONDO="37,99,235"
    SALIDA="Calculadora.apk" ;;
  admin)
    APP_ID="com.calculadora.importacion.admin"
    APP_NOMBRE="Calculadora Admin"
    ICONO="app-icon-admin.png"
    FONDO="15,23,42"
    SALIDA="Calculadora-Admin.apk" ;;
  *) echo "Variante desconocida: $VARIANTE"; exit 1 ;;
esac
echo "=== Construyendo $VARIANTE ($APP_ID) ==="

# 1) Carpeta web de esta variante
rm -rf www assets android
mkdir -p www assets
cp index.html manifest.webmanifest icon-192.png icon-512.png icon-maskable-512.png apple-touch-icon.png favicon-32.png www/
if [ "$VARIANTE" = "admin" ]; then
  sed -i 's/const MODO_ADMIN = false;/const MODO_ADMIN = true;/' www/index.html
  grep -q 'const MODO_ADMIN = true;' www/index.html   # si no se aplicó, se detiene aquí
fi

# 2) Configuración de Capacitor (nombre e identificador distintos para cada APK)
cat > capacitor.config.json <<JSON
{
  "appId": "$APP_ID",
  "appName": "$APP_NOMBRE",
  "webDir": "www",
  "server": { "androidScheme": "https" },
  "android": { "backgroundColor": "#f5f7fa" }
}
JSON

# 3) Proyecto Android
npm install --no-audit --no-fund
npx cap add android
npx cap sync android

# 4) Íconos (si algo falla se usa el ícono por defecto y la compilación sigue)
cp "$ICONO" assets/icon-only.png
cp app-icon-foreground.png assets/icon-foreground.png
python3 - "$FONDO" <<'PY'
import sys, zlib, struct
r, g, b = [int(x) for x in sys.argv[1].split(",")]
w = h = 1024
raw = b"".join(b"\x00" + bytes((r, g, b)) * w for _ in range(h))
def chunk(t, d):
    return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
open("assets/icon-background.png", "wb").write(png)
PY
npx --yes @capacitor/assets generate --android || echo "Aviso: no se pudieron generar los íconos; se usa el de por defecto"
RES=android/app/src/main/res
if ! ls $RES/mipmap-*/ic_launcher_background.* >/dev/null 2>&1; then
  echo "Falta el fondo del ícono adaptable: se quitan sus XML para que no falle"
  rm -f $RES/mipmap-anydpi-v26/ic_launcher.xml $RES/mipmap-anydpi-v26/ic_launcher_round.xml
fi

# 5) Compilar
( cd android
  yes | sdkmanager --licenses > /dev/null || true
  sed -i "s/versionCode 1\$/versionCode ${GITHUB_RUN_NUMBER:-1}/" app/build.gradle || true
  chmod +x gradlew
  ./gradlew assembleRelease --no-daemon )

# 6) Firmar
BT=$(ls -d "$ANDROID_HOME"/build-tools/* | sort -V | tail -1)
SRC=$(find android/app/build/outputs/apk/release -name '*.apk' | head -1)
echo "APK sin firmar: $SRC"
"$BT/zipalign" -p -f 4 "$SRC" alineado.apk
"$BT/apksigner" sign --ks calculadora.keystore --ks-key-alias calculadora \
  --ks-pass pass:calculadora123 --key-pass pass:calculadora123 \
  --out "$SALIDA" alineado.apk
"$BT/apksigner" verify "$SALIDA"
rm -f alineado.apk
echo "=== Listo: $SALIDA ==="
