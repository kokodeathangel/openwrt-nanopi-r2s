#!/bin/bash
#
# This is free software, license use GPLv3.
#
# Copyright (c) 2020, Chuck <fanck0605@qq.com>
#

set -eu

rm -rf openwrt
git clone -b openwrt-21.02 https://github.com/openwrt/openwrt.git openwrt

# customize patches
pushd openwrt
cat ../patches/*.patch | patch -p1
popd

# initialize feeds
feed_list=$(cd patches && find * -type d)
pushd openwrt
# clone feeds
./scripts/feeds update -a
# patching
pushd feeds
for feed in $feed_list ; do
  [ -d $feed ] && {
    pushd $feed
    cat ../../../patches/$feed/*.patch | patch -p1
    popd
  }
done
popd
popd

# addition packages
pushd openwrt/package
# luci-app-helloworld
svn co https://github.com/fw876/helloworld/trunk/luci-app-ssr-plus custom/luci-app-ssr-plus
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/shadowsocksr-libev custom/shadowsocksr-libev
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/pdnsd-alt custom/pdnsd-alt
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/microsocks custom/microsocks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/dns2socks custom/dns2socks
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/simple-obfs custom/simple-obfs
svn co https://github.com/fw876/helloworld/trunk/tcping custom/tcping
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/v2ray-plugin custom/v2ray-plugin
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/trojan custom/trojan
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/ipt2socks custom/ipt2socks
svn co https://github.com/fw876/helloworld/trunk/naiveproxy custom/naiveproxy
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/redsocks2 custom/redsocks2
# luci-app-openclash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash custom/luci-app-openclash
# luci-app-filebrowser
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/ctcgfw/luci-app-filebrowser custom/luci-app-filebrowser
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/ctcgfw/filebrowser custom/filebrowser
# luci-app-arpbind
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-arpbind custom/luci-app-arpbind
# luci-app-xlnetacc
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/lean/luci-app-xlnetacc custom/luci-app-xlnetacc
# luci-app-oled
git clone --depth 1 https://github.com/NateLol/luci-app-oled.git custom/luci-app-oled
# luci-app-unblockmusic
svn co https://github.com/cnsilvan/luci-app-unblockneteasemusic/trunk/luci-app-unblockneteasemusic custom/luci-app-unblockneteasemusic
svn co https://github.com/cnsilvan/luci-app-unblockneteasemusic/trunk/UnblockNeteaseMusic custom/UnblockNeteaseMusic
# luci-app-autoreboot
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-autoreboot custom/luci-app-autoreboot
# luci-app-vsftpd
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/lean/luci-app-vsftpd custom/luci-app-vsftpd
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/lean/vsftpd-alt custom/vsftpd-alt
# luci-app-netdata
svn co https://github.com/coolsnowwolf/lede/trunk/package/lean/luci-app-netdata custom/luci-app-netdata
# ddns-scripts
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/lean/ddns-scripts_aliyun custom/ddns-scripts_aliyun
svn co https://github.com/immortalwrt/immortalwrt/branches/openwrt-21.02/package/lean/ddns-scripts_dnspod custom/ddns-scripts_dnspod

find -maxdepth 3 -name .svn | xargs rm -rf
find -maxdepth 3 -name .git | xargs rm -rf

popd

# zh_cn to zh_Hans
pushd openwrt/package
../../scripts/convert_translation.sh
popd

# create acl files
pushd openwrt
../scripts/create_acl_for_luci.sh -a
popd

#install packages
pushd openwrt
./scripts/feeds install -a
popd

# customize configs
pushd openwrt
cat ../config.seed > .config
make defconfig
popd

# build openwrt
pushd openwrt
make download -j8
make -j$(($(nproc) + 1)) || make -j1 V=s
popd

# package output files
archive_tag=OpenWrt_$(date +%Y%m%d)_NanoPi-R2S
pushd openwrt/bin/targets/*/*
tar -zcf $archive_tag.tar.gz *
popd
mv openwrt/bin/targets/*/*/$archive_tag.tar.gz .
