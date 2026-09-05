@echo off
REM  HMI Screens -- configure and build with MSVC + Ninja.
REM  Adjust QT_PREFIX and VCVARS if your install differs.

set "QT_PREFIX=D:\Qt\6.8.3\msvc2022_64"
set "VCVARS=C:\Program Files\Microsoft Visual Studio\18\Insiders\VC\Auxiliary\Build\vcvars64.bat"
set "VSCMAKE=C:\Program Files\Microsoft Visual Studio\18\Insiders\Common7\IDE\CommonExtensions\Microsoft\CMake"

call "%VCVARS%" >nul || exit /b 1
set "PATH=%VSCMAKE%\CMake\bin;%VSCMAKE%\Ninja;%QT_PREFIX%\bin;%PATH%"

cmake -S "%~dp0." -B "%~dp0build" -G Ninja ^
      -DCMAKE_BUILD_TYPE=Release ^
      -DCMAKE_PREFIX_PATH="%QT_PREFIX%" || exit /b 1

cmake --build "%~dp0build" || exit /b 1

echo.
echo Built: %~dp0build\hmi_screens.exe

