#!/bin/bash
#
# Copyright (c) 2019-2025 huajiaoshu520
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/huajiaoshu520/X86
# File name: diy-docker.sh
# Description: OpenWrt DIY script docker (After Update feeds)
#

# dockerman
#sed -i 's/+cgroupfs-mount //g' feeds/luci/applications/luci-app-dockerman/Makefile
#sed -i '42i sed -i "/^# the system init finished. By default this file does nothing./a \/etc\/init.d\/cgroupfs-mount disable" \/etc\/rc.local' package/lean/default-settings/files/zzz-default-settings
#rm -rf ./feeds/luci/applications/luci-app-dockerman
#git clone https://github.com/Jason6111/luci-app-dockerman ./feeds/luci/applications/luci-app-dockerman
#rm -rf ./feeds/packages/utils/dockerd
#git clone https://github.com/Jason6111/dockerd ./feeds/packages/utils/dockerd && chmod -R 777 ./feeds/packages/utils/dockerd

# dockerd
# wget https://codeload.github.com/moby/moby/tar.gz/docker-v29.6.2
# sha256sum docker-v29.6.2
sed -i -e 's/29.1.1/29.6.2/g' \
       -e 's/65221f1c70feb1bd1562bb1017b586e4528be877656dc16f5be5659fc9b7e522/8b64afb7562347d2ce9f1027e326ce9a45c8f41a486106ce2034f7eb1abe0e0f/g' \
       -e 's/9a84135/3d80467/g' ./feeds/packages/utils/dockerd/Makefile

# docker
# wget https://codeload.github.com/docker/cli/tar.gz/v29.6.2
sed -i -e 's/29.1.1/29.6.2/g' \
       -e 's/a02081b7d6fb10bfbc8afb621e7edc5124048b31eea7a1ab73c7ccd924b03a66/11aef3484c38d39d291a54a73a4d9dd2bb3c000d9a3fc3862bd03fe899594f2c/g' \
       -e 's/0aedba5/dfc4efb/g' ./feeds/packages/utils/docker/Makefile
       
# containerd      
# wget https://codeload.github.com/containerd/containerd/tar.gz/v2.2.0
sed -i -e 's/2.2.0/2.2.0/g' \
       -e 's/86e7a268fc73f5332522baef86082c1d6c17986e2957a9ad842ead35d1080fca/86e7a268fc73f5332522baef86082c1d6c17986e2957a9ad842ead35d1080fca/g' ./feeds/packages/utils/containerd/Makefile
#sed -i 's/containerd-shim,containerd-shim-runc-v1,//g' ./feeds/packages/utils/containerd/Makefile

# runc
# https://codeload.github.com/opencontainers/runc/tar.gz/v1.3.4
sed -i -e 's/1.3.3/1.3.4/g' \
       -e 's/3da010af5c2c1c3d12d460255e4a7dc049c223ebc629c80fbbe4c10720997ffe/a9f9646c4c8990239f6462b408b22d9aa40ba0473a9fc642b9d6576126495eee/g' ./feeds/packages/utils/runc/Makefile
