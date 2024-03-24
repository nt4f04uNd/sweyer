#!/bin/bash -x
fvm flutter build appbundle --obfuscate --tree-shake-icons --split-debug-info=./build/app/outputs/symbols
