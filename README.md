[![Github actions](https://github.com/wxleong/tpm2-aosp2/actions/workflows/main.yml/badge.svg)](https://github.com/wxleong/tpm2-aosp2/actions)

# Introduction

Android integration guide for OPTIGA™ TPM 2.0.

# Table of Contents

- **[Prerequisites](#prerequisites)**
- **[Preparing the Environment](#preparing-the-environment)**
- **[Building AOSP](#building-aosp)**
- **[Running Android Emulator](#running-android-emulator)**
- **[Running Headless Android Emulator](#running-headless-android-emulator)**

# Prerequisites

The integration guide has been CI tested for compatibility with the following platform and operating system:

- Platform: x86_64
- Operating System: Ubuntu (22.04)

# Preparing the Environment

Download this project for later use:
```exclude
$ git clone https://github.com/wxleong/tpm2-aosp2 ~/tpm2-aosp2
```

# Building AOSP

On Ubuntu 22.04:
```all
$ sudo apt update
$ sudo apt install -y git git-core gnupg flex bison build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig

$ export REPO=$(mktemp /tmp/repo.XXXXX)
$ curl -o ${REPO} https://storage.googleapis.com/git-repo-downloads/repo
$ sudo install -m 755 ${REPO} /usr/bin/repo

$ sudo apt install -y python3
$ sudo ln -s /usr/bin/python3 /usr/bin/python
$ python --version

$ repo version

$ mkdir ~/aosp
$ cd ~/aosp
$ repo init --depth=1 -u https://android.googlesource.com/platform/manifest -b android-14.0.0_r11
$ cp ~/aosp/.repo/repo/repo /usr/bin/repo
$ repo sync -c -f --force-sync --no-clone-bundle --no-tags -j 0
$ du -sm ~/aosp

$ cd ~/aosp
$ source build/envsetup.sh
$ lunch sdk_phone_x86_64
$ m -j
```

# Running Android Emulator

```exclude
$ cd ~/aosp
$ source build/envsetup.sh
$ emulator -verbose -gpu swiftshader -selinux permissive -logcat *:v
```

# Running Headless Android Emulator

Start the emulator in headless mode:
```all
$ cd ~/aosp
$ source build/envsetup.sh
$ export ANDROID_EMULATOR_WAIT_TIME_BEFORE_KILL=1

$ emulator -selinux permissive -no-window -no-audio &
$ EMULATOR_PID=$!
```

Wait for the emulator to be ready:
```all
$ export PATH=${HOME}/aosp/out/host/linux-x86/bin:$PATH

# Usage: ./emulator_check.sh <emulator pid> <desired android version> <max wait time in seconds>
$ chmod +x ~/tpm2-aosp2/scripts/emulator_check.sh
$ ~/tpm2-aosp2/scripts/emulator_check.sh $EMULATOR_PID 14 30
```

Interact with the emulator:
```all
$ adb shell getprop ro.build.version.sdk
$ adb shell getprop ro.system.build.version.release
```

Terminate the emulator:
```all
$ kill -SIGTERM $EMULATOR_PID
```

