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
echo " Docker DIY script"
echo "============================================================"
# ============================================================
# dockerd
# ============================================================
# wget https://codeload.github.com/moby/moby/tar.gz/docker-v29.7.2
# sha256sum docker-v29.7.2
sed -i -e 's/29.6.1/29.8.0/g' \
       -e 's/a97bd870c4b072b7d9cc053b2a806ca3d920f192f9dc6a662e17c1b69f56f2e1/e75ffb5d2ddc1fd98138fdb5e29f707b59f415ec8697e73b8bbdf8bbbb4be8eb/g' \
       -e 's/8ec5ab3/3ce5872/g' \
       ./feeds/packages/utils/dockerd/Makefile
# ============================================================
# docker
# ============================================================
# wget https://codeload.github.com/docker/cli/tar.gz/v29.7.2
DOCKER_MAKEFILE="./feeds/packages/utils/docker/Makefile"
sed -i -e 's/29.6.1/29.8.0/g' \
       -e 's/74d14dd212b07cd3328989dc6a029dde2ebbe6a878199eaaafad54916f456194/c5fadbc00c02dbecb1b7c9936e188baf9c80421a9107e7e9ad36a0923a0fc764/g' \
       -e 's/8900f1d/88096ef/g' \
       "$DOCKER_MAKEFILE"
# ============================================================
# Docker CLI jsonschema/v6 metaschemas 修复
#
# Docker CLI 29.8.0:
#
# github.com/santhosh-tekuri/jsonschema/v6/loader.go
#
# 使用：
#
#     //go:embed metaschemas
#
# 如果 vendor 中缺少 metaschemas，会出现：
#
#     pattern metaschemas: no matching files found
#
# 修复流程：
#
# 1. Docker CLI 真正进入 Build/Compile 时执行
# 2. go mod download
# 3. go mod vendor
# 4. 检查 vendor 中的 metaschemas
# 5. 如果仍然没有，从 Go module cache 恢复
#
# ============================================================
if [ -f "$DOCKER_MAKEFILE" ]; then
    echo "===> Installing Docker CLI jsonschema fix..."
    # --------------------------------------------------------
    # 防止重复注入
    # --------------------------------------------------------
    if grep -q "OPENWRT_DOCKER_JSONSCHEMA_FIX" "$DOCKER_MAKEFILE"; then
        echo "===> Docker jsonschema fix already installed."
    else
        # ----------------------------------------------------
        # 1. 在 Makefile 尾部加入修复函数
        # ----------------------------------------------------
        cat >> "$DOCKER_MAKEFILE" <<'EOF'
# ============================================================
# OPENWRT_DOCKER_JSONSCHEMA_FIX
# ============================================================
define Build/PrepareDockerJsonschema
	@echo "============================================================"
	@echo " Docker CLI jsonschema/v6 metaschemas fix"
	@echo "============================================================"
	@JSONSCHEMA_DIR="$(PKG_BUILD_DIR)/vendor/github.com/santhosh-tekuri/jsonschema/v6"; \
	echo "===> JSONSchema directory: $$JSONSCHEMA_DIR"; \
	if [ ! -d "$$JSONSCHEMA_DIR/metaschemas" ] || \
	   [ -z "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "===> metaschemas missing"; \
		echo "===> Running go mod download..."; \
		cd "$(PKG_BUILD_DIR)" && go mod download; \
		echo "===> Running go mod vendor..."; \
		cd "$(PKG_BUILD_DIR)" && go mod vendor; \
	fi; \
	if [ ! -d "$$JSONSCHEMA_DIR/metaschemas" ] || \
	   [ -z "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "===> metaschemas still missing"; \
		echo "===> Searching Go module cache..."; \
		GOPATH_DIR="$$(go env GOPATH)"; \
		echo "===> GOPATH: $$GOPATH_DIR"; \
		SRC="$$(find "$$GOPATH_DIR/pkg/mod" \
			-type d \
			-path '*santhosh-tekuri/jsonschema/v6*' \
			-print -quit 2>/dev/null)"; \
		if [ -n "$$SRC" ] && [ -d "$$SRC/metaschemas" ]; then \
			echo "===> Found jsonschema module:"; \
			echo "$$SRC"; \
			mkdir -p "$$JSONSCHEMA_DIR"; \
			rm -rf "$$JSONSCHEMA_DIR/metaschemas"; \
			cp -a "$$SRC/metaschemas" "$$JSONSCHEMA_DIR/"; \
		else \
			echo "============================================================"; \
			echo " ERROR: jsonschema/v6 metaschemas not found!"
			echo "============================================================"; \
			echo "Go module cache:"; \
			find "$$GOPATH_DIR/pkg/mod" \
				-type d \
				-path '*santhosh-tekuri/jsonschema*' \
				-print 2>/dev/null || true; \
			exit 1; \
		fi; \
	fi; \
	echo "===> Final metaschemas check:"; \
	find "$$JSONSCHEMA_DIR/metaschemas" -type f -print; \
	if [ -z "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "ERROR: metaschemas is empty"; \
		exit 1; \
	fi; \
	echo "===> Docker CLI jsonschema fix completed."
endef
EOF
        # ----------------------------------------------------
        # 2. 找到 Build/Compile
        # ----------------------------------------------------
        if grep -q '^define Build/Compile' "$DOCKER_MAKEFILE"; then
            echo "===> Found Build/Compile."
            # ------------------------------------------------
            # 如果 Build/Compile 已经调用过，就不重复处理
            # ------------------------------------------------
            if grep -q '$(Build/PrepareDockerJsonschema)' "$DOCKER_MAKEFILE"; then
                echo "===> Build/Compile hook already exists."
            else
                # ------------------------------------------------
                # 在 define Build/Compile 后插入修复调用
                # ------------------------------------------------
                sed -i '/^define Build\/Compile$/a\\	$(Build/PrepareDockerJsonschema)' \
                    "$DOCKER_MAKEFILE"
                echo "===> Build/Compile hook installed."
            fi
        else
            echo "============================================================"
            echo " WARNING: define Build/Compile not found."
            echo " Docker jsonschema fix function was added,"
            echo " but Build/Compile hook could not be installed."
            echo "============================================================"
        fi
    fi
else
    echo "============================================================"
    echo " ERROR: Docker Makefile not found:"
    echo " $DOCKER_MAKEFILE"
    echo "============================================================"
    exit 1
fi
# ============================================================
# 禁用 containerd / runc vendored version check
# ============================================================
sed -i -e '\|$(call EnsureVendoredVersion,containerd)|{s/^/# /}' \
       -e '\|$(call EnsureVendoredVersion,runc)|{s/^/# /}' \
       ./feeds/packages/utils/dockerd/Makefile
# ============================================================
# dockerd patches
# ============================================================
mkdir -p ./feeds/packages/utils/dockerd/patches
wget -O ./feeds/packages/utils/dockerd/patches/001-skip-copy-nested-binaries.patch \
  https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/dockerd/patches/001-skip-copy-nested-binaries.patch
# ============================================================
# fw4 docker
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
# dockerd UCI config
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
echo " jsonschema : metaschemas auto-fix enabled"
echo "============================================================"
