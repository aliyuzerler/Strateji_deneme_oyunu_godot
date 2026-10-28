#!/bin/bash
# Android SDK bilesen kurulumu (Dustbound APK export icin)
set -x
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
SDK=/home/z/my-project/android-sdk
MGR=$SDK/cmdline-tools/latest/bin/sdkmanager

yes | "$MGR" --sdk_root=$SDK --licenses > /home/z/my-project/tools/android/lic.log 2>&1
"$MGR" --sdk_root=$SDK "platform-tools" "platforms;android-34" "build-tools;34.0.0" > /home/z/my-project/tools/android/sdk_install.log 2>&1
echo "SDK_INSTALL_DONE rc=$?" >> /home/z/my-project/tools/android/sdk_install.log
