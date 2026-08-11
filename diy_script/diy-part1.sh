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
echo "src-git daed https://github.com/kenzok8/openwrt-daede" >> "feeds.conf.default"

#daed
curl -L https://raw.githubusercontent.com/immortalwrt/immortalwrt/master/tools/llvm-bpf/Makefile -o tools/llvm-bpf/Makefile
curl -L https://raw.githubusercontent.com/immortalwrt/immortalwrt/refs/heads/master/include/bpf.mk -o include/bpf.mk
# 升级内核
sed -i 's/38/44/g' ./include/kernel-6.18
sed -i 's/ac26e508abd56e9f8b89872b6e10c49fc823bcc70d8068a5d8504c1a7c4ff045/0f72d938f06828e82c90405174fe572287db7bfe089e2fc46572a99a7f240d43/g' ./include/kernel-6.18
#修改daed编译内核
cp ./include/kernel-6.18 ./target/linux/x86/generic
cp ./include/kernel-6.18 ./target/linux/generic
rm -rf package/kernel/bpf-headers
git clone https://github.com/huajiaoshu520/bpf-headers ./package/kernel/bpf-headers
