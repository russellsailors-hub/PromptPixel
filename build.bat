@echo off
REM ============================================================
REM  PromptPixel build script
REM  Compiles PromptPixel.ahk -> PromptPixel.exe using Ahk2Exe
REM ============================================================

setlocal

REM Try common Ahk2Exe locations
set "AHK2EXE="
if exist "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" set "AHK2EXE=C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe"
if exist "C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe" set "AHK2EXE=C:\Program Files\AutoHotkey\v2\Compiler\Ahk2Exe.exe"
if exist "%~dp0..\_ahk2exe\Ahk2Exe.exe" set "AHK2EXE=%~dp0..\_ahk2exe\Ahk2Exe.exe"
set "AHKBASE=C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe"

if "%AHK2EXE%"=="" (
    echo.
    echo  ERROR: Ahk2Exe.exe not found.
    echo.
    echo  Install AutoHotkey v2 from https://www.autohotkey.com/download/
    echo  OR extract _ahk2exe.zip into the parent _ahk2exe folder.
    echo.
    pause
    exit /b 1
)

echo Using compiler: %AHK2EXE%
echo.
echo Building PromptPixel.exe...

"%AHK2EXE%" /in "%~dp0PromptPixel.ahk" /out "%~dp0PromptPixel.exe" /base "%AHKBASE%"

if exist "%~dp0PromptPixel.exe" (
    echo.
    echo  SUCCESS: PromptPixel.exe built.
    echo  Location: %~dp0PromptPixel.exe
    echo.
) else (
    echo.
    echo  BUILD FAILED.
    echo.
)

pause
