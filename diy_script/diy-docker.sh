```bash
#!/bin/bash

set -e

echo "============================================================"
echo " Docker DIY script starting..."
echo "============================================================"

# ============================================================
# dockerd version
# ============================================================

sed -i \
    -e 's/29.6.1/29.8.0/g' \
    -e 's/a97bd870c4b072b7d9cc053b2a806ca3d920f192f9dc6a662e17c1b69f56f2e1/e75ffb5d2ddc1fd98138fdb5e29f707b59f415ec8697e73b8bbdf8bbbb4be8eb/g' \
    -e 's/8ec5ab3/3ce5872/g' \
    ./feeds/packages/utils/dockerd/Makefile


# ============================================================
# docker CLI version
# ============================================================

DOCKER_MAKEFILE="./feeds/packages/utils/docker/Makefile"

if [ ! -f "$DOCKER_MAKEFILE" ]; then
    echo "ERROR: Docker Makefile not found:"
    echo "$DOCKER_MAKEFILE"
    exit 1
fi

sed -i \
    -e 's/29.6.1/29.8.0/g' \
    -e 's/74d14dd212b07cd3328989dc6a029dde2ebbe6a878199eaaafad54916f456194/c5fadbc00c02dbecb1b7c9936e188baf9c80421a9107e7e9ad36a0923a0fc764/g' \
    -e 's/8900f1d/88096ef/g' \
    "$DOCKER_MAKEFILE"


# ============================================================
# Docker CLI jsonschema/v6 fix
# ============================================================

echo "===> Installing Docker CLI jsonschema/v6 fix..."

# Remove previous versions of our fix.
sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V1/,/^endef$/d' \
    "$DOCKER_MAKEFILE" 2>/dev/null || true

sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V2/,/^endef$/d' \
    "$DOCKER_MAKEFILE" 2>/dev/null || true

sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V3/,/^endef$/d' \
    "$DOCKER_MAKEFILE" 2>/dev/null || true

sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V4/,/^endef$/d' \
    "$DOCKER_MAKEFILE" 2>/dev/null || true

sed -i '/# OPENWRT_DOCKER_JSONSCHEMA_FIX_V5/,/^endef$/d' \
    "$DOCKER_MAKEFILE" 2>/dev/null || true


# Add the fix function to the Docker package Makefile.

cat >> "$DOCKER_MAKEFILE" <<'EOF'

# ============================================================
# OPENWRT_DOCKER_JSONSCHEMA_FIX_V6
# ============================================================

define Build/PrepareDockerJsonschema
	@echo "Docker CLI jsonschema/v6 metaschemas fix"; \
	WORKDIR="$(PKG_BUILD_DIR)/.go_work/build/src/github.com/docker/cli"; \
	JSONSCHEMA_DIR="$$WORKDIR/vendor/github.com/santhosh-tekuri/jsonschema/v6"; \
	echo "===> PKG_BUILD_DIR: $(PKG_BUILD_DIR)"; \
	echo "===> Docker CLI work directory: $$WORKDIR"; \
	\
	if [ -d "$$JSONSCHEMA_DIR/metaschemas" ] && \
	   [ -n "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "===> metaschemas already exists."; \
	else \
		echo "===> metaschemas is missing."; \
		echo "===> Go version:"; \
		go version; \
		\
		GOMODCACHE_DIR="$$(go env GOMODCACHE)"; \
		echo "===> Go module cache: $$GOMODCACHE_DIR"; \
		\
		echo "===> Running go mod download..."; \
		cd "$(PKG_BUILD_DIR)" && go mod download; \
		\
		echo "===> Searching jsonschema/v6 module..."; \
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
			echo "GOMODCACHE: $$GOMODCACHE_DIR"; \
			find "$$GOMODCACHE_DIR" \
				-type d \
				-path '*jsonschema*' \
				-print 2>/dev/null | head -100 || true; \
			exit 1; \
		fi; \
		\
		echo "===> Found jsonschema module: $$SRC"; \
		\
		if [ ! -d "$$SRC/metaschemas" ]; then \
			echo "ERROR: metaschemas directory not found."; \
			echo "Module: $$SRC"; \
			exit 1; \
		fi; \
		\
		echo "===> Restoring metaschemas..."; \
		mkdir -p "$$JSONSCHEMA_DIR"; \
		rm -rf "$$JSONSCHEMA_DIR/metaschemas"; \
		cp -a "$$SRC/metaschemas" "$$JSONSCHEMA_DIR/"; \
		echo "===> metaschemas restored."; \
	fi; \
	\
	echo "===> Final metaschemas check:"; \
	\
	if [ ! -d "$$JSONSCHEMA_DIR/metaschemas" ]; then \
		echo "ERROR: metaschemas directory is missing."; \
		exit 1; \
	fi; \
	\
	find "$$JSONSCHEMA_DIR/metaschemas" -type f -print; \
	\
	if [ -z "$$(find "$$JSONSCHEMA_DIR/metaschemas" -type f -print -quit 2>/dev/null)" ]; then \
		echo "ERROR: metaschemas directory is empty."; \
		exit 1; \
	fi; \
	\
	echo "===> Docker CLI jsonschema fix completed."

endef

EOF


# ============================================================
# Hook into Build/Compile
# ============================================================

if grep -q '^define Build/Compile' "$DOCKER_MAKEFILE"; then

    echo "===> Found Docker Build/Compile."

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

    echo "ERROR: define Build/Compile was not found."
    echo "Docker Makefile:"
    echo "$DOCKER_MAKEFILE"
    exit 1

fi


# ============================================================
# Disable containerd / runc vendored version check
# ============================================================

sed -i \
    -e '\|$(call EnsureVendoredVersion,containerd)|{s/^/# /}' \
    -e '\|$(call EnsureVendoredVersion,runc)|{s/^/# /}' \
    ./feeds/packages/utils/dockerd/Makefile


# ============================================================
# dockerd patch
# ============================================================

mkdir -p ./feeds/packages/utils/dockerd/patches

wget -O \
    ./feeds/packages/utils/dockerd/patches/001-skip-copy-nested-binaries.patch \
    "https://raw.githubusercontent.com/huajiaoshu520/X86-daed/refs/heads/main/patches/dockerd/patches/001-skip-copy-nested-binaries.patch"

echo "===> dockerd patch installed."


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
# Verify script configuration
# ============================================================

echo "============================================================"
echo " Docker DIY configuration completed!"
echo "============================================================"
echo " Docker CLI       : 29.8.0"
echo " dockerd          : 29.8.0"
echo " jsonschema fix   : enabled"
echo " dockerd patch    : installed"
echo "============================================================"
```
