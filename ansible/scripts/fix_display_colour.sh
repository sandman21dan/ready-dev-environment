#!/bin/bash
# @description: Modifies macOS display configuration to fix color issues, by setting BitDepth to 8.

/usr/libexec/PlistBuddy -c "add DisplaySets:Configs:DisplayConfig:DisplayConfig:DisplayConfig:LinkDescription:BitDepth integer" ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
/usr/libexec/PlistBuddy -c "set DisplaySets:Configs:DisplayConfig:DisplayConfig:DisplayConfig:LinkDescription:BitDepth 8" ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
/usr/libexec/PlistBuddy -c "add DisplaySets:Configs:DisplayConfig:DisplayConfig:DisplayConfig:LinkDescription:EOTF integer" ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
/usr/libexec/PlistBuddy -c "add DisplaySets:Configs:DisplayConfig:DisplayConfig:DisplayConfig:LinkDescription:PixelEncoding integer" ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
/usr/libexec/PlistBuddy -c "add DisplaySets:Configs:DisplayConfig:DisplayConfig:DisplayConfig:LinkDescription:Range integer" ~/Library/Preferences/ByHost/com.apple.windowserver.displays.*.plist
