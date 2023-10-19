[![Github actions](https://github.com/wxleong/tpm2-aosp2/actions/workflows/main.yml/badge.svg)](https://github.com/wxleong/tpm2-aosp2/actions)

# tpm2-aosp2

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
$ lunch aosp_x86_64-eng
$ m -j$(nproc)
```
