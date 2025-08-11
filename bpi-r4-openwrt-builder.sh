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

echo "==== 1. LIMPIEZA PREVIA ===="
rm -rf openwrt
rm -rf mtk-openwrt-feeds 
rm -rf tmp_comxwrt

echo "==== 2. CLONA REPOSITORIOS PRINCIPALES ===="
git clone --branch openwrt-24.10 https://github.com/brudalevante/openwrt-1.git openwrt || true
cd openwrt; git checkout 4941509f573676c4678115a0a3a743ef78b63c17; cd -

git clone https://github.com/brudalevante/led-mtk.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds; git checkout 5716038e06b2a4dc30d24acb536775522ecd5e20; cd -

echo "571603" > mtk-openwrt-feeds/autobuild/unified/feed_revision

echo "==== 3. COPIA REGLAS Y LIMPIA PARCHES CONFLICTIVOS ===="
\cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. COPIA PARCHES ===="
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
\cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
\cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
\cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/
\cp -v my_files/834-v6.8-leds-trigger-netdev-Extend-speeds-up-to-10G.patch openwrt/target/linux/mediatek/patches-6.6/
\cp -v my_files/leds.mk openwrt/package/kernel/linux/modules/leds.mk

echo "==== 5. DESACTIVA PERF EN CONFIGS BASE ===="
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

echo "==== 6. CLONA Y COPIA PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt
\cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/
\cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/
\cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/
\cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/
\cp -rv tmp_comxwrt/luci-app-dawn2 openwrt/package/
\cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/
\cp -rv tmp_comxwrt/force-ledtrig-netdev openwrt/package/   # <-- Dummy netdev

echo "==== 7. ENTRA EN openwrt/ Y CONFIGURA FEEDS ===="
cd openwrt
echo "==== LIMPIANDO feeds/ previos ===="
rm -rf feeds/
echo "==== USANDO feeds.conf.default DEL REPO (OFICIAL) ===="
cat feeds.conf.default

\cp -r ../configs/mm_perf.config .config 2>/dev/null || echo "No existe mm_perf.config, omitiendo"

# Limpia perf en .config ANTES de feeds/install
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 8. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y" >> .config
echo "CONFIG_PACKAGE_luci-app-cpu-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-temp-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-dawn2=y" >> .config
echo "CONFIG_PACKAGE_luci-app-usteer2=y" >> .config
echo "CONFIG_PACKAGE_force-ledtrig-netdev=y" >> .config

echo "==== 9. GENERA DEFCONFIG Y RESUELVE DEPENDENCIAS ===="
make defconfig

echo "==== 10. VERIFICACIÓN EN .CONFIG ===="
grep perf .config || echo "perf NO está en .config"
grep fakemesh .config || echo "NO aparece fakemesh en .config"
grep autoreboot .config || echo "NO aparece autoreboot en .config"
grep cpu-status .config || echo "NO aparece cpu-status en .config"
grep temp-status .config || echo "NO aparece temp-status en .config"
grep dawn2 .config || echo "NO aparece dawn en .config"
grep usteer2 .config || echo "NO aparece usteer en .config"
grep force-ledtrig-netdev .config || echo "NO aparece force-ledtrig-netdev en .config"
grep kmod-ledtrig-netdev .config || echo "NO aparece kmod-ledtrig-netdev en .config"

echo "==== 11. DESACTIVA PERF EN EL .CONFIG FINAL (por si acaso) ===="
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== 12. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

echo "==== 13. ELIMINAR EL WARNING EN ROJO DEL MAKEFILE ===="
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

echo "==== 14. ELIMINA WARNING SHA-512 DE scripts/ipkg-make-index.sh ===="
if grep -q "WARNING: Applying padding" scripts/ipkg-make-index.sh; then
  sed -i '/WARNING: Applying padding/d' scripts/ipkg-make-index.sh
fi

echo "==== 15. COMPILA ===="
make -j$(nproc)

echo "==== 16. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
