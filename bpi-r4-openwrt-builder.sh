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
git clone --branch openwrt-24.10 https://github.com/brudalevante/openwrt-6.6.100.git openwrt || true
cd openwrt; git checkout 4941509f573676c4678115a0a3a743ef78b63c17; cd -

git clone https://github.com/brudalevante/mtk-openwrt-feeds.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds; git checkout 0553fd700709a59ff0b3d0d6cbf02246bc83bee0; cd - 

echo "0553fd" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# Puedes activar el defconfig que te interese aquí
#\cp -r configs/defconfig mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
#\cp -r configs/dbg_defconfig mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
#####\cp -r configs/dbg_defconfig_crypto mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig

# Cambia feed_revision si quieres
#\cp -r my_files/w-feed_revision mtk-openwrt-feeds/autobuild/unified/feed_revision

echo "==== 3. COPIA REGLAS Y LIMPIA PARCHES CONFLICTIVOS ===="
\cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

# Wireless regdb mods (descomenta si lo necesitas)
#rm -rf openwrt/package/firmware/wireless-regdb/patches/*.*
#rm -rf mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches/*.*
#\cp -r my_files/500-tx_power.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/firmware/wireless-regdb/patches
#\cp -r my_files/regdb.Makefile openwrt/package/firmware/wireless-regdb/Makefile

echo "==== 4. COPIA PARCHES ===="
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
\cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
\cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
\cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/

echo "==== 5. DESACTIVA PERF EN CONFIGS BASE ===="
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

echo "==== 6. COPIA PAQUETES PERSONALIZADOS (mesh, etc) ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-espejo.git tmp_comxwrt
\cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/
\cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/
\cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/
\cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/
\cp -rv tmp_comxwrt/luci-app-dawn2 openwrt/package/
\cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/
\cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/
\cp -rv tmp_comxwrt/force-ledtrig-netdev openwrt/package/

echo "==== 6B. COPIA ARCHIVOS DE CONFIG PERSONALIZADOS ===="
mkdir -p openwrt/package/base-files/files/etc/config
mkdir -p openwrt/package/base-files/files/etc

cp -v configs/network openwrt/package/base-files/files/etc/config/network
cp -v configs/system openwrt/package/base-files/files/etc/config/system
cp -v my_files/board.json openwrt/package/base-files/files/etc/board.json


# ============================================================
# CREA EL FEEDS.CONF PERSONALIZADO AQUÍ
echo "==== CREANDO feeds.conf PERSONALIZADO ===="
cat > openwrt/feeds.conf <<EOF
src-git packages https://git.openwrt.org/feed/packages.git^c7d1a8c1ae976bd0ad94a351d82ee8fbf16a81f0
src-git luci https://git.openwrt.org/project/luci.git^d6b13f648339273facc07b173546ace459c1cabe
src-git routing https://git.openwrt.org/feed/routing.git^85d040f28c21c116c905aa15a66255dde80336e7
src-git telephony https://git.openwrt.org/feed/telephony.git^2a4541d46199ac96fac214d02c908402831c4dc6
src-link mtk_openwrt_feed /home/vboxuser/xgs-pont-4/mtk-openwrt-feeds
EOF
# ============================================================

echo "==== 7. CONFIGURACIÓN OPENWRT Y FEEDS ===="
cd openwrt
echo "==== LIMPIANDO feeds/ previos ===="
rm -rf feeds/
echo "==== USANDO feeds.conf PERSONALIZADO ===="
cat feeds.conf

\cp -r ../configs/mm_perf.config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, omitiendo"

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
echo "CONFIG_PACKAGE_kmod-ledtrig-netdev=y" >> .config
echo "CONFIG_PACKAGE_dawn=y" >> .config

# Solo añade dawn si existe el paquete en feeds
if [ -d "package/feeds/packages/dawn" ]; then
    echo "CONFIG_PACKAGE_dawn=y" >> .config
else
    echo "El paquete dawn no está en feeds/packages, revisa tu feeds.conf.default."
fi

# Limpia perf OTRA VEZ antes de make defconfig
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

make defconfig

# Limpia perf DESPUÉS de make defconfig (por si acaso)
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== 9. VERIFICACIÓN PERF Y PAQUETES EN .CONFIG ===="
grep perf .config || echo "perf NO está en .config"
grep fakemesh .config || echo "NO aparece fakemesh en .config"
grep autoreboot .config || echo "NO aparece autoreboot en .config"
grep cpu-status .config || echo "NO aparece cpu-status en .config"
grep temp-status .config || echo "NO aparece temp-status en .config"
grep dawn2 .config || echo "NO aparece dawn en .config"
grep usteer2 .config || echo "NO aparece usteer en .config"
grep kmod-ledtrig-netdev .config || echo "kmod-ledtrig-netdev .config"
grep dawn .config || echo "NO aparece dawn en .config"


echo "==== 11. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# ==== ELIMINAR EL WARNING EN ROJO DEL MAKEFILE ====
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

echo "==== ELIMINA WARNING SHA-512 DE scripts/ipkg-make-index.sh ===="
if grep -q "WARNING: Applying padding" scripts/ipkg-make-index.sh; then
  sed -i '/WARNING: Applying padding/d' scripts/ipkg-make-index.sh
fi

echo "==== 12. COMPILA ===="
make -j$(nproc)

echo "==== 13. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
