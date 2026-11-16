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

# LEDE 仍使用 gettext-full 0.22.5 时，应用上游的 0.24.2 更新
if grep -Fxq 'PKG_VERSION:=0.22.5' package/libs/gettext-full/Makefile; then
    echo "正在应用 gettext-full 0.24.2 更新"

    (
        set -euo pipefail
        gettext_update=5ba7ce24dc18e08e7a62ce823df1611f7bf04b18
        git diff "${gettext_update}^" "$gettext_update" -- package/libs/gettext-full |
            git apply
    ) || {
        echo "错误：gettext-full 补丁应用失败，请检查当前 LEDE 源码" >&2
        exit 1
    }
fi

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# LINUX_VERSION
sed -i 's/IMG_PREFIX:=/IMG_PREFIX:=$(LINUX_VERSION)-/g' include/image.mk

# Add a feed source
#sed -i 's/23\.05/25.12/g' feeds.conf.default
#echo "src-git helloworld https://github.com/Jason6111/helloworld;dev" >> "feeds.conf.default"
#echo "src-git helloworld https://github.com/fw876/helloworld;dev" >> "feeds.conf.default"
echo "src-git daed https://github.com/kenzok8/openwrt-daede" >> "feeds.conf.default"
echo "src-git quickstart https://github.com/huajiaoshu520/quickstart" >> "feeds.conf.default"

#daed
#curl -L https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/daed/patches/llvm-bpf/Makefile -o tools/llvm-bpf/Makefile
#curl -L https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/daed/patches/bpf.mk -o include/bpf.mk

#修改daed编译内核
cp ./include/kernel-6.18 ./target/linux/x86/generic
cp ./include/kernel-6.18 ./target/linux/generic
rm -rf package/kernel/bpf-headers
git clone https://github.com/huajiaoshu520/bpf-headers ./package/kernel/bpf-headers

# 取消iptables
sed -i -E 's/[[:space:]]iptables-mod-tproxy([[:space:]]|$)/\1/g; s/[[:space:]]iptables-mod-extra([[:space:]]|$)/\1/g; s/[[:space:]]iptables([[:space:]]|$)/\1/g' ./include/target.mk
