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
git clone https://github.com/huajiaoshu520/bpf-headers ./package/kernel/bpf-headers
