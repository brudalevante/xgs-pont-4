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

# Variables de commit/branch (modifica según tus últimos cambios)
OPENWRT_REPO="https://github.com/brudalevante/openwrt-13-08-2025.git"
OPENWRT_BRANCH="openwrt-24.10"
OPENWRT_COMMIT="1ef48cdfe461a53d61c07f74c51997f0876bfde8"

FEEDS_REPO="https://github.com/brudalevante/mtk-13-08-2025.git"
FEEDS_COMMIT="927c227f021b2b18b5494b0314413a7b0112a5e5"

FAKEMESH_REPO="https://github.com/brudalevante/fakemesh-6g.git"
FAKEMESH_BRANCH="main"

echo "==== 1. LIMPIEZA PREVIA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 2. CLONA REPOSITORIOS ===="
git clone --branch "$OPENWRT_BRANCH" "$OPENWRT_REPO" openwrt || true
cd openwrt
git checkout "$OPENWRT_COMMIT"
echo "Commit actual (OpenWrt): $(git log -1 --pretty=oneline)"
cd -

git clone "$FEEDS_REPO" mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout "$FEEDS_COMMIT"
echo "Commit actual (feeds): $(git log -1 --pretty=oneline)"
cd -

echo "${FEEDS_COMMIT:0:6}" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# Puedes activar el defconfig que te interese aquí
#\cp -r configs/defconfig mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig
#\cp -r configs/dbg_defconfig mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig	# dbg+strongswan
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
git clone --depth=1 --single-branch --branch "$FAKEMESH_BRANCH" "$FAKEMESH_REPO" tmp_comxwrt
for PKG in luci-app-fakemesh luci-app-autoreboot luci-app-cpu-status luci-app-temp-status luci-app-dawn2 luci-app-usteer2; do
  \cp -rv "tmp_comxwrt/$PKG" openwrt/package/
done

echo "==== 7. CONFIGURACIÓN OPENWRT Y FEEDS ===="
cd openwrt
echo "==== LIMPIANDO feeds/ previos ===="
rm -rf feeds/
echo "==== USANDO feeds.conf.default DEL REPO (OFICIAL) ===="
cat feeds.conf.default

\cp -r ../configs/mm_perf.config .config 2>/dev/null || echo "No existe rc1_ext_mm_config, omitiendo"

# Limpia perf en .config ANTES de feeds/install
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 8. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
for PKG in fakemesh autoreboot cpu-status temp-status dawn2 usteer2; do
  echo "CONFIG_PACKAGE_luci-app-$PKG=y" >> .config
done

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
for PKG in fakemesh autoreboot cpu-status temp-status dawn2 usteer2; do
  grep $PKG .config || echo "NO aparece $PKG en .config"
done

echo "==== 10. SEGURIDAD: DESACTIVA PERF EN EL .CONFIG FINAL (por si acaso) ===="
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

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
