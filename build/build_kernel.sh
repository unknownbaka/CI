#!bin/bash
# Copyright 2019, Ahmad Thoriq Najahi "Najahiii" <najahiii@outlook.co.id>
# Copyright 2019, alanndz <alanmahmud0@gmail.com>
# Copyright 2020, Dicky Herlambang "Nicklas373" <herlambangdicky5@gmail.com>
# Copyright 2016-2020, HANA-CI Build Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Kernel host environment
export KBUILD_BUILD_USER=unknownbaka
export KBUILD_BUILD_HOST=Drone-CI
export ARCH=arm64
export TZ=CST-8

# Kernel directory environment
BUILD_GCC=2
BUILD_CLANG=0
BUILD_KERNEL=1
#DL_LIBRA=1
CODENAME="libra"
IMAGE="$(pwd)/kernel/out/arch/arm64/boot/Image.gz-dtb"
KERNEL="$(pwd)/kernel"
KERNEL_TEMP="$(pwd)/TEMP"
KERNEL_DEVICE="Xiaomi 4c"
KERNEL_BOT=Baka-CI
KERNEL_DATE="$(date +%Y%m%d-%H%M)"
KERNEL_ANDROID_VER="Q"

# Telegram Bot
TELEGRAM_BOT_ID=${TELEGRAM_BOT}
TELEGRAM_GROUP_ID=${TELEGRAM_GROUP}
TELEGRAM_FILENAME="${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip"

# Telegram Bot Service || Compiling Notification
function bot_template() {
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendMessage -d chat_id=${TELEGRAM_GROUP_ID} -d "parse_mode=HTML" -d text="$(
            for POST in "${@}"; do
                echo "${POST}"
            done
          )"
}

# Create Temporary Folder
mkdir TEMP

# Download libra’s boot
if [ "$DL_LIBRA" = "1" ]; then
    wget --output-document=android.zip https://github.com/WJXXBSH/android_device_xiaomi_libra/releases/download/v2020.08.12/lineage-17.1-20200812-UNOFFICIAL-libra.zip
    unzip android.zip
    chmod +x boot.img
    mv boot.img libra_boot.img
    curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@$(pwd)/libra_boot.img"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
fi

if [ "$BUILD_KERNEL" != "0" ]; then
# Build environment
apt-get update -qq && apt-get upgrade -y && apt-get install --no-install-recommends -y bc binutils binutils-aarch64-linux-gnu binutils-arm-linux-gnueabi bison flex g++ gcc libssl-dev make patch subversion zstd

# Kernel environment
if [ "$BUILD_KERNEL" = "1" ]; then
    KERNEL_NAME="Lineage17.1"
    KERNEL_BRANCH="master"
    KERNEL_SCHED="EAS"
    git clone --depth=1 -b ${KERNEL_BRANCH} https://github.com/WJXXBSH/android_kernel_xiaomi_libra.git ${KERNEL}
    #sed -i "s/# CONFIG_MSM_CORE_CTL is not set/CONFIG_MSM_CORE_CTL=y/g" kernel/arch/arm64/configs/libra_defconfig
    #sed -i "s/# CONFIG_MSM_CORE_CTL_HELPER is not set/CONFIG_MSM_CORE_CTL_HELPER=y/g" kernel/arch/arm64/configs/libra_defconfig
    sed -i "s/<75>/<76>/g" kernel/arch/arm/boot/dts/qcom/dsi-panel-sharp-rsp61322-1080p-video.dtsi
    #patch -p1 < build/clang.patch
fi

# Clang environment
if [ "$BUILD_CLANG" = "1" ]; then
    git clone --depth=1 https://github.com/kdrag0n/proton-clang.git proton-clang
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export CLANG_PATH=$(pwd)/proton-clang/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${CLANG_PATH}:${GCC_32_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/proton-clang/bin/../lib:$PATH"
    rm $CLANG_PATH/ld $CLANG_PATH/as
elif [ "$BUILD_CLANG" = "2" ]; then
    svn checkout https://github.com/AOSiP/platform_prebuilts_clang_host_linux-x86/trunk/clang-r399163 google-clang
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export CLANG_PATH=$(pwd)/google-clang/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${CLANG_PATH}:${GCC_32_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/google-clang/bin/../lib:$PATH"
elif [ "$BUILD_CLANG" = "3" ]; then
    wget --output-document=candy_clang.tar.zst $CANDY_CLANG
    tar -axf candy_clang.tar.zst
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export CLANG_PATH=$(pwd)/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${CLANG_PATH}:${GCC_32_PATH}:${PATH}
    export LD_LIBRARY_PATH="$(pwd)/bin/../lib:$PATH"
fi

# GCC environment
if [ "$BUILD_GCC" = "1" ]; then
    apt-get install --no-install-recommends -y gcc-arm-linux-gnueabi gcc-aarch64-linux-gnu
elif [ "$BUILD_GCC" = "2" ]; then
    git clone --depth=1 https://github.com/arter97/arm64-gcc.git toolchain
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export GCC_PATH=$(pwd)/toolchain/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${GCC_PATH}:${GCC_32_PATH}:${PATH}
    export CROSS_COMPILE=aarch64-elf-
elif [ "$BUILD_GCC" = "3" ]; then
    git clone --depth=1 https://github.com/milouk/gcc-prebuilt-elf-toolchains.git toolchain
    git clone --depth=1 https://github.com/arter97/arm32-gcc.git toolchain32
    export GCC_PATH=$(pwd)/toolchain/aarch64-linux-elf/bin
    export GCC_32_PATH=$(pwd)/toolchain32/bin
    export PATH=${GCC_PATH}:${GCC_32_PATH}:${PATH}
    export CROSS_COMPILE=aarch64-linux-elf-
fi

# AnyKernel 3
git clone --depth=1 https://github.com/unknownbaka/AnyKernel3

# Import telegram bot environment
function bot_env() {
if [ -a ${KERNEL}/localversion ]; then
TELEGRAM_KERNEL_LOCALVER=$(cat ${KERNEL}/localversion | cut -c2-)
else
TELEGRAM_KERNEL_LOCALVER=$(cat ${KERNEL}/out/.config | grep "CONFIG_LOCALVERSION=" | cut -d '"' -f 2 | cut -c2-)
fi
TELEGRAM_KERNEL_VER=$(cat ${KERNEL}/out/.config | grep Linux/arm64 | cut -d " " -f3)
TELEGRAM_CST_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep UTS_VERSION | cut -d '"' -f2)
TELEGRAM_COMPILER_NAME=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILE_BY | cut -d '"' -f2)
TELEGRAM_COMPILER_HOST=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILE_HOST | cut -d '"' -f2)
TELEGRAM_TOOLCHAIN_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
}

# Telegram bot message || first notification
function bot_first_compile() {
bot_template   "<b>||------------${KERNEL_BOT} Build Bot------------||</b>" \
                "" \
                "<b>${KERNEL_NAME} Kernel build Start!</b>" \
                "" \
                "<b>Device :</b><code> ${KERNEL_DEVICE} </code>" \
                "<b>Android Version :</b><code> ${KERNEL_ANDROID_VER} </code>" \
                "<b>Kernel Branch :</b><code> ${KERNEL_BRANCH} </code>" \
                "<b>Latest commit :</b><code> $(git -C ${KERNEL} --no-pager log --pretty=format:'"%h - %s (%an)"' -1) </code>"
}

function bot_first_compile_() {
bot_template   "<b>||------------${KERNEL_BOT} Build Bot------------||</b>" \
                "" \
                "<b>${KERNEL_NAME} Kernel build Start!</b>" \
                "" \
                "<b>Device :</b><code> ${KERNEL_DEVICE} </code>" \
                "<b>Android Version :</b><code> ${KERNEL_ANDROID_VER} </code>" \
                "<b>Kernel Branch :</b><code> ${KERNEL_BRANCH} </code>"
}

# Telegram bot message || bot notification
function bot_complete_compile() {
bot_env
bot_template   "<b>||------------${KERNEL_BOT} Build Bot------------||</b>" \
                "" \
                "<b>Kernel Scheduler :</b><code> ${KERNEL_SCHED} </code>" \
                "<b>Kernel Version :</b><code> Linux ${TELEGRAM_KERNEL_VER} </code>" \
                "<b>Kernel Local Version :</b><code> ${TELEGRAM_KERNEL_LOCALVER} </code>" \
                "<b>Kernel Host :</b><code> ${TELEGRAM_COMPILER_NAME}@${TELEGRAM_COMPILER_HOST} </code>" \
                "<b>Kernel Toolchain :</b><code> ${TELEGRAM_TOOLCHAIN_VER} </code>" \
                "<b>CST Version :</b><code> ${TELEGRAM_CST_VER} </code>"
}

# Telegram bot message || success notification
function bot_build_success() {
bot_template   "<b>${KERNEL_NAME} Kernel build Success!</b>" \
                "" \
                "<b>Compile Time :</b><code> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) </code>"
}

# Telegram bot message || failed notification
function bot_build_failed() {
bot_template   "<b>${KERNEL_NAME} Kernel build Failed!</b>" \
                "" \
                "<b>Compile Time :</b><code> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s) </code>"
}

# Compile Mido Begin
function run() {
START=$(date +"%s")
bot_first_compile
if [ "$?" != "0" ]; then
	bot_first_compile_
fi
mkdir ${KERNEL}/out
make -s -C ${KERNEL} ${CODENAME}_defconfig O=out
if [ "$BUILD_CLANG" != "0" ]; then
make -C ${KERNEL} -j$(nproc --all) O=out \
                CC=clang \
                CROSS_COMPILE=aarch64-linux-gnu- \
                CROSS_COMPILE_ARM32=arm-eabi- \
                2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                2> tee ${KERNEL_TEMP}/compile_fail.log
else
if [ "$BUILD_GCC" = "1" ]; then
make -C ${KERNEL} -j$(nproc --all) O=out \
                2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                2> tee ${KERNEL_TEMP}/compile_fail.log
else
make -C ${KERNEL} -j$(nproc --all) O=out \
                CROSS_COMPILE_ARM32=arm-eabi- \
                2>&1| tee ${KERNEL_TEMP}/compile_success.log \
                2> tee ${KERNEL_TEMP}/compile_fail.log
fi
fi
if ! [ -a $IMAGE ]; then
	END=$(date +"%s")
	DIFF=$(($END - $START))
	bot_build_failed
	curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/compile_fail.log"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
	exit 1
fi
END=$(date +"%s")
DIFF=$(($END - $START))
bot_complete_compile
bot_build_success
cp ${IMAGE} AnyKernel3
anykernel
kernel_upload
}

# AnyKernel
function anykernel() {
cd AnyKernel3
sed -i "s/kernel.string=Kernel/kernel.string=${KERNEL_NAME} Kernel/g" anykernel.sh
sed -i "s/mido/$CODENAME/g" anykernel.sh
make -j$(nproc --all)
mv Kernel-mido.zip  ${KERNEL_TEMP}/${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip
}

# Upload Kernel
function kernel_upload() {
curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/compile_success.log"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
}

# Running
run
fi