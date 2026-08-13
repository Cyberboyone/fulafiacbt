@echo off
REM Generate a signing keystore for Play Store release builds.
REM Run this from the project root: scripts\generate_keystore.bat
REM The resulting keystore.jks should be kept SECRET and backed up safely.

set KEYSTORE_PATH=android\app\keystore.jks
set KEY_ALIAS=fulafiacbt
set VALIDITY=10000
set KEY_PASSWORD=changeit123

keytool -genkey -v ^
  -keystore %KEYSTORE_PATH% ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity %VALIDITY% ^
  -alias %KEY_ALIAS% ^
  -storepass %KEY_PASSWORD% ^
  -keypass %KEY_PASSWORD% ^
  -dname "CN=Fulafia CBT, OU=Education, O=Siyayya, L=Lafia, ST=Nasarawa, C=NG"

echo.
echo Keystore created at %KEYSTORE_PATH%
echo.

REM --- Generate base64 for GitHub secret (clean, no headers) ---
echo Encoding keystore to base64...
certutil -encode %KEYSTORE_PATH% keystore_b64_raw.txt >nul

REM Strip header/footer and line breaks so the secret is one clean line
powershell -Command "$raw = Get-Content keystore_b64_raw.txt -Raw; $b64 = ($raw -split \"`n\" | Where-Object { $_ -notmatch '-----' }) -join ''; Set-Content -NoNewline keystore_b64.txt $b64"

echo.
echo ============================================================
echo  DONE. Two files were created:
echo.
echo  1) android\app\keystore.jks   (KEEP THIS SECRET - backup it!)
echo  2) keystore_b64.txt           (copy its ENTIRE contents)
echo.
echo  NEXT: Add these as GitHub repository secrets:
echo.
echo  Secret name : ANDROID_KEYSTORE_BASE64
echo  Secret value: (paste the full contents of keystore_b64.txt)
echo.
echo  Secret name : ANDROID_KEY_PASSWORD
echo  Secret value: %KEY_PASSWORD%
echo ============================================================
echo.
echo KEEP keystore.jks AND the password SAFE. If lost, you cannot
echo update the app on the Play Store.
