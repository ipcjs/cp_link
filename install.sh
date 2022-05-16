#!/bin/sh

output="."
if [ -n "$DROPBOX" ]; then
    output="$DROPBOX/bin"
fi

dart compile exe -o "$output/cp-link.exe" bin/cp_link.dart
dart compile exe -o "$output/defender-danger-list.exe" bin/defender_danger_list.dart
dart compile exe -o "$output/dart-fix-rules.exe" bin/dart_fix_rules.dart
