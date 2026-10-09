@echo off
setlocal

:: Move to the project root directory
cd /d "%~dp0.."

echo [1/2] Building and patching Game.swf...
java patcher/Patcher.java
if %errorlevel% neq 0 goto :error

echo [2/2] Copying patched game into loader...
if not exist "loader\gamefiles" mkdir "loader\gamefiles"

set "RETRY_COUNT=0"
:copy_retry
copy /y assets\Game.swf loader\gamefiles\Game.swf >nul 2>&1
if %errorlevel% neq 0 (
    set /a RETRY_COUNT+=1
    if %RETRY_COUNT% leq 3 (
        ping 127.0.0.1 -n 2 >nul
        goto :copy_retry
    )
    copy /y assets\Game.swf loader\gamefiles\Game.swf
    goto :error
)
echo         1 file(s) copied.
if exist "assets\Map-UI_r38.swf" (
    copy /y assets\Map-UI_r38.swf loader\gamefiles\Map-UI_r38.swf >nul 2>&1
)
if exist "loader\gamefiles\world-map.swf" (
    del /q loader\gamefiles\world-map.swf >nul 2>&1
)
if exist "assets\spiderbook3.swf" (
    copy /y assets\spiderbook3.swf loader\gamefiles\spiderbook3.swf >nul 2>&1
)

echo.
echo ========================================================
echo GAME.SWF, SPIDERBOOK3.SWF & MAP-UI_R38.SWF BUILD SUCCESSFUL!
echo Output files:
echo   - assets\Game.swf
echo   - loader\gamefiles\Game.swf
echo   - loader\gamefiles\Map-UI_r38.swf
echo   - loader\gamefiles\spiderbook3.swf
echo ========================================================
pause
exit /b 0

:error
echo.
echo ========================================================
echo BUILD FAILED!
echo ========================================================
pause
exit /b 1
