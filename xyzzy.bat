@echo off

setlocal
set XYZZYHOME=%~dp0
set XYZZYCONFIGPATH=
set PATH=%XYZZYHOME%\bin;%PATH%

start %XYZZYHOME%\xyzzy.exe %*
