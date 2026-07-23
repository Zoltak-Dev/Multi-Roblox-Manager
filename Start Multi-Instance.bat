@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Multi-Roblox Manager
cd /d "%~dp0"

set "PYTHON_CMD="

where py.exe >nul 2>&1
if not errorlevel 1 (
    py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
    if not errorlevel 1 set "PYTHON_CMD=py -3"
)
if not defined PYTHON_CMD (
    where python.exe >nul 2>&1
    if not errorlevel 1 (
        python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
        if not errorlevel 1 set "PYTHON_CMD=python"
    )
)
if not defined PYTHON_CMD (
    for /d %%P in ("%LocalAppData%\Programs\Python\Python*") do (
        if exist "%%~fP\python.exe" (
            "%%~fP\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
            if not errorlevel 1 set PYTHON_CMD="%%~fP\python.exe"
        )
    )
)
if not defined PYTHON_CMD (
    for /d %%P in ("%ProgramFiles%\Python*") do (
        if exist "%%~fP\python.exe" (
            "%%~fP\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
            if not errorlevel 1 set PYTHON_CMD="%%~fP\python.exe"
        )
    )
)
if not defined PYTHON_CMD if defined ProgramFiles(x86) (
    for /d %%P in ("%ProgramFiles(x86)%\Python*") do (
        if exist "%%~fP\python.exe" (
            "%%~fP\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
            if not errorlevel 1 set PYTHON_CMD="%%~fP\python.exe"
        )
    )
)

if not defined PYTHON_CMD (
    echo Python was not found.
    echo Run install.bat first, then try again.
    echo.
    pause
    exit /b 1
)

%PYTHON_CMD% "%~dp0multi_instance.py"
set "UTILITY_EXIT=%ERRORLEVEL%"
if not "%UTILITY_EXIT%"=="0" (
    echo.
    echo The utility stopped because of an error.
    pause
)
exit /b %UTILITY_EXIT%
