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
# Check
# ============================================================

echo ""
echo "============================================================"
echo " Docker DIY configuration completed!"
echo "============================================================"
echo " Docker CLI     : 29.8.0"
echo " dockerd        : 29.8.0"
echo " dockerd patch  : installed"
echo "============================================================"
```
