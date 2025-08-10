#!/bin/bash

#*****************************************************************************
#
# Build environment - Ubuntu 64-bit Server 24.04.2
#
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk \
# gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev \
# python3-setuptools rsync swig unzip zlib1g-dev file wget \
# libtraceevent-dev systemtap-sdt-dev libslang-dev
#
#*****************************************************************************

set -e

echo "==== 1. LIMPIA DIRECTORIOS PREVIOS ===="
rm -rf openwrt
rm -rf mtk-openwrt-feeds

echo "==== 2. CLONA REPOS ===="
git clone --branch main https://github.com/brudalevante/openwrt-kermel-6.6.100.git openwrt || true
cd openwrt
git checkout c21df6451d0714ea6529c90d0f510aa20a5d55ce
echo "==== COMMITS DE openwrt ===="
git log --oneline | head -20
cd ..

git clone --branch master https://github.com/brudalevante/led-mtk.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout 31c492d5c761176fcb15a3099f30d846450c01f5
echo "==== COMMITS DE mtk-openwrt-feeds ===="
git log --oneline | head -20
cd ..

echo "==== 3. PREPARA FEEDS Y REGLAS ===="
echo "31c492" > mtk-openwrt-feeds/autobuild/unified/feed_revision
cp -v my_files/w-autobuild.sh mtk-openwrt-feeds/autobuild/unified/autobuild.sh
cp -v my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

# Soluciona permisos ejecutables de scripts y autobuild
find mtk-openwrt-feeds/autobuild/unified -type f -name "*.sh" -exec chmod +x {} \;
chmod -R a+X mtk-openwrt-feeds/autobuild/unified

echo "==== 4. COPIA PARCHES ===="
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/

echo "==== 5. COPIA ARCHIVOS DE CONFIG PERSONALIZADOS ===="
mkdir -p openwrt/package/base-files/files/etc/config
mkdir -p openwrt/package/base-files/files/etc
cp -v configs/network openwrt/package/base-files/files/etc/config/network
cp -v configs/system openwrt/package/base-files/files/etc/config/system
cp -v my_files/board.json openwrt/package/base-files/files/etc/board.json

echo "==== 6. USA CONFIGURACIÓN BASE ===="
cp -v configs/mm_perf.config openwrt/.config

cd openwrt

echo "==== 7. REPARA PERMISOS DE SCRIPTS ===="
find scripts/ -type f -exec chmod +x {} \;
chmod +x scripts/* || true

echo "==== 8. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

echo "==== 9. AÑADE PAQUETES MESH Y WIREGUARD SIN DUPLICADOS ===="
for pkg in luci-app-fakemesh luci-app-autoreboot luci-app-cpu-status luci-app-temp-status luci-app-dawn2 luci-app-usteer2; do
    sed -i "/CONFIG_PACKAGE_$pkg/d" .config
    echo "CONFIG_PACKAGE_${pkg}=y" >> .config
done

if [ -d "package/feeds/packages/dawn" ]; then
    sed -i '/CONFIG_PACKAGE_dawn/d' .config
    echo "CONFIG_PACKAGE_dawn=y" >> .config
else
    echo "El paquete dawn no está en feeds/packages, revisa tu feeds.conf.default."
fi

for pkg in kmod-wireguard wireguard-tools luci-proto-wireguard; do
    sed -i "/CONFIG_PACKAGE_$pkg/d" .config
    echo "CONFIG_PACKAGE_${pkg}=y" >> .config
done

# Limpia perf antes y después de defconfig
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

make defconfig

sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== 10. COPIA FEEDS Y PAQUETES PERSONALIZADOS ===="
cp -r ../my_files/luci-app-3ginfo-lite-main/sms-tool/ feeds/packages/utils/sms-tool
cp -r ../my_files/luci-app-3ginfo-lite-main/luci-app-3ginfo-lite/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/luci-app-modemband/ feeds/luci/applications
cp -r ../my_files/luci-app-modemband-main/modemband/ feeds/packages/net/modemband
cp -r ../my_files/luci-app-at-socat/ feeds/luci/applications

find scripts/ -type f -exec chmod +x {} \;
chmod +x scripts/* || true

./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 11. (OPCIONAL) VERIFICACIÓN FINAL ===="
for pkg in fakemesh autoreboot cpu-status temp-status dawn2 dawn usteer2 wireguard; do
    grep $pkg .config || echo "NO aparece $pkg en .config"
done

grep "CONFIG_PACKAGE_kmod-wireguard=y" .config || echo "ATENCIÓN: kmod-wireguard NO está marcado"
grep "CONFIG_PACKAGE_wireguard-tools=y" .config || echo "ATENCIÓN: wireguard-tools NO está marcado"
grep "CONFIG_PACKAGE_luci-proto-wireguard=y" .config || echo "ATENCIÓN: luci-proto-wireguard NO está marcado"

echo "==== 12. INICIA COMPILACIÓN ===="
make menuconfig
make -j$(nproc)
