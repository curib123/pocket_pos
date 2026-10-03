#!/usr/bin/env bash
set -euo pipefail

adb install -r build/app/outputs/flutter-apk/app-release.apk
adb shell svc wifi disable
adb shell svc data disable
adb logcat -c
adb shell am start -W -n com.nexttech.nextpos/.MainActivity

# Wait for SQLite initialization and the Flutter home screen to complete.
# A successful native activity launch alone does not prove Dart startup worked.
mkdir -p build/release-smoke
for attempt in $(seq 1 20); do
  adb shell uiautomator dump /sdcard/pocket-inventory-startup.xml >/dev/null
  adb pull /sdcard/pocket-inventory-startup.xml build/release-smoke/startup.xml >/dev/null
  if grep -q 'Inventory' build/release-smoke/startup.xml; then
    adb logcat -d > build/release-smoke/startup.log
    if grep -E 'FATAL EXCEPTION|Unhandled Exception|Queries can be performed using SQLiteDatabase' build/release-smoke/startup.log; then
      echo 'Android startup reported a fatal error.' >&2
      exit 1
    fi
    echo 'Release APK opened the inventory home screen with Wi-Fi and mobile data disabled.'
    exit 0
  fi
  sleep 2
done

adb logcat -d > build/release-smoke/startup.log
cat build/release-smoke/startup.log
echo 'Release APK did not reach the inventory home screen.' >&2
exit 1
