@echo off
rem Batch Script for building zip file containing pdf2svg windows files
rem
rem Usage: Set Architecture to select the correct files.
rem Files to be packed are assumed to be in build\dist-32bits or 
rem build\dist-64bits respectively

rem Some variables
set Pdf2SvgVersion=0.2.3
set Architecture=64
set DestPath=build
set SourcePath=%DestPath%\dist-%Architecture%bits
set TempPackagePath=pdf2svg-%Architecture%bits
set PackageName=pdf2svg-windows-%Pdf2SvgVersion%-%Architecture%bit

rem Delete old stuff and setup new directory structure
if exist %TempPackagePath% (
   echo Directory %TempPackagePath% already exists, content will be deleted!
   rmdir /S /Q %TempPackagePath%
)
echo Creating new directory %TempPackagePath%
mkdir %TempPackagePath%

rem Copy files
copy %SourcePath%\*.* %TempPackagePath%

rem If we have zip available on this machine build a zip package
WHERE zip >nul 2>nul
IF %ERRORLEVEL% EQU 0 zip -r %DestPath%\%PackageName%.zip %TempPackagePath%

rem Verzeichnis mit temporären Dateien löschen
rmdir /S /Q %TempPackagePath%

exit /B

rem Copy helper function
:copy_func
echo Copying file %1 into directory %2
copy %1 %2
exit /B
