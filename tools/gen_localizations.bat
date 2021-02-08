:: This script will generate arb from the localization dart file and generate messages from arb

:: Do not close the window on error
if not defined in_subprocess (cmd /k set in_subprocess=y ^& %0 %*) & exit )

:: cd to batch location directory
cd %~dp0
cd ..

call flutter pub run intl_translation:extract_to_arb --output-dir=lib/localization/arb lib/localization/localization.dart

call flutter pub run intl_translation:generate_from_arb --output-dir=lib/localization/gen --no-use-deferred-loading ^
lib/localization/arb/intl_en.arb lib/localization/arb/intl_ru.arb lib/localization/arb/intl_messages.arb ^
lib/localization/localization.dart
