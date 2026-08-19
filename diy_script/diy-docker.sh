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
# wget https://codeload.github.com/moby/moby/tar.gz/docker-v29.7.2
# sha256sum docker-v29.7.2
sed -i -e 's/29.1.1/29.7.2/g' \
       -e 's/65221f1c70feb1bd1562bb1017b586e4528be877656dc16f5be5659fc9b7e522/3a93a88bff41ffa6f4dca9f4ed9fc05e7fdb08e0f9014cf1d8177f85ecbc0683/g' \
       -e 's/9a84135/6a43e3d/g' ./feeds/packages/utils/dockerd/Makefile

# docker
# wget https://codeload.github.com/docker/cli/tar.gz/v29.7.2
sed -i -e 's/29.1.1/29.7.2/g' \
       -e 's/a02081b7d6fb10bfbc8afb621e7edc5124048b31eea7a1ab73c7ccd924b03a66/225b7ab2a15f5230b482df8461069cd4bce38891266fb9898d4188d0a3cbf54a/g' \
       -e 's/0aedba5/a7dcaa6/g' ./feeds/packages/utils/docker/Makefile

# 禁用
sed -i '/containerd.installer/{s/^/# /}' ./feeds/packages/utils/dockerd/Makefile
sed -i '/runc.installer/{s/^/# /}' ./feeds/packages/utils/dockerd/Makefile
# 补丁      
mkdir -p ./feeds/packages/utils/dockerd/patches
wget -O ./feeds/packages/utils/dockerd/patches/001-skip-copy-nested-binaries.patch \
  https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/dockerd/patches/001-skip-copy-nested-binaries.patch

# fw4 docker
mkdir -p package/base-files/files/etc/docker

cat > package/base-files/files/etc/docker/daemon.json <<'EOF'
{
    "data-root": "/mnt/nvme0n1p1/docker",
    "log-level": "warn",
    "iptables": false,
    "firewall-backend": "nftables",
    "hosts": [
        "unix:///var/run/docker.sock"
    ]
}
EOF

mkdir -p package/base-files/files/etc/config

cat > package/base-files/files/etc/config/dockerd <<'EOF'
config globals 'globals'
        option iptables '0'
        option alt_config_file '/etc/docker/daemon.json'
EOF
