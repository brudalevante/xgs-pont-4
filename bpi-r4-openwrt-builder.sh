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

echo "==== 2. CLONA REPOSITORIOS ===="
git clone --branch mi-rama-6.6.99 https://github.com/brudalevante/openwrt.git openwrt || true
cd openwrt; git checkout 4941509f573676c4678115a0a3a743ef78b63c17; cd -;

git clone https://github.com/brudalevante/mtk-openwrt-6.6.99.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds; git checkout 31c492d5c761176fcb15a3099f30d846450c01f5; cd -;

echo "31c492" > mtk-openwrt-feeds/autobuild/unified/feed_revision

echo "==== 3. COPIA REGLAS Y LIMPIA PARCHES CONFLICTIVOS ===="
cp -v my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
echo "Verifica w-rules copiado:"
head -n 10 mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. COPIA PARCHES ===="
cp -v my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -v my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -v my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
cp -v my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/

echo "==== 5. DESACTIVA PERF EN CONFIGS BASE ===="
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

echo "==== 6. COPIA PAQUETES PERSONALIZADOS (mesh, etc) ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt
cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/
cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/
cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/
cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/
cp -rv tmp_comxwrt/luci-app-dawn2 openwrt/package/
cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/

echo "==== 7. CONFIGURACIÓN FEEDS Y .CONFIG BASE ===="
cd openwrt
rm -rf feeds/
./scripts/feeds update -a
./scripts/feeds install -a

# Opcional: Aplica extra config desde configs si lo necesitas
cp -v ../configs/mm_perf.config .config 2>/dev/null || echo "No existe mm_perf.config, omitiendo"

# Limpia y fuerza desactivación de perf (ANTES de autobuild)
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== 8. EJECUTA AUTOBUILD (REGLAS PERSONALIZADAS) ===="
cd ..
bash mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

cd openwrt

echo "==== 9. COMPROBACIÓN DE CONFIGURACIÓN KERNEL (TRIGGER NETDEV) ===="
grep CONFIG_LEDS_TRIGGER_NETDEV build_dir/target-*/linux-*/linux-*/.config || (echo "ERROR: Trigger netdev NO activado en kernel" && exit 1)
grep kmod-ledtrig-netdev .config || echo "NO aparece kmod-ledtrig-netdev en .config OpenWrt"

echo "==== 10. COMPILA ===="
make -j$(nproc)

echo "==== 11. VERIFICACIÓN POST-COMPILACIÓN ===="
find build_dir/target-*/linux-*/ -name 'ledtrig-netdev.ko' || echo "NO se generó el .ko de netdev"

echo "==== 12. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
