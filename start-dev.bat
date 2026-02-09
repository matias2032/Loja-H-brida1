@echo off
echo ========================================
echo   Iniciando Backend + Frontend
echo ========================================

cd "C:\desenvolvimento hibrido\loja1\backend\projectohibrido"
start cmd /k "mvnw spring-boot:run"

timeout /t 15 /nobreak

cd "C:\desenvolvimento hibrido\loja1\frontend\vendedor_app"
@REM cd "C:\desenvolvimento hibrido\loja1\frontend\cliente_web"
start cmd /k "flutter run -d windows"

echo ========================================
echo   Tudo iniciado!
echo ========================================