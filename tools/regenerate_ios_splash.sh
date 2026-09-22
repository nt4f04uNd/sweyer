#!/bin/bash -ex

cd "$(dirname "$0")/.."

fvm flutter pub get
fvm dart run flutter_native_splash:create
