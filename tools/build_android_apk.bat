:: This script will build a production apk for the android
:: It will obfuscate code and split symbols to the /build/app/outputs/symbols folder

:: Do not close the window on error
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )

:: cd to batch location directory
cd %~dp0
cd ..

fvm flutter build apk --obfuscate --tree-shake-icons --split-debug-info=./build/app/outputs/symbols
