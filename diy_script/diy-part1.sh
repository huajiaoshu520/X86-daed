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
# 使用 GitHub 下载 erofs-utils 源码
sed -i \
    's|^PKG_SOURCE_URL[:]*=.*|PKG_SOURCE_URL:=https://codeload.github.com/erofs/erofs-utils/tar.gz/refs/tags/v$(PKG_VERSION)?|' \
    tools/erofs-utils/Makefile
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

# 修复 profiles.json 生成时的变量解析
python3 - <<'PY'
from pathlib import Path

path = Path("scripts/json_overview_image_info.py")
content = path.read_text(encoding="utf-8")

if "# Parse named Make variables" in content:
    print("profiles.json 解析补丁已存在")
    raise SystemExit(0)

start = content.find('    default_packages, output["arch_packages"] = run(')
end = content.find(
    '    output["default_packages"] = sorted(default_packages.split())',
    start,
)

if start < 0 or end < 0:
    raise SystemExit("未找到预期代码，请检查新版 json_overview_image_info.py")

replacement = '''    # Parse named Make variables
    import shlex

    result = run(
        [
            "make",
            "--no-print-directory",
            "-C",
            "target/linux/",
            "var.DEFAULT_PACKAGES",
            "var.ARCH_PACKAGES",
        ],
        stdout=PIPE,
        stderr=PIPE,
        check=True,
        env={**environ, "TOPDIR": str(Path.cwd())},
        universal_newlines=True,
    )

    values = {}
    for line in result.stdout.splitlines():
        if line.startswith(("DEFAULT_PACKAGES=", "ARCH_PACKAGES=")):
            fields = shlex.split(line)
            if len(fields) != 1:
                raise RuntimeError(f"无法解析 Make 变量：{line!r}")
            key, value = fields[0].split("=", 1)
            values[key] = value

    if not all(key in values for key in ("DEFAULT_PACKAGES", "ARCH_PACKAGES")):
        raise RuntimeError(
            "Make 输出缺少目标变量：\\\\n" + result.stdout + result.stderr
        )

    default_packages = values["DEFAULT_PACKAGES"]
    output["arch_packages"] = values["ARCH_PACKAGES"]

'''

content = content[:start] + replacement + content[end:]
compile(content, str(path), "exec")
path.write_text(content, encoding="utf-8")
print("已修复 profiles.json 的 Make 变量解析")
PY

# 补丁失败时停止构建
[ "$?" -eq 0 ] || exit 1
