#!/bin/bash
#
# Copyright (c) 2019-2025 huajiaoshu520
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/huajiaoshu520/X86
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# LINUX_VERSION
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(LINUX_VERSION)-/g' include/image.mk

# Add a feed source
#sed -i 's/23\.05/25.12/g' feeds.conf.default
#echo "src-git helloworld https://github.com/Jason6111/helloworld;dev" >> "feeds.conf.default"
echo "src-git helloworld https://github.com/fw876/helloworld;dev" >> "feeds.conf.default"
#echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
#echo "src-git passwall_packages https://github.com/xiaorouji/openwrt-passwall-packages.git;main" >> "feeds.conf.default"
#echo "src-git passwall2 https://github.com/xiaorouji/openwrt-passwall2.git;main" >> "feeds.conf.default"
echo 'src-git istore https://github.com/linkease/istore;main' >> feeds.conf.default
echo "src-git daed https://github.com/QiuSimons/luci-app-daed" >> "feeds.conf.default"

# Temp
#rm -rf ./target/linux/generic/hack-6.12/220-arm-gc_sections.patch
# Switch to the specific commit (4bb635d) for mbedtls directory
#rm -rf ./package/libs/mbedtls/patches/100-fix-gcc14-build.patch
#git checkout 4bb635d -- package/libs/mbedtls
curl -L https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/tools/llvm-bpf/Makefile -o tools/llvm-bpf/Makefile
curl -L https://raw.githubusercontent.com/immortalwrt/immortalwrt/refs/heads/master/include/bpf.mk -o include/bpf.mk
# 删除原来的 bpf-headers
rm -rf package/kernel/bpf-headers

# 下载 immortalwrt 的 bpf-headers
git clone --depth=1 --filter=blob:none --sparse https://github.com/immortalwrt/immortalwrt.git /tmp/immortalwrt

cd /tmp/immortalwrt
git sparse-checkout init --cone
git sparse-checkout set package/kernel/bpf-headers

# 复制到 LEDE
cp -a package/kernel/bpf-headers /mnt/workdir/openwrt/package/kernel/

# 清理临时目录
rm -rf /tmp/immortalwrt

sed -ri "s/(PKG_PATCHVER:=)[^\"]*/\16.18/" package/kernel/bpf-headers/Makefile
curl -s https://raw.githubusercontent.com/Q2297045667/OpenWRT_x86_64/refs/heads/master/openwrt/patch/packages-patches/bpf-headers/900-fix-build.patch > package/kernel/bpf-headers/patches/900-fix-build.patch

