@echo off
set source=%~dp0\json\*.json
set target=%appdata%\LazyREST\Data\json\
echo %source%  %target%
xcopy /S /I /Q /Y /F "%source%" "%target%"
pause