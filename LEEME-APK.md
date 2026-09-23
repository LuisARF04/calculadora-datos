# Dos APK: Calculadora (clientes) y Calculadora Admin (solo tú)

Los precios y productos viven en el archivo `precios.json` del repositorio público
`calculadora-datos`. La app Admin lo edita; la app de clientes lo lee al abrirse.

## Preparación (una sola vez)
1. Crea un repositorio PUBLIC llamado `calculadora-datos` marcando "Add a README file".
2. Crea un token en GitHub: Settings > Developer settings > Personal access tokens >
   Fine-grained tokens > Generate new token.
   - Repository access: Only select repositories > calculadora-datos
   - Permissions > Repository permissions > Contents: Read and write
   - Guarda el token (empieza con `github_pat_`). No lo compartas.
3. Sube todos los archivos de este zip a tu repositorio de la app (reemplazan a los anteriores)
   y pega el nuevo `.github/workflows/build-apk.yml` (está en el chat).
4. Cuando termine la compilación, en Releases descarga los dos APK:
   - `Calculadora.apk`: para tus clientes.
   - `Calculadora-Admin.apk`: solo para ti (no lo compartas).

## Uso diario
En la app Admin toca el engranaje: cambia el costo por libra y la tasa, agrega productos con
sus libras y pulsa "Publicar cambios". La primera vez pega el token. Las apps de clientes
reciben los cambios al abrirse (pueden tardar unos minutos).
