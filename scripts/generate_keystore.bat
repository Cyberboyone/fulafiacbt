@echo off
REM Generate a signing keystore for Play Store release builds.
REM Run this from the project root: scripts\generate_keystore.bat
REM The resulting keystore.jks should be kept SECRET and backed up safely.

set KEYSTORE_PATH=android\app\keystore.jks
set KEY_ALIAS=fulafiacbt
set VALIDITY=10000

keytool -genkey -v ^
  -keystore %KEYSTORE_PATH% ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity %VALIDITY% ^
  -alias %KEY_ALIAS% ^
  -storepass changeit123 ^
  -keypass changeit123 ^
  -dname "CN=Fulafia CBT, OU=Education, O=Siyayya, L=Lafia, ST=Nasarawa, C=NG"

echo.
echo Keystore created at %KEYSTORE_PATH%
echo.
echo Next steps to configure GitHub Actions signing:
echo 1. Convert keystore to base64: certutil -encode android\app\keystore.jks keystore.txt
echo    (then copy the base64 body without headers into the ANDROID_KEYSTORE_BASE64 secret)
echo 2. Add GitHub secret ANDROID_KEY_PASSWORD = changeit123
echo 3. Update build-aab.yml KEY_ALIAS if different from "fulafiacbt"
echo.
echo KEEP keystore.jks AND the password SAFE. If lost, you cannot update the app on Play Store.
