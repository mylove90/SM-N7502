#!/bin/bash
#rm -rf output
export ARCH=arm
if ! d [ arm-linux-androideabi-4.9 ]; then
git clone -b android-8.0.0_r51 https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/
fi
export CROSS_COMPILE=$(pwd)/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-

mkdir output

make -C $(pwd) O=output msm8226-sec_defconfig VARIANT_DEFCONFIG=msm8226-sec_hl3gds_eur_defconfig SELINUX_DEFCONFIG=selinux_defconfig
make -j$(nproc) -C $(pwd) O=output
