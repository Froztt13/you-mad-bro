@echo off
setlocal

:: Move to the project root directory
cd /d "%~dp0.."

set KEYSTORE_NAME=keystore.jks
set STOREPASS=123654
set ALIAS=123

echo [1/5] Building and patching Game.swf...
java patcher/Patcher.java
if %errorlevel% neq 0 goto :error

echo [2/5] Copying patched game into loader...
copy /y assets\Game.swf loader\gamefiles\Game.swf
if %errorlevel% neq 0 goto :error
if exist "assets\Map-UI_r38.swf" (
    copy /y assets\Map-UI_r38.swf loader\gamefiles\Map-UI_r38.swf >nul 2>&1
)
if exist "loader\gamefiles\world-map.swf" (
    del /q loader\gamefiles\world-map.swf >nul 2>&1
)
if exist "assets\spiderbook3.swf" (
    copy /y assets\spiderbook3.swf loader\gamefiles\spiderbook3.swf >nul 2>&1
)
if exist "assets\charselect.swf" (
    copy /y assets\charselect.swf loader\gamefiles\charselect.swf >nul 2>&1
)

echo [3/5] Compiling the loader...
call amxmlc -optimize=true -inline=true -omit-trace-statements=true -library-path+=ane/BatteryOptimizer.swc -output loader/Loader.swf loader/src/Main.as
if %errorlevel% neq 0 goto :error

echo [4/5] Checking keystore...
if not exist %KEYSTORE_NAME% (
    echo Generating new keystore...
    keytool -genkeypair -alias %ALIAS% -keyalg RSA -keysize 2048 -validity 10000 ^
      -keystore %KEYSTORE_NAME% -storepass %STOREPASS% -keypass %STOREPASS% ^
      -dname "CN=Unknown, OU=Unknown, O=Unknown, L=Unknown, S=Unknown, C=US"
) else (
    echo Keystore already exists, skipping.
)

echo [5/5] Packaging the APK...
call adt -package -target apk-captive-runtime -arch armv8 ^
  -storetype JKS -keystore %KEYSTORE_NAME% -storepass %STOREPASS% -keypass %STOREPASS% ^
  YouMadBro-armv8.apk loader/app.xml ^
  -extdir ane ^
  -C loader Loader.swf icons gamefiles

if %errorlevel% neq 0 goto :error

echo.
echo BUILD SUCCESSFUL!
pause
exit /b 0

:error
echo.
echo BUILD FAILED!
pause
exit /b 1