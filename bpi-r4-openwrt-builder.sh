#!/bin/bash
set -e

# ===== 1. DEPENDENCIAS DEL SISTEMA =====
# Ubuntu/Debian:
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget libtraceevent-dev systemtap-sdt-dev

# ===== 2. LIMPIEZA SOLO DE TEMPORALES, NO DE REPOS =====
echo "==== 1. LIMPIEZA PREVIA DE TEMPORALES ===="
rm -rf tmp_comxwrt

# ===== 3. CLONA REPOSITORIOS Y FIJA COMMITS EXACTOS =====
echo "==== 2. CLONA REPOSITORIOS Y CHECKOUT EXÁCTO ===="
git clone --branch openwrt-24.10 https://github.com/brudalevante/6.6.100.git openwrt || true
cd openwrt; git checkout ab309245478d6a3ce120e241c9e1ec42d7985a2a; cd -

git clone https://github.com/brudalevante/mtk-openwrt-feeds.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds; git checkout 0553fd700709a59ff0b3d0d6cbf02246bc83bee0; cd -

echo "0553fd" > mtk-openwrt-feeds/autobuild/unified/feed_revision

# ===== 4. COPIA PARCHES Y CONFIGS PERSONALIZADOS =====
echo "==== 3. COPIANDO PARCHES Y CONFIGS PERSONALIZADOS ===="
\cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
\cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
\cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/

# ===== 5. DESACTIVA PERF EN CONFIGS BASE =====
echo "==== 4. DESACTIVANDO PERF EN CONFIGS BASE ===="
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config
sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config

# ===== 6. CLONA Y COPIA PAQUETES PERSONALIZADOS =====
echo "==== 5. CLONANDO Y COPIANDO PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt
\cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/
\cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/
\cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/
\cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/
\cp -rv tmp_comxwrt/luci-app-dawn2 openwrt/package/
\cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/

# ===== 7. COPIA ARCHIVOS DE CONFIG BASE =====
echo "==== 6. COPIANDO CONFIGURACIÓN BASE ===="
mkdir -p openwrt/package/base-files/files/etc/config
mkdir -p openwrt/package/base-files/files/etc
\cp -v configs/network openwrt/package/base-files/files/etc/config/network
\cp -v configs/system openwrt/package/base-files/files/etc/config/system
\cp -v my_files/board.json openwrt/package/base-files/files/etc/board.json

# ===== 8. PRIORIZA TU FEED PERSONAL EN feeds.conf =====
echo "==== 7. CONFIGURANDO feeds.conf (TU FEED EL PRIMERO) ===="
cd openwrt
rm -rf feeds/
\cp feeds.conf.default feeds.conf.default.ORIGINAL

cat > feeds.conf <<EOF
src-git mtk_openwrt_feed https://github.com/brudalevante/mtk-openwrt-feeds.git^0553fd700709a59ff0b3d0d6cbf02246bc83bee0
src-git packages https://git.openwrt.org/feed/packages.git^8098a4ad60845e541473aaa15d60ce104a752036
src-git luci https://git.openwrt.org/project/luci.git^00c4c120dd0e50009c8c75392ebb6c78a1e2a61c
src-git routing https://git.openwrt.org/feed/routing.git^d8f9eab170bb63024596c4133c04a84a7aa8a454
src-git telephony https://git.openwrt.org/feed/telephony.git^2a4541d46199ac96fac214d02c908402831c4dc6
EOF

echo "=== FEEDS.USADOS EN COMPILACIÓN ==="
cat feeds.conf

# ===== 9. ACTUALIZA E INSTALA FEEDS =====
echo "==== 8. ACTUALIZANDO E INSTALANDO FEEDS ===="
./scripts/feeds update -a
./scripts/feeds install -a

# ===== 10. COPIA Y AJUSTA CONFIGURACIÓN BASE (.config) =====
echo "==== 9. COPIANDO CONFIGURACIÓN BASE ===="
\cp -v ../configs/mm_perf.config .config

awk '!a[$0]++' .config > .config.tmp && mv .config.tmp .config

make defconfig

# Limpia perf después de defconfig
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

# ===== 11. VERIFICA PAQUETES CRÍTICOS EN .config =====
echo "==== 10. VERIFICANDO PAQUETES IMPRESCINDIBLES EN .config ===="
check_pkg() {
  local pkg="$1"
  if grep -q "^${pkg}=y" .config; then
    echo "OK: $pkg habilitado en .config"
  else
    echo "ERROR: $pkg NO aparece habilitado en .config"
    exit 1
  fi
}

# Paquetes críticos, añade más si los necesitas:
check_pkg "CONFIG_PACKAGE_kmod-ledtrig-netdev"
check_pkg "CONFIG_PACKAGE_luci-app-fakemesh"
check_pkg "CONFIG_PACKAGE_luci-app-dawn2"
check_pkg "CONFIG_PACKAGE_luci-app-usteer2"
check_pkg "CONFIG_PACKAGE_dawn"

# ===== 12. COPIA TU CONFIGURACIÓN PERSONALIZADA AL DEFCONFIG DEL AUTOBUILD =====
echo "==== 11. COPIANDO TU CONFIGURACIÓN BASE AL DEFCONFIG DEL AUTOBUILD ===="
\cp -v ../configs/mm_perf.config ../mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig

echo "==== 12. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# ==== ELIMINAR EL WARNING EN ROJO DEL MAKEFILE ====
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

echo "==== ELIMINA WARNING SHA-512 DE scripts/ipkg-make-index.sh ===="
if grep -q "WARNING: Applying padding" scripts/ipkg-make-index.sh; then
  sed -i '/WARNING: Applying padding/d' scripts/ipkg-make-index.sh
fi

echo "==== 13. COMPILANDO ===="
make -j$(nproc)

echo "==== 14. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
