[![Github actions](https://github.com/wxleong/tpm2-aosp2/actions/workflows/main.yml/badge.svg)](https://github.com/wxleong/tpm2-aosp2/actions)

# Introduction

Android integration guide for OPTIGA™ TPM 2.0.

# Table of Contents

- **[Prerequisites](#prerequisites)**
- **[Preparing the Environment](#preparing-the-environment)**
- **[Cross-Compiling OpenSSL 3](#cross-compiling-openssl-3)**
- **[Cross-Compiling TPM2-TSS](#cross-compiling-tpm2-tss)**
- **[Cross-Compiling TPM2-OpenSSL](#cross-compiling-tpm2-openssl)**
- **[Cross-Compiling TPM2 Simulator](#cross-compiling-tpm2-simulator)**
- **[Building AOSP](#building-aosp)**
- **[Running Android Emulator](#running-android-emulator)**
- **[Running Headless Android Emulator](#running-headless-android-emulator)**

# Prerequisites

The integration guide has been CI tested for compatibility with the following platform and operating system:

- Platform: x86_64
- Operating System: Ubuntu (22.04)

# Preparing the Environment

Download package information:
```all
$ sudo apt update
```

Install packages necessary for AOSP building:
```all
$ sudo apt install -y git git-core gnupg flex bison build-essential zip curl zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 libncurses5 lib32ncurses5-dev x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev libxml2-utils xsltproc unzip fontconfig

$ sudo apt install -y python3
$ sudo ln -s /usr/bin/python3 /usr/bin/python
$ python --version

$ export REPO=$(mktemp /tmp/repo.XXXXX)
$ curl -o ${REPO} https://storage.googleapis.com/git-repo-downloads/repo
$ sudo install -m 755 ${REPO} /usr/bin/repo
$ repo version
```

Install packages necessary for tpm2-tss building:
```all
$ sudo apt -y install autoconf-archive libcmocka0 libcmocka-dev procps iproute2 build-essential git pkg-config gcc libtool automake libssl-dev uthash-dev autoconf doxygen libjson-c-dev libini-config-dev libcurl4-openssl-dev uuid-dev pandoc acl libglib2.0-dev xxd jq patchelf
```

Download the Android NDK:
```all
$ sudo apt install -y wget

$ cd ~
$ wget https://dl.google.com/android/repository/android-ndk-r26b-linux.zip
$ unzip android-ndk-r26b-linux.zip
$ du -ms android-ndk-r26b
```

Download this project for later use:
```exclude
$ git clone https://github.com/wxleong/tpm2-aosp2 --depth=1 ~/tpm2-aosp2
```

# Cross-Compiling OpenSSL 3

Set the environment variables:
```all
$ export PATH=${HOME}/android-ndk-r26b/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
$ export ANDROID_NDK_ROOT=${HOME}/android-ndk-r26b
```

Download the project:
```all
$ git clone https://github.com/openssl/openssl -b openssl-3.1.4 --depth=1 ~/openssl
```

Cross-compile the project:
```all
$ cd ~/openssl

# Why "-U__ANDROID_API__ -D__ANDROID_API__=34"? Read https://github.com/openssl/openssl/issues/18561
$ ./Configure android-x86_64 -U__ANDROID_API__ -D__ANDROID_API__=34 --libdir="${HOME}/openssl/build/usr/local/lib" --prefix="${HOME}/openssl/build/usr/local" --openssldir="${HOME}/openssl/build/usr/local/lib/ssl"
$ make -j

$ mkdir build
$ make install_sw -j
$ ls -R build
```

You will need to change the library name due to a conflict with AOSP BoringSSL, which uses the same library name:
```all
$ cd ~/openssl/build/usr/local/lib

# Read the SONAME entry before modifying
$ readelf -a libcrypto.so | grep SONAME

# Modify SONAME
$ patchelf --set-soname libossl3-crypto.so libcrypto.so
$ mv libcrypto.so libossl3-crypto.so

# Read the SONAME entries after making modifications
$ readelf -a libossl3-crypto.so | grep SONAME
```

# Cross-Compiling TPM2-TSS

Set the environment variables:
```all
$ export PATH=${HOME}/android-ndk-r26b/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
$ export CC=x86_64-linux-android34-clang
$ export CRYPTO_LIBS="-L${HOME}/openssl/build/usr/local/lib -lossl3-crypto"
$ export CRYPTO_CFLAGS="-I${HOME}/openssl/build/usr/local/include"
```

Download the project:
```all
$ git clone https://github.com/tpm2-software/tpm2-tss ~/tpm2-tss
$ cd ~/tpm2-tss
$ git checkout d0632dabe8557754705f8d38ffffdafc9f4865d1
```

Cross-compile the project:
```all
$ cd ~/tpm2-tss

$ ./bootstrap
$ ./configure --host=x86_64-linux-android34 --with-crypto=ossl --disable-fapi --disable-policy --disable-tcti-spi-helper --disable-tcti-i2c-helper --with-maxloglevel=none --libdir="${HOME}/tpm2-tss/build/usr/local/lib" --includedir="${HOME}/tpm2-tss/build/usr/local/include"
$ make -j

$ make install -j
$ ls -R build
```

# Cross-Compiling TPM2-OpenSSL

Set the environment variables:
```all
$ export PATH=${HOME}/android-ndk-r26b/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
$ export CC=x86_64-linux-android34-clang
$ export TSS2_LIBS="-L${HOME}/tpm2-tss/build/usr/local/lib"
$ export TSS2_CFLAGS="-I${HOME}/tpm2-tss/build/usr/local/include"
$ export TSS2_ESYS_LIBS="{$TSS2_LIBS} -ltss2-esys"
$ export TSS2_ESYS_CFLAGS=$TSS2_CFLAGS
$ export TSS2_TCTILDR_LIBS="${TSS2_LIBS} -ltss2-tctildr"
$ export TSS2_TCTILDR_CFLAGS=$TSS2_CFLAGS
$ export TSS2_RC_LIBS="${TSS2_LIBS} -ltss2-rc"
$ export TSS2_RC_CFLAGS=$TSS2_CFLAGS
$ export CRYPTO_LIBS="-L${HOME}/openssl/build/usr/local/lib -lossl3-crypto"
$ export CRYPTO_CFLAGS="-I${HOME}/openssl/build/usr/local/include"
```

Download the project:
```all
$ git clone https://github.com/tpm2-software/tpm2-openssl -b 1.2.0 --depth=1 ~/tpm2-openssl
```

Cross-compile the project:
```all
$ cd ~/tpm2-openssl

$ ./bootstrap
$ ./configure --host=x86_64-linux-android34
$ make -j

$ make install DESTDIR=${HOME}/tpm2-openssl/build -j
$ ls -R build
```

Change the library name to ensure clarity:
```all
$ cd ~/tpm2-openssl/build/usr/lib/x86_64-linux-gnu/ossl-modules

# Read the SONAME entry before modifying
$ readelf -a tpm2.so | grep SONAME

# Modify SONAME
$ patchelf --set-soname libtss2-ossl3-provider.so tpm2.so
$ mv tpm2.so libtss2-ossl3-provider.so

# Read the SONAME entries after making modifications
$ readelf -a libtss2-ossl3-provider.so | grep SONAME
```

# Cross-Compiling TPM2 Simulator

Set the environment variables:
```all
$ export PATH=${HOME}/android-ndk-r26b/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
$ export CC=x86_64-linux-android34-clang
$ export CPP="$CC -E"
$ export LIBCRYPTO_LIBS="-L${HOME}/openssl/build/usr/local/lib -lossl3-crypto"
$ export LIBCRYPTO_CFLAGS="-I${HOME}/openssl/build/usr/local/include"
```

Download the project:
>  Support for OpenSSL 3 is not officially provided yet in the [ms-tpm-20-ref](https://github.com/microsoft/ms-tpm-20-ref) project. Official support for OpenSSL 3 can be tracked through the project's [pull request #93](https://github.com/microsoft/ms-tpm-20-ref/pull/93). This is a temporary workaround taken from the pull request.
```all
$ git clone https://github.com/fferino-fungible/ms-tpm-20-ref -b user/fabrice/openssl3 --depth=1 ~/ms-tpm-20-ref
```

Disabling the FILE_BACKED_NV feature is not possible through the use of CFLAGS; therefore, the code must be modified:
```all
$ cd ~/ms-tpm-20-ref/TPMCmd
$ sed -i 's/define FILE_BACKED_NV YES/define FILE_BACKED_NV NO/g' Platform/include/PlatformData.h
```

Cross-compile the project:
```all
$ cd ~/ms-tpm-20-ref/TPMCmd

$ ./bootstrap
$ ./configure --host=x86_64-linux-android34
$ make -j

$ mkdir build
$ make install DESTDIR=/home/wenxinleong/ms-tpm-20-ref/TPMCmd/build -j
$ ls -R build
```

# Building AOSP

```all
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
$ du -sm ~/aosp/out
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
