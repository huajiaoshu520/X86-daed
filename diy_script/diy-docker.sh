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

# docker
# wget https://codeload.github.com/docker/cli/tar.gz/v29.7.2
sed -i -e 's/29.6.1/29.8.0/g' \
       -e 's/74d14dd212b07cd3328989dc6a029dde2ebbe6a878199eaaafad54916f456194/c5fadbc00c02dbecb1b7c9936e188baf9c80421a9107e7e9ad36a0923a0fc764/g' \
       -e 's/8900f1d/88096ef/g' ./feeds/packages/utils/docker/Makefile

# 禁用
sed -i -e '\|$(call EnsureVendoredVersion,containerd)|{s/^/# /}' \
       -e '\|$(call EnsureVendoredVersion,runc)|{s/^/# /}' \
       ./feeds/packages/utils/dockerd/Makefile
# 补丁      
mkdir -p ./feeds/packages/utils/dockerd/patches
wget -O ./feeds/packages/utils/dockerd/patches/001-skip-copy-nested-binaries.patch \
  https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/dockerd/patches/001-skip-copy-nested-binaries.patch

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

DOCKER_MAKEFILE="./feeds/packages/utils/docker/Makefile"

if [ -f "$DOCKER_MAKEFILE" ]; then

    echo "Installing Docker CLI 29.8.0 jsonschema fix..."

    sed -i \
        '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V6/,/^endef$/d' \
        "$DOCKER_MAKEFILE" 2>/dev/null || true

    cat >> "$DOCKER_MAKEFILE" <<'EOF'

define Build/PrepareDockerJsonschema
	@echo "===> Docker CLI 29.8.0 jsonschema/v6 fix"; \
	WORKDIR="$(PKG_BUILD_DIR)/.go_work/build/src/github.com/docker/cli"; \
	JSONSCHEMA_DIR="$$WORKDIR/vendor/github.com/santhosh-tekuri/jsonschema/v6"; \
	echo "===> Checking: $$JSONSCHEMA_DIR/metaschemas"; \
	\
	if [ -d "$$JSONSCHEMA_DIR/metaschemas" ] && \
	   [ -n "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "===> metaschemas already exists."; \
	else \
		echo "===> metaschemas is missing."; \
		echo "===> Running go mod download..."; \
		cd "$(PKG_BUILD_DIR)" && go mod download; \
		\
		GOMODCACHE_DIR="$$(go env GOMODCACHE)"; \
		echo "===> GOMODCACHE: $$GOMODCACHE_DIR"; \
		\
		SRC="$$(find "$$GOMODCACHE_DIR" \
			-type d \
			-path '*/github.com/santhosh-tekuri/jsonschema/v6@*' \
			-print \
			-quit 2>/dev/null)"; \
		\
		if [ -z "$$SRC" ]; then \
			SRC="$$(find "$$GOMODCACHE_DIR" \
				-type d \
				-path '*santhosh-tekuri/jsonschema/v6*' \
				-print \
				-quit 2>/dev/null)"; \
		fi; \
		\
		if [ -z "$$SRC" ]; then \
			echo "ERROR: jsonschema/v6 module not found."; \
			find "$$GOMODCACHE_DIR" \
				-type d \
				-path '*jsonschema*' \
				-print 2>/dev/null | head -100 || true; \
			exit 1; \
		fi; \
		\
		echo "===> Found jsonschema module:"; \
		echo "$$SRC"; \
		\
		if [ ! -d "$$SRC/metaschemas" ]; then \
			echo "ERROR: metaschemas directory not found in:"; \
			echo "$$SRC"; \
			exit 1; \
		fi; \
		\
		echo "===> Copying metaschemas to actual Docker CLI vendor tree..."; \
		mkdir -p "$$JSONSCHEMA_DIR"; \
		rm -rf "$$JSONSCHEMA_DIR/metaschemas"; \
		cp -a "$$SRC/metaschemas" "$$JSONSCHEMA_DIR/"; \
		\
		echo "===> metaschemas restored."; \
	fi; \
	\
	echo "===> Final metaschemas check:"; \
	find "$$JSONSCHEMA_DIR/metaschemas" -type f -print; \
	\
	if [ -z "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "ERROR: metaschemas directory is empty."; \
		exit 1; \
	fi; \
	\
	echo "===> Docker CLI 29.8.0 jsonschema fix completed."

endef

EOF

    if grep -q '^define Build/Compile' "$DOCKER_MAKEFILE"; then

        if grep -q '$(Build/PrepareDockerJsonschema)' "$DOCKER_MAKEFILE"; then
            echo "===> jsonschema Build/Compile hook already exists."
        else

            sed -i \
                '/^define Build\/Compile$/a\
\t$(Build/PrepareDockerJsonschema)' \
                "$DOCKER_MAKEFILE"

            echo "===> jsonschema Build/Compile hook installed."

        fi

    else

        echo "ERROR: define Build/Compile not found in Docker Makefile."
        exit 1

    fi

else

    echo "ERROR: Docker Makefile not found:"
    echo "$DOCKER_MAKEFILE"
    exit 1

fi
