@echo off
REM  Run the built cluster without installing Qt system-wide.
set "QT_PREFIX=D:\Qt\6.8.3\msvc2022_64"
set "PATH=%QT_PREFIX%\bin;%PATH%"
start "" "%~dp0build\hmi_screens.exe"
