#!/bin/bash -x
fvm flutter pub run build_runner build --delete-conflicting-outputs
tools/format.sh
