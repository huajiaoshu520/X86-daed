```bash
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

set -e

echo "============================================================"
echo " Docker DIY script starting..."
echo "============================================================"


# ============================================================
# dockerd
# ============================================================

# wget https://codeload.github.com/moby/moby/tar.gz/docker-v29.7.2
# sha256sum docker-v29.7.2

sed -i \
    -e 's/29.6.1/29.8.0/g' \
    -e 's/a97bd870c4b072b7d9cc053b2a806ca3d920f192f9dc6a662e17c1b69f56f2e1/e75ffb5d2ddc1fd98138fdb5e29f707b59f415ec8697e73b8bbdf8bbbb4be8eb/g' \
    -e 's/8ec5ab3/3ce5872/g' \
    ./feeds/packages/utils/dockerd/Makefile


# ============================================================
# docker
# ============================================================

# wget https://codeload.github.com/docker/cli/tar.gz/v29.7.2
# sha256sum docker-v29.7.2

DOCKER_MAKEFILE="./feeds/packages/utils/docker/Makefile"

sed -i \
    -e 's/29.6.1/29.8.0/g' \
    -e 's/74d14dd212b07cd3328989dc6a029dde2ebbe6a878199eaaafad54916f456194/c5fadbc00c02dbecb1b7c9936e188baf9c80421a9107e7e9ad36a0923a0fc764/g' \
    -e 's/8900f1d/88096ef/g' \
    "$DOCKER_MAKEFILE"


# ============================================================
# Docker CLI 29.8.0
#
# Fix:
#
# .go_work/build/src/github.com/docker/cli/vendor/
# github.com/santhosh-tekuri/jsonschema/v6
#
# loader.go:
#
#     //go:embed metaschemas
#
# Error:
#
#     pattern metaschemas: no matching files found
#
# ============================================================

if [ -f "$DOCKER_MAKEFILE" ]; then

    echo "============================================================"
    echo " Installing Docker CLI jsonschema/v6 fix..."
    echo "============================================================"

    # --------------------------------------------------------
    # 删除之前可能安装过的旧版本修复
    # --------------------------------------------------------

    sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V1/,/^endef$/d' \
        "$DOCKER_MAKEFILE" 2>/dev/null || true

    sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V2/,/^endef$/d' \
        "$DOCKER_MAKEFILE" 2>/dev/null || true

    sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V3/,/^endef$/d' \
        "$DOCKER_MAKEFILE" 2>/dev/null || true


    # --------------------------------------------------------
    # 防止 V4 重复注入
    # --------------------------------------------------------

    if ! grep -q "OPENWRT_DOCKER_JSONSCHEMA_FIX_V4" "$DOCKER_MAKEFILE"; then

        cat >> "$DOCKER_MAKEFILE" <<'EOF'

# ============================================================
# OPENWRT_DOCKER_JSONSCHEMA_FIX_V4
# ============================================================

define Build/PrepareDockerJsonschema
	@echo "============================================================"; \
	echo " Docker CLI jsonschema/v6 metaschemas fix"; \
	echo "============================================================"; \
	\
	WORKDIR="$(PKG_BUILD_DIR)/.go_work/build/src/github.com/docker/cli"; \
	JSONSCHEMA="$$WORKDIR/vendor/github.com/santhosh-tekuri/jsonschema/v6"; \
	\
	echo "===> PKG_BUILD_DIR:"; \
	echo "$(PKG_BUILD_DIR)"; \
	\
	echo "===> Docker CLI work directory:"; \
	echo "$$WORKDIR"; \
	\
	if [ ! -d "$$WORKDIR" ]; then \
		echo "===> Creating Docker CLI work directory"; \
		mkdir -p "$$WORKDIR"; \
	fi; \
	\
	echo "===> Checking jsonschema vendor..."; \
	\
	if [ ! -d "$$JSONSCHEMA/metaschemas" ] || \
	   [ -z "$$(find "$$JSONSCHEMA/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		\
		echo "===> metaschemas missing from Docker CLI vendor"; \
		\
		echo "===> Go version:"; \
		go version; \
		\
		echo "===> Go module cache:"; \
		echo "$$(go env GOPATH)/pkg/mod"; \
		\
		echo "===> Running go mod download..."; \
		cd "$(PKG_BUILD_DIR)" && go mod download; \
		\
		echo "===> Searching jsonschema/v6 in module cache..."; \
		\
		SRC="$$(find "$$(go env GOPATH)/pkg/mod" \
			-type d \
			-path '*santhosh-tekuri/jsonschema/v6*' \
			-print \
			-quit 2>/dev/null)"; \
		\
		if [ -z "$$SRC" ]; then \
			echo "===> jsonschema/v6 not found"; \
			echo "===> Searching Go module cache again..."; \
			find "$$(go env GOPATH)/pkg/mod" \
				-type d \
				-path '*jsonschema*' \
				-print 2>/dev/null | head -50 || true; \
			exit 1; \
		fi; \
		\
		echo "===> Found jsonschema module:"; \
		echo "$$SRC"; \
		\
		if [ ! -d "$$SRC/metaschemas" ]; then \
			echo "ERROR: metaschemas directory does not exist in:"; \
			echo "$$SRC"; \
			exit 1; \
		fi; \
		\
		mkdir -p "$$JSONSCHEMA"; \
		rm -rf "$$JSONSCHEMA/metaschemas"; \
		cp -a "$$SRC/metaschemas" "$$JSONSCHEMA/"; \
		\
		echo "===> metaschemas restored"; \
	fi; \
	\
	echo "===> Final metaschemas check:"; \
	\
	if [ ! -d "$$JSONSCHEMA/metaschemas" ]; then \
		echo "ERROR: metaschemas directory is missing"; \
		exit 1; \
	fi; \
	\
	find "$$JSONSCHEMA/metaschemas" -type f -print; \
	\
	if [ -z "$$(find "$$JSONSCHEMA/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "ERROR: metaschemas directory is empty"; \
		exit 1; \
	fi; \
	\
	echo "===> Docker CLI jsonschema fix completed."

endef

EOF

    else

        echo "===> Docker jsonschema V4 fix already installed."

    fi


    # ========================================================
    # 将 hook 插入 Docker 的 Build/Compile
    # ========================================================

    if grep -q '^define Build/Compile' "$DOCKER_MAKEFILE"; then

        if ! grep -q '$(Build/PrepareDockerJsonschema)' "$DOCKER_MAKEFILE"; then

            sed -i \
                '/^define Build\/Compile$/a\	$(Build/PrepareDockerJsonschema)' \
                "$DOCKER_MAKEFILE"

            echo "===> jsonschema Build/Compile hook installed."

        else

            echo "===> jsonschema Build/Compile hook already exists."

        fi

    else

        echo "============================================================"
        echo " WARNING:"
        echo " define Build/Compile was not found."
        echo "============================================================"
        echo ""
        echo "Docker Makefile:"
        echo "$DOCKER_MAKEFILE"
        echo ""
        echo "The jsonschema fix function was installed, but"
        echo "the compile hook could not be inserted."
        echo ""

    fi

else

    echo "============================================================"
    echo " ERROR: Docker Makefile not found!"
    echo "============================================================"
    echo "$DOCKER_MAKEFILE"
    exit 1

fi


# ============================================================
# 禁用 containerd / runc vendored version check
# ============================================================

sed -i \
    -e '\|$(call EnsureVendoredVersion,containerd)|{s/^/# /}' \
    -e '\|$(call EnsureVendoredVersion,runc)|{s/^/# /}' \
    ./feeds/packages/utils/dockerd/Makefile


# ============================================================
# dockerd patches
# ============================================================

mkdir -p ./feeds/packages/utils/dockerd/patches

wget -O ./feeds/packages/utils/dockerd/patches/001-skip-copy-nested-binaries.patch \
  https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/dockerd/patches/001-skip-copy-nested-binaries.patch


# ============================================================
# Docker daemon.json
# ============================================================

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


# ============================================================
# Docker dockerd UCI config
# ============================================================

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


# ============================================================
# 完成
# ============================================================

echo ""
echo "============================================================"
echo " Docker DIY configuration completed!"
echo "============================================================"
echo " Docker CLI : 29.8.0"
echo " dockerd    : 29.8.0"
echo " jsonschema : V4 fix enabled"
echo "============================================================"
```
