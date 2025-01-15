#!/bin/bash

# 현재 키보드 입력 소스 정보 가져오기
INPUT_SOURCE=$(defaults read ~/Library/Preferences/com.apple.HIToolbox.plist AppleSelectedInputSources)

echo "INPUT_SOURCE: $INPUT_SOURCE"

# 한글/영문 여부 판단
if [[ "$INPUT_SOURCE" == *"Korean"* ]] || [[ "$INPUT_SOURCE" == *"ABC"* ]]; then
  if [[ "$INPUT_SOURCE" == *"Korean"* ]]; then
    KEYBOARD_LAYOUT="한"
  elif [[ "$INPUT_SOURCE" == *"ABC"* ]]; then
    KEYBOARD_LAYOUT="A"
  fi
else
  KEYBOARD_LAYOUT="?"
fi

echo "KEYBOARD_LAYOUT: $KEYBOARD_LAYOUT"

# sketchybar에 표시
sketchybar --set "$NAME" label="$KEYBOARD_LAYOUT"
