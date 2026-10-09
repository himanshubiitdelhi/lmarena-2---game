@echo off
setlocal EnableExtensions EnableDelayedExpansion
set GRADLE_VERSION=8.13

if not "%GRADLE_HOME%"=="" if exist "%GRADLE_HOME%\bin\gradle.bat" (
  call :isPinned "%GRADLE_HOME%\bin\gradle.bat"
  if !ERRORLEVEL! EQU 0 (
    call "%GRADLE_HOME%\bin\gradle.bat" %*
    exit /b !ERRORLEVEL!
  )
)

where gradle >nul 2>nul
if !ERRORLEVEL! EQU 0 (
  set SYSTEM_GRADLE_VERSION=
  for /f "tokens=2" %%v in ('gradle --version ^| findstr /b /c:"Gradle "') do set SYSTEM_GRADLE_VERSION=%%v
  if "!SYSTEM_GRADLE_VERSION!"=="%GRADLE_VERSION%" (
    call gradle %*
    exit /b !ERRORLEVEL!
  )
)

set GRADLE_HOME_DIR=%USERPROFILE%\.gradle\wrapper\dists\gradle-%GRADLE_VERSION%-bin\orbit-hop
set GRADLE_BIN=%GRADLE_HOME_DIR%\gradle-%GRADLE_VERSION%\bin\gradle.bat
if not exist "%GRADLE_BIN%" (
  if not exist "%GRADLE_HOME_DIR%" mkdir "%GRADLE_HOME_DIR%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-bin.zip' -OutFile '%TEMP%\gradle-%GRADLE_VERSION%-bin.zip'; if ($?) { Expand-Archive -LiteralPath '%TEMP%\gradle-%GRADLE_VERSION%-bin.zip' -DestinationPath '%GRADLE_HOME_DIR%' -Force }"
  if errorlevel 1 exit /b !ERRORLEVEL!
  del "%TEMP%\gradle-%GRADLE_VERSION%-bin.zip"
)
call "%GRADLE_BIN%" %*
exit /b !ERRORLEVEL!

:isPinned
set PINNED_CANDIDATE_VERSION=
for /f "tokens=2" %%v in ('call "%~1" --version ^| findstr /b /c:"Gradle "') do set PINNED_CANDIDATE_VERSION=%%v
if "!PINNED_CANDIDATE_VERSION!"=="%GRADLE_VERSION%" exit /b 0
exit /b 1
