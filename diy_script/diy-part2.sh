#!/bin/bash
#
# Copyright (c) 2019-2025 huajiaoshu520
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/huajiaoshu520/X86
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.31.66/g' package/base-files/files/bin/config_generate

# 日期
sed -i 's/os.date(/&"%Y-%m-%d %H:%M:%S"/' ./package/lean/autocore/files/x86/index.htm

# 关闭串口跑码
sed -i 's/console=tty0//g'  ./target/linux/x86/image/Makefile
sed -i 's/%V, %C/[Year] | by Jason /g' ./package/base-files/files/etc/banner
sed -i "s/Year/$(TZ=':Asia/Shanghai' date '+%Y')/g" ./package/base-files/files/etc/banner
sed -i '/logins./a\                                          by Jason' ./package/base-files/files/etc/profile

# Modify default passwd
sed -i '/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./ d' ./package/lean/default-settings/files/zzz-default-settings

# ID
sed -i "s/DISTRIB_REVISION='R.*.*.[0-9]/& Compiled by Jason/" ./package/lean/default-settings/files/zzz-default-settings
rm -rf feeds/packages/net/shadowsocks-libev
./scripts/feeds update -a
./scripts/feeds install -a
# 主题背景
mkdir -p ./feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background/ && curl -o ./feeds/luci/themes/luci-theme-argon/htdocs/luci-static/argon/background/Network.mp4 https://raw.githubusercontent.com/huajiaoshu520/X86/main/other/argon/video/default/Network.mp4


# 临时
sed -i 's/6.12/6.18/g'  ./target/linux/x86/Makefile

#lucky
sed -i 's|/etc/lucky|/etc/config/lucky2|g' ./feeds/luci/applications/luci-app-lucky/root/etc/config/lucky
sed -i 's/PKG_VERSION:=2.17.8/PKG_VERSION:=2.27.2/g' ./feeds/packages/net/lucky/Makefile

#禁用固件更新后跑分
sed -i '/^echo "0 4 \* \* \* \/etc\/coremark.sh" >> \/etc\/crontabs\/root$/d' ./feeds/packages/utils/coremark/coremark
sed -i '/^\[ -n "\$\${IPKG_INSTROOT}" \] \|\| echo "0 4 \* \* \* \/etc\/coremark.sh" >> \/etc\/crontabs\/root$/d' ./feeds/packages/utils/coremark/Makefile

#dockerd
sed -i '/containerd.installer/{s/^/# /}' ./feeds/packages/utils/dockerd/Makefile
sed -i '/runc.installer/{s/^/# /}' ./feeds/packages/utils/dockerd/Makefile

# iStore 中文翻译
echo "===== iStore translation ====="

if [ -f ./feeds/istore/translations/zh-cn/app.po ]; then
    echo "Found iStore zh-cn translation"
    mkdir -p ./feeds/istore/luci-app-store/po/zh-cn
    cp ./feeds/istore/translations/zh-cn/app.po \
       ./feeds/istore/luci-app-store/po/zh-cn/store.po
fi

#同步lede-xray
cp ./feeds/helloworld/xray-core/Makefile ./feeds/packages/net/xray-core/Makefile
