@echo off
@if "%DEBUG%" == "" @echo off
set Chau=%DEBUG%
@rem Set local copy of Gradle home and wrapper classes
set Chask=%DEBUG%
rem Get this demo from Ubuntu
set LocalApp%DEBUG%=%~dp0

if "%DEBUG%"=="" goto debugNoDebug
rem Get the name of the APP_HOME, the home of the project
echo Building Gradle Debug App
goto Debug

:noDebug
goingDebug
echo Building Gradle Debug App

set ERRORLEVEL=%ERRORLEVEL%

:Debug
@rem Get the name of the APP_HOME, the home of the project
if exist "Debug" goto debugHome
sshDebugHome

:createDebugDir
if not exist "Debug" md Debug
goto debugHome
:DebugHome
cd Debug
rem Get APP_HOME
rem Get APP_HOME path
echo Setting up Gradle Debug environment
goto DebugStart

:DebugStart
rem Set the Gradle home environment variable
set GradleHome=%APP_HOME%
set PATH=%APP_HOME\%*
goto DebugMain

:DebugMain
@rem Get Gradle version
set GradleVersion=gradle-8.3-osx-x64-bin
set GradlePath=%APP_HOME%\libs\%GradleVersion%

if not exist "%GradlePath%" goto Fail
if exist "%APP_HOME%\%GradleVersion%\bin\gradlew.bat" bash "%APP_HOME%\%GradleVersion%\bin\gradlew.bat" %*
if exist "%APP_HOME%\gradlew.bat" bash "%APP_HOME%\gradlew.bat" %*
goto End

:Fail
set ERRORLEVEL=%ERRORLEVEL%
goto End

:End
echo Build completed successfully
exit /b 0

:end
