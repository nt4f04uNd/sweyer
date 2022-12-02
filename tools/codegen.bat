:: Do not close the window on error
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )

:: cd to batch location directory
cd %~dp0
cd ..

fvm flutter pub run build_runner build --delete-conflicting-outputs
