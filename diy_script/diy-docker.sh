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
sed -i -e 's/29.6.1/29.8.0/g' \
       -e 's/a97bd870c4b072b7d9cc053b2a806ca3d920f192f9dc6a662e17c1b69f56f2e1/e75ffb5d2ddc1fd98138fdb5e29f707b59f415ec8697e73b8bbdf8bbbb4be8eb/g' \
       -e 's/8ec5ab3/3ce5872/g' ./feeds/packages/utils/dockerd/Makefile

# containerd      
# wget https://codeload.github.com/containerd/containerd/tar.gz/v2.3.4
sed -i -e 's/2.2.5/2.3.4/g' \
       -e 's/ca9c2084ab92b3ce073fa4e43f29a0cad33c2ea71d4e09777acfc082b90049db/175bbf57d637c987fa742f846b43b1b8ba2c61af6a9eaec619c625e4a8a19b69/g' ./feeds/packages/utils/containerd/Makefile
sed -i 's/containerd-shim,containerd-shim-runc-v1,//g' ./feeds/packages/utils/containerd/Makefile

# runc
# https://codeload.github.com/opencontainers/runc/tar.gz/v1.3.4
sed -i -e 's/1.3.6/1.5.1/g' \
       -e 's/8816e8d4181d13012d16733e837425f5f67df57dfac28bc58a68f7dfcd54291b/32286f18899a644ec7c1589688a9600ba54cc65264f23f1f5877ba214ca76e75/g' ./feeds/packages/utils/runc/Makefile

#适配docker29.8.0
#wget -O ./feeds/packages/utils/docker/Makefile \
#  https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/docker/test
sed -i '/^[[:space:]]*cli\/compose\/schema\/data[[:space:]]*\\$/a\
\tvendor/github.com/santhosh-tekuri/jsonschema/v6/metaschemas \\' ./feeds/packages/utils/docker/Makefile

# docker
# wget https://codeload.github.com/docker/cli/tar.gz/v29.7.2
sed -i -e 's/29.6.1/29.8.0/g' \
       -e 's/74d14dd212b07cd3328989dc6a029dde2ebbe6a878199eaaafad54916f456194/c5fadbc00c02dbecb1b7c9936e188baf9c80421a9107e7e9ad36a0923a0fc764/g' \
       -e 's/8900f1d/88096ef/g' ./feeds/packages/utils/docker/Makefile

# 禁用
#sed -i -e '\|$(call EnsureVendoredVersion,containerd)|{s/^/# /}' \
#       -e '\|$(call EnsureVendoredVersion,runc)|{s/^/# /}' \
#       ./feeds/packages/utils/dockerd/Makefile

# 测试
#wget -O ./feeds/packages/utils/containerd/Makefile \
#  https://raw.githubusercontent.com/sbwml/packages_utils_containerd/refs/heads/main/Makefile
#wget -O ./feeds/packages/utils/runc/Makefile \
#  https://raw.githubusercontent.com/sbwml/packages_utils_runc/refs/heads/main/Makefile
  
# 补丁      
#mkdir -p ./feeds/packages/utils/dockerd/patches
#wget -O ./feeds/packages/utils/dockerd/patches/001-skip-copy-nested-binaries.patch \
#  https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/dockerd/patches/001-skip-copy-nested-binaries.patch

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
        option log_level 'warn'
        option iptables '0'
        option alt_config_file '/etc/docker/daemon.json'
        option data_root '/mnt/nvme0n1p1/docker'
        list hosts 'unix:///var/run/docker.sock'
        option _luci_lan 'lan'

config firewall 'firewall'
        option device 'docker0'
        list blocked_interfaces 'wan'
EOF
