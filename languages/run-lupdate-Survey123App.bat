@echo off

rem The lupdate tool produces or updates ts files from source code translatable strings

cd ..

%USERPROFILE%\Applications\ArcGIS\AppStudio\bin\lupdate.exe . -extensions qml -ts languages/Survey123App_en.ts

pause
