#!/bin/sh

output="."
if [ -n "$DROPBOX" ]; then
    output="$DROPBOX/bin"
fi

dart compile exe -o "$output/cp_link.exe" bin/cp_link.dart
dart compile exe -o "$output/defender_danger_list.exe" bin/defender_danger_list.dart
