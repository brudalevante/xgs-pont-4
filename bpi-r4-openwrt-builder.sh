#!/bin/bash

set -e

echo "==== 1. LIMPIEZA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 2. CLONA TUS REPOS PERSONALES ===="
git clone --branch openwrt-24.10 https://github.com/brudalevante/openwrt-6.6.100.git openwrt || true
cd openwrt
git checkout 4941509f573676c4678115a0a3a743ef78b63c17
cd ..
git clone https://github.com/brudalevante/led-mtk.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout 31c492d5c761176fcb15a3099f30d846450c01f5
cd ..

echo "==== 3. PREPARA FEEDS Y CONFIGURACIONES BASE ===="
echo "31c492" > mtk-openwrt-feeds/autobuild/unified/feed_revision
cp -r my_files/w-autobuild.sh mtk-openwrt-feeds/autobuild/unified/autobuild.sh
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
chmod 776 -R mtk-openwrt-feeds/autobuild/unified
rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. COPIA PARCHES ===="
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/

echo "==== 5. CLONA Y COPIA PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-6g.git tmp_comxwrt
cp -rv tmp_comxwrt/luci-app-fakemesh openwrt/package/
cp -rv tmp_comxwrt/luci-app-autoreboot openwrt/package/
cp -rv tmp_comxwrt/luci-app-cpu-status openwrt/package/
cp -rv tmp_comxwrt/luci-app-temp-status openwrt/package/
cp -rv tmp_comxwrt/luci-app-dawn2 openwrt/package/
cp -rv tmp_comxwrt/luci-app-usteer2 openwrt/package/

echo "==== 6. COPIA ARCHIVOS DE CONFIG PERSONALIZADOS ===="
mkdir -p openwrt/package/base-files/files/etc/config
mkdir -p openwrt/package/base-files/files/etc
cp -v configs/network openwrt/package/base-files/files/etc/config/network
cp -v configs/system openwrt/package/base-files/files/etc/config/system
cp -v my_files/board.json openwrt/package/base-files/files/etc/board.json

echo "==== 7. ENTRA EN OPENWRT Y USA feeds.conf.default OFICIAL ===="
cd openwrt
rm -rf feeds/
cat feeds.conf.default

echo "==== 8. COPIA LA CONFIGURACIÓN BASE (mm_perf.config) ===="
cp -v ../configs/mm_perf.config .config

echo "==== 9. COPIA TU CONFIGURACIÓN PERSONALIZADA AL DEFCONFIG DEL AUTOBUILD ===="
cp -v ../configs/mm_perf.config ../mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig

echo "==== 10. ACTUALIZA E INSTALA FEEDS ===="
./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 11. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y" >> .config
echo "CONFIG_PACKAGE_luci-app-cpu-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-temp-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-dawn2=y" >> .config
echo "CONFIG_PACKAGE_dawn=y" >> .config
echo "CONFIG_PACKAGE_luci-app-usteer2=y" >> .config

# Limpia perf OTRA VEZ antes de make defconfig
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

make defconfig

# Limpia perf DESPUÉS de make defconfig (por si acaso)
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== VERIFICACIÓN PERF FINAL ===="
grep perf .config || echo "perf NO está en .config"

echo "==== 12. VERIFICA PAQUETES EN .CONFIG ===="
grep fakemesh .config      || echo "NO aparece fakemesh en .config"
grep autoreboot .config    || echo "NO aparece autoreboot en .config"
grep cpu-status .config    || echo "NO aparece cpu-status en .config"
grep temp-status .config   || echo "NO aparece temp-status en .config"
grep dawn2 .config         || echo "NO aparece dawn2 en .config"
grep dawn .config          || echo "NO aparece dawn en .config"
grep usteer2 .config       || echo "NO aparece usteer2 en .config"

echo "==== 13. AÑADE SEGURIDAD: DESACTIVA PERF EN EL .CONFIG FINAL (por si acaso) ===="
sed -i '/CONFIG_PACKAGE_perf=y/d' .config
sed -i '/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config

echo "==== 14. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

# ==== ELIMINAR EL WARNING EN ROJO DEL MAKEFILE ====
sed -i 's/\($(call ERROR_MESSAGE,WARNING: Applying padding.*\)/#\1/' package/Makefile

echo "==== ELIMINA WARNING SHA-512 DE scripts/ipkg-make-index.sh ===="
if grep -q "WARNING: Applying padding" scripts/ipkg-make-index.sh; then
    sed -i '/WARNING: Applying padding/d' scripts/ipkg-make-index.sh
fi

echo "==== 15. COMPILA ===="
make -j$(nproc)

echo "==== 16. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
