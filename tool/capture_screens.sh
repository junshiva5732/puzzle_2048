#!/usr/bin/env bash
# 스토어 스크린샷 원본 캡처. 사용: bash tool/capture_screens.sh <ko|en|ja> [adb serial]
# LOCALE 을 dart-define 으로 강제한 디버그 APK 를 설치하고, 스와이프로 플레이하며 4장을 찍는다.
set +e
LANG_CODE=$1; SERIAL=${2:-emulator-5580}
ADB="/c/Users/Administrator/AppData/Local/Android/sdk/platform-tools/adb.exe -s $SERIAL"
OUT=store/raw/$LANG_CODE; mkdir -p "$OUT"
PKG=com.jun5731.puzzle_2048

flutter build apk --debug --dart-define=LOCALE=$LANG_CODE 2>&1 | tail -1
$ADB install -r build/app/outputs/flutter-apk/app-debug.apk | tail -1
$ADB shell pm clear $PKG >/dev/null
$ADB shell am start -n $PKG/.MainActivity >/dev/null
sleep 8
swipes() { for i in $(seq 1 "$1"); do
  $ADB shell input swipe 200 700 500 700 60; $ADB shell input swipe 360 500 360 900 60
  $ADB shell input swipe 500 700 200 700 60; $ADB shell input swipe 360 500 360 900 60; done; }
swipes 12; sleep 1; $ADB exec-out screencap -p > "$OUT/s_play1.png"
swipes 40; sleep 1; $ADB exec-out screencap -p > "$OUT/s_play2.png"
$ADB shell input tap 647 308; sleep 1; $ADB exec-out screencap -p > "$OUT/s_help.png"
$ADB shell input keyevent BACK; sleep 0.5
for i in $(seq 1 60); do
  $ADB shell input swipe 360 700 360 400 60; $ADB shell input swipe 200 700 500 700 60
  $ADB shell input swipe 360 500 360 900 60; $ADB shell input swipe 500 700 200 700 60; done
sleep 1; $ADB exec-out screencap -p > "$OUT/s_over.png"
echo "captured: $OUT"
