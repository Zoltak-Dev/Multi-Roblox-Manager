@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Multi-Roblox Manager - Installer

set "REPO_URL=https://github.com/Zoltak-Dev/Multi-Roblox-Manager.git"
set "PROJECT_NAME=Multi-Roblox-Manager"
set "PYTHON_CMD="
set "GIT_CMD="

echo ==============================================================
echo   Multi-Roblox Manager - Automatic Installer
echo ==============================================================
echo.

call :find_desktop
if not defined DESKTOP_DIR (
    call :fail "Your Windows Desktop folder could not be located."
    exit /b 1
)

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"
for %%I in ("%DESKTOP_DIR%\%PROJECT_NAME%") do set "TARGET_DIR=%%~fI"

call :find_python
if not defined PYTHON_CMD (
    echo Python 3.8 or newer was not found.
    choice /C YN /N /M "Install Python automatically now? [Y/N]: "
    if errorlevel 2 (
        call :fail "Python is required. Installation cancelled."
        exit /b 1
    )
    call :install_python
    if errorlevel 1 exit /b 1
    call :find_python
    if not defined PYTHON_CMD (
        call :fail "Python was installed but could not be located. Restart Windows, then run this installer again."
        exit /b 1
    )
)
echo [OK] Python is available.

call :find_git
if not defined GIT_CMD (
    echo Git was not found.
    choice /C YN /N /M "Install Git automatically now? [Y/N]: "
    if errorlevel 2 (
        call :fail "Git is required. Installation cancelled."
        exit /b 1
    )
    call :install_git
    if errorlevel 1 exit /b 1
    call :find_git
    if not defined GIT_CMD (
        call :fail "Git was installed but could not be located. Restart Windows, then run this installer again."
        exit /b 1
    )
)
echo [OK] Git is available.
echo.

rem A complete downloaded or cloned copy can be prepared in place.
if exist "%SCRIPT_DIR%\multi_instance.py" if exist "%SCRIPT_DIR%\requirements.txt" if exist "%SCRIPT_DIR%\Start Multi-Instance.bat" (
    set "TARGET_DIR=%SCRIPT_DIR%"
    echo A complete project folder was detected next to this installer.
    echo It will be prepared in place; no additional clone is needed.
    call :validate_project "%SCRIPT_DIR%"
    if errorlevel 1 exit /b 1
    call :install_project_requirements "%SCRIPT_DIR%"
    if errorlevel 1 exit /b 1
    goto :success
)

if exist "%TARGET_DIR%\" (
    echo An existing installation was found:
    echo   "%TARGET_DIR%"
    echo.
    echo Replacing it will keep the old folder as a timestamped backup.
    choice /C YN /N /M "Replace the existing installation? [Y/N]: "
    if errorlevel 2 (
        echo.
        echo Installation cancelled. The existing folder was not changed.
        call :wait_seconds 5
        exit /b 0
    )
)

set "TEMP_TARGET=%DESKTOP_DIR%\%PROJECT_NAME%.installing-%RANDOM%-%RANDOM%"
if exist "%TEMP_TARGET%\" (
    call :fail "A temporary install folder already exists. Run the installer again."
    exit /b 1
)

echo Cloning the latest public version...
%GIT_CMD% -c core.longpaths=true clone --depth 1 --single-branch --branch main "%REPO_URL%" "%TEMP_TARGET%"
if not "%ERRORLEVEL%"=="0" (
    call :cleanup_temp
    call :fail "Git could not clone the repository. Check your internet connection and try again."
    exit /b 1
)

rem Validate the new copy completely before touching an existing installation.
call :validate_project "%TEMP_TARGET%"
if errorlevel 1 (
    call :cleanup_temp
    exit /b 1
)
call :install_project_requirements "%TEMP_TARGET%"
if errorlevel 1 (
    call :cleanup_temp
    exit /b 1
)

if exist "%TARGET_DIR%\" (
    call :backup_existing
    if errorlevel 1 (
        call :cleanup_temp
        exit /b 1
    )
)

move "%TEMP_TARGET%" "%TARGET_DIR%" >nul
if errorlevel 1 (
    if defined BACKUP_DIR move "%BACKUP_DIR%" "%TARGET_DIR%" >nul
    call :cleanup_temp
    call :fail "The new folder could not be put in place. The previous version was restored when possible."
    exit /b 1
)
echo [OK] Repository installed on the Desktop.

:success
echo.
echo ==============================================================
echo   SUCCESS: Multi-Roblox Manager is ready.
echo ==============================================================
echo Location:
echo   "%TARGET_DIR%"
echo.
echo Open "Start Multi-Instance.bat" whenever you want to enable it.
start "" explorer.exe "%TARGET_DIR%"
echo This window will close in 8 seconds...
call :wait_seconds 8
exit /b 0


:find_desktop
set "DESKTOP_DIR="
for /f "usebackq delims=" %%D in (`powershell.exe -NoProfile -Command "[Environment]::GetFolderPath('Desktop')" 2^>nul`) do (
    if not defined DESKTOP_DIR set "DESKTOP_DIR=%%D"
)
if not defined DESKTOP_DIR if exist "%USERPROFILE%\Desktop\" set "DESKTOP_DIR=%USERPROFILE%\Desktop"
exit /b 0


:find_python
set "PYTHON_CMD="
where py.exe >nul 2>&1
if not errorlevel 1 (
    py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
    if not errorlevel 1 (
        set "PYTHON_CMD=py -3"
        exit /b 0
    )
)
where python.exe >nul 2>&1
if not errorlevel 1 (
    python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
    if not errorlevel 1 (
        set "PYTHON_CMD=python"
        exit /b 0
    )
)
for /d %%P in ("%LocalAppData%\Programs\Python\Python*") do (
    if exist "%%~fP\python.exe" (
        "%%~fP\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
        if not errorlevel 1 (
            set PYTHON_CMD="%%~fP\python.exe"
            exit /b 0
        )
    )
)
for /d %%P in ("%ProgramFiles%\Python*") do (
    if exist "%%~fP\python.exe" (
        "%%~fP\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
        if not errorlevel 1 (
            set PYTHON_CMD="%%~fP\python.exe"
            exit /b 0
        )
    )
)
if defined ProgramFiles(x86) for /d %%P in ("%ProgramFiles(x86)%\Python*") do (
    if exist "%%~fP\python.exe" (
        "%%~fP\python.exe" -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 8) else 1)" >nul 2>&1
        if not errorlevel 1 (
            set PYTHON_CMD="%%~fP\python.exe"
            exit /b 0
        )
    )
)
exit /b 0


:find_git
set "GIT_CMD="
where git.exe >nul 2>&1
if not errorlevel 1 (
    git --version >nul 2>&1
    if not errorlevel 1 (
        set "GIT_CMD=git"
        exit /b 0
    )
)
if exist "%ProgramFiles%\Git\cmd\git.exe" (
    "%ProgramFiles%\Git\cmd\git.exe" --version >nul 2>&1
    if not errorlevel 1 (
        set GIT_CMD="%ProgramFiles%\Git\cmd\git.exe"
        exit /b 0
    )
)
if exist "%LocalAppData%\Programs\Git\cmd\git.exe" (
    "%LocalAppData%\Programs\Git\cmd\git.exe" --version >nul 2>&1
    if not errorlevel 1 (
        set GIT_CMD="%LocalAppData%\Programs\Git\cmd\git.exe"
        exit /b 0
    )
)
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" (
    "%ProgramFiles(x86)%\Git\cmd\git.exe" --version >nul 2>&1
    if not errorlevel 1 (
        set GIT_CMD="%ProgramFiles(x86)%\Git\cmd\git.exe"
        exit /b 0
    )
)
exit /b 0


:install_python
where winget.exe >nul 2>&1
if errorlevel 1 (
    start "" "https://www.python.org/downloads/windows/"
    call :fail "winget is unavailable. Install Python from https://www.python.org/downloads/ and run this file again."
    exit /b 1
)
echo Installing Python with winget...
winget install --id Python.Python.3.14 --exact --source winget --accept-package-agreements --accept-source-agreements
if "%ERRORLEVEL%"=="0" exit /b 0
winget install --id Python.Python.3.13 --exact --source winget --accept-package-agreements --accept-source-agreements
if "%ERRORLEVEL%"=="0" exit /b 0
winget install --id Python.Python.3.12 --exact --source winget --accept-package-agreements --accept-source-agreements
if "%ERRORLEVEL%"=="0" exit /b 0
call :fail "winget could not install a supported Python version."
exit /b 1


:install_git
where winget.exe >nul 2>&1
if errorlevel 1 (
    start "" "https://git-scm.com/download/win"
    call :fail "winget is unavailable. Install Git from https://git-scm.com/download/win and run this file again."
    exit /b 1
)
echo Installing Git with winget...
winget install --id Git.Git --exact --source winget --accept-package-agreements --accept-source-agreements
if not "%ERRORLEVEL%"=="0" (
    call :fail "winget could not install Git."
    exit /b 1
)
exit /b 0


:timestamp
set "STAMP="
for /f "usebackq delims=" %%T in (`powershell.exe -NoProfile -Command "Get-Date -Format 'yyyyMMdd-HHmmss'" 2^>nul`) do (
    if not defined STAMP set "STAMP=%%T"
)
if not defined STAMP set "STAMP=%RANDOM%-%RANDOM%"
exit /b 0


:backup_existing
call :timestamp
set "BACKUP_DIR=%DESKTOP_DIR%\%PROJECT_NAME%.backup-%STAMP%"
if exist "%BACKUP_DIR%\" (
    call :fail "The backup destination already exists. No folder was replaced."
    exit /b 1
)
move "%TARGET_DIR%" "%BACKUP_DIR%" >nul
if errorlevel 1 (
    call :fail "The existing folder is in use or could not be moved. Close it and try again."
    exit /b 1
)
echo [OK] Previous version saved as:
echo   "%BACKUP_DIR%"
exit /b 0


:validate_project
set "CHECK_DIR=%~f1"
if not exist "%CHECK_DIR%\multi_instance.py" (
    call :fail "The downloaded repository is incomplete: multi_instance.py is missing."
    exit /b 1
)
if not exist "%CHECK_DIR%\Start Multi-Instance.bat" (
    call :fail "The downloaded repository is incomplete: Start Multi-Instance.bat is missing."
    exit /b 1
)
if not exist "%CHECK_DIR%\requirements.txt" (
    call :fail "The downloaded repository is incomplete: requirements.txt is missing."
    exit /b 1
)
%PYTHON_CMD% -c "import pathlib,sys; compile(pathlib.Path(sys.argv[1]).read_bytes(), sys.argv[1], 'exec')" "%CHECK_DIR%\multi_instance.py" >nul 2>&1
if not "%ERRORLEVEL%"=="0" (
    call :fail "multi_instance.py is invalid or incompatible with the installed Python version."
    exit /b 1
)
exit /b 0


:install_project_requirements
set "REQUIREMENTS_DIR=%~f1"
echo.
echo Preparing Python and installing requirements...
%PYTHON_CMD% -m pip --version >nul 2>&1
if errorlevel 1 %PYTHON_CMD% -m ensurepip --upgrade >nul 2>&1
%PYTHON_CMD% -m pip install --disable-pip-version-check --no-input -r "%REQUIREMENTS_DIR%\requirements.txt"
if not "%ERRORLEVEL%"=="0" (
    call :fail "Python requirements could not be installed. No existing installation was replaced."
    exit /b 1
)
exit /b 0


:cleanup_temp
if defined TEMP_TARGET if exist "%TEMP_TARGET%\" rmdir /S /Q "%TEMP_TARGET%"
exit /b 0


:wait_seconds
powershell.exe -NoProfile -Command "Start-Sleep -Seconds %~1" >nul 2>&1
if errorlevel 1 ping.exe 127.0.0.1 -n %~1 >nul 2>&1
exit /b 0


:fail
echo.
echo ==============================================================
echo   ERROR
echo ==============================================================
echo %~1
echo.
pause
exit /b 0
