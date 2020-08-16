#!bin/bash
#
# Baka-CI Kernel Build Script || For Continous Integration
#
# Copyright 2019, Ahmad Thoriq Najahi "Najahiii" <najahiii@outlook.co.id>
# Copyright 2019, alanndz <alanmahmud0@gmail.com>
# Copyright 2020, Dicky Herlambang "Nicklas373" <herlambangdicky5@gmail.com>
# Copyright 2016-2020, Baka-CI Build Project
# SPDX-License-Identifier: GPL-3.0-or-later

# Declare Kernel Details
KERNEL_NAME=Kizuna
KERNEL_COMPILER=0
KERNEL_BOT="Drone-CI"

# Define Kernel Specific Tag
KERNEL_CAF_TAG="LA.UM.10.6.2.r1-00500-89xx.0"
# Environment init
function env_init() {
# Set ARCH
export ARCH=arm64
export SUBARCH=arm64
export TZ=CST-8
}

# Mido init
function mido_init() {
# Create Temporary Folder
mkdir TEMP

# Clone kernel repositories earlier
git clone --depth=1 -b lineage-17.1 https://github.com/Nicklas373/kernel_xiaomi_msm8953-4.9.git kernel

# Cloning AnyKernel Repository
git clone --depth=1 https://github.com/unknownbaka/AnyKernel3

# Define Kernel Specific Environment
KERNEL_SCHED="EAS"
KERNEL_BRANCH="lineage-17.1"
KERNEL_REL="CAF"

# Define CI Specific Environment
export KBUILD_BUILD_USER=unknownbaka
export KBUILD_BUILD_HOST=${KERNEL_BOT}

# Define Global Environment for Mido
IMAGE="$(pwd)/kernel/out/arch/arm64/boot/Image.gz-dtb"
KERNEL="$(pwd)/kernel"
KERNEL_TEMP="$(pwd)/TEMP"
CODENAME="mido"
KERNEL_CODE="Mido"
TELEGRAM_DEVICE="Redmi Note 4x"
}

# Additional init environment
function add_init() {
# Declare global additional environment
KERNEL_DATE="$(date +%Y%m%d-%H%M)"
ZIP_NAME="${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip"
KERNEL_ANDROID_VER="11"

# Declare Telegram File Environment
TELEGRAM_BOT_ID=${TELEGRAM_BOT}
TELEGRAM_GROUP_ID=${TELEGRAM_GROUP}
TELEGRAM_FILENAME="${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip"
}

# Cloning Clang
function clang_init() {
if [ "$KERNEL_COMPILER" == "0" ];
	then
		# Clang environment
        git clone --depth=1 https://github.com/kdrag0n/proton-clang.git proton-clang
        export CLANG_PATH=$(pwd)/proton-clang/bin
        export PATH=${CLANG_PATH}:${PATH}
        export LD_LIBRARY_PATH="$(pwd)/proton-clang/bin/../lib:$PATH"
elif [ "$KERNEL_COMPILER" == "1" ];
	then
		# Clang environment
		export CLANG_PATH=/root/aosp-clang/bin
		export PATH=${CLANG_PATH}:${PATH}
		export LD_LIBRARY_PATH="/root/aosp-clang/bin/../lib:$PATH"
		export CROSS_COMPILE=/root/gcc-4.9_64/arm64/bin/aarch64-linux-android-
		export CROSS_COMPILE_ARM32=/root/gcc-4.9/arm/bin/arm-linux-androideabi-
fi
}

# Declare Telegram Bot Aliases
function telegram_init() {
TELEGRAM_KERNEL_VER=$(cat ${KERNEL}/out/.config | grep Linux/arm64 | cut -d " " -f3)
TELEGRAM_UTS_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep UTS_VERSION | cut -d '"' -f2)
TELEGRAM_COMPILER_NAME=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILE_BY | cut -d '"' -f2)
TELEGRAM_COMPILER_HOST=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILE_HOST | cut -d '"' -f2)
TELEGRAM_TOOLCHAIN_VER=$(cat ${KERNEL}/out/include/generated/compile.h | grep LINUX_COMPILER | cut -d '"' -f2)
}

# Telegram Bot Service || Compiling Notification
function bot_template() {
curl -s -X POST https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendMessage -d chat_id=${TELEGRAM_GROUP_ID} -d "parse_mode=HTML" -d text="$(
	for POST in "${@}";
		do
			echo "${POST}"
		done
	)"
}

# Telegram Bot Service || Compiling Message
function bot_first_compile() {
	bot_template	"<b>|| Baka-CI Build Bot ||</b>" \
			"" \
			"<b>Kizuna Kernel build Start!</b>" \
			"" \
			"============= Build Information ================" \
			"<b>Device :</b><code> ${TELEGRAM_DEVICE} </code>" \
			"<b>Android Version :</b><code> ${KERNEL_ANDROID_VER} </code>" \
			"" \
			" =========== Kernel Information ================" \
			"<b>Kernel Scheduler : </b><code> ${KERNEL_SCHED} </code>" \
			"<b>Kernel Tag : </b><code> ${KERNEL_CAF_TAG} </code>" \
			"<b>Kernel Branch : </b><code> ${KERNEL_BRANCH} </code>" \
			"<b>Kernel Commit : </b><code> $(git --no-pager log --pretty=format:'"%h - %s (%an)"' -1) </code>"
}

# Telegram bot message || success notification
function bot_build_success() {
	bot_template	"<b>|| Baka-CI Build Bot ||</b>" \
			"" \
			"<b>Kizuna Kernel build Success!</b>" \
			"" \
			"<b>Compile Time :</b><code> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)</code>"
}

# Telegram bot message || failed notification
function bot_build_failed() {
	bot_template	"<b>|| Baka-CI Build Bot ||</b>" \
			"" \
			"<b>Kizuna Kernel build Failed!</b>" \
			"" \
			"<b>Compile Time :</b><code> $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) second(s)</code>"
}

function anykernel() {
cd AnyKernel3
sed -i "s/kernel.string=Kernel/kernel.string=${KERNEL_NAME} Kernel/g" anykernel.sh
#sed -i "s/do.refresh_rate=/do.refresh_rate=67/g" anykernel.sh
sed -i "s/do.cpu_offset=/do.cpu_offset=-60/g" anykernel.sh
make -j$(nproc --all)
mv Kernel-mido.zip  ${KERNEL_TEMP}/${KERNEL_NAME}-${CODENAME}-${KERNEL_DATE}.zip
}

# Compile Mido Begin
function compile_mido() {
	cd ${KERNEL}
	bot_first_compile
	cd ..
	sed -i "s/-perf/-キズナ-${KERNEL_CAF_TAG}/g" ${KERNEL}/localversion
	sed -i "s/CONFIG_WIREGUARD=y/# CONFIG_WIREGUARD is not set/g" ${KERNEL}/arch/arm64/configs/mido_defconfig
	patch -p1 < build/localversion.patch
	patch -p1 < build/polly.patch
	patch -p1 < build/mido.patch
	patch -p1 < build/tpd.patch
	patch -p1 < build/touch.patch
	START=$(date +"%s")
	make -s -C ${KERNEL} ${CODENAME}_defconfig O=out
	make -C ${KERNEL} -j$(nproc --all) -> ${KERNEL_TEMP}/compile.log O=out \
					CC=clang \
					AR=llvm-ar \
					NM=llvm-nm \
					STRIP=llvm-strip \
					OBJCOPY=llvm-objcopy \
					OBJDUMP=llvm-objdump \
					OBJSIZE=llvm-size \
					READELF=llvm-readelf \
					HOSTCC=clang \
					HOSTCXX=clang++ \
					HOSTAR=llvm-ar \
					CLANG_TRIPLE=aarch64-linux-gnu- \
					CROSS_COMPILE=aarch64-linux-gnu- \
					CROSS_COMPILE_ARM32=arm-linux-gnueabi-
	if ! [ -a $IMAGE ];
		then
			echo "kernel not found"
			END=$(date +"%s")
			DIFF=$(($END - $START))
			cd ${KERNEL}
			bot_build_failed
			cd ..
			curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/compile.log"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
			exit 1
	fi
	END=$(date +"%s")
	DIFF=$(($END - $START))
	cd ${KERNEL}
	bot_build_success
	cd ..
	cp ${IMAGE} AnyKernel3
	anykernel
	kernel_upload
}

# Upload Kernel
function kernel_upload() {
	echo "Upload kernel file..."
	curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/$ZIP_NAME" https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument

	echo "Upload log file..."
	curl -F chat_id=${TELEGRAM_GROUP_ID} -F document="@${KERNEL_TEMP}/compile.log"  https://api.telegram.org/bot${TELEGRAM_BOT_ID}/sendDocument
}

function run() {
	env_init
	mido_init
	clang_init
	add_init
	compile_mido
}

# Running
run