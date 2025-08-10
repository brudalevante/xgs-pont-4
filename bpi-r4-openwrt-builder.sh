#!/bin/bash

set -e

echo "==== 1. LIMPIEZA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 2. CLONA REPOS ===="
git clone --branch main https://github.com/brudalevante/openwrt-kermel-6.6.100.git openwrt || true
cd openwrt
git checkout c21df6451d0714ea6529c90d0f510aa20a5d55ce
echo "==== COMMITS DE openwrt ===="
git log --oneline | head -20
cd ..
git clone --branch main https://github.com/brudalevante/led-mtk.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds
git checkout 31c492d5c761176fcb15a3099f30d846450c01f5
echo "==== COMMITS DE mtk-openwrt-feeds ===="
git log --oneline | head -20
cd ..

echo "==== 3. PREPARA FEEDS Y REGLAS ===="
echo "31c492" > mtk-openwrt-feeds/autobuild/unified/feed_revision
cp -r my_files/w-autobuild.sh mtk-openwrt-feeds/autobuild/unified/autobuild.sh
cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules
chmod 776 -R mtk-openwrt-feeds/autobuild/unified

rm -rf mtk-openwrt-feeds/24.10/patches-feeds/108-strongswan-add-uci-support.patch

echo "==== 4. COPIA TUS PARCHES ===="
cp -r my_files/1007-wozi-arch-arm64-dts-mt7988a-add-thermal-zone.patch mtk-openwrt-feeds/24.10/patches-base/
cp -r my_files/200-wozi-libiwinfo-fix_noise_reading_for_radios.patch openwrt/package/network/utils/iwinfo/patches
cp -r my_files/99999_tx_power_check.patch mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/files/package/kernel/mt76/patches/
cp -r my_files/999-2764-net-phy-sfp-add-some-FS-copper-SFP-fixes.patch openwrt/target/linux/mediatek/patches-6.6/
# Añade aquí tus otros parches si los hay

echo "==== 5. COPIA ARCHIVOS DE CONFIG PERSONALIZADOS ===="
mkdir -p openwrt/package/base-files/files/etc/config
mkdir -p openwrt/package/base-files/files/etc

cp -v configs/network openwrt/package/base-files/files/etc/config/network
cp -v configs/system openwrt/package/base-files/files/etc/config/system
cp -v my_files/board.json openwrt/package/base-files/files/etc/board.json

echo "==== 6. ENTRA EN OPENWRT ===="
cd openwrt

echo "==== 7. CONFIGURA FEEDS ===="
rm -rf feeds/
cat feeds.conf.default

echo "==== 8. COPIA LA CONFIGURACIÓN BASE (mm_perf.config) ===="
cp -v ../configs/mm_perf.config .config

echo "==== 9. COPIA TU CONFIGURACIÓN PERSONALIZADA AL DEFCONFIG DEL AUTOBUILD ===="
cp -v ../configs/mm_perf.config ../mtk-openwrt-feeds/autobuild/unified/filogic/24.10/defconfig

echo "==== 10. DA PERMISOS DE EJECUCIÓN A FEEDS ===="
chmod +x scripts/feeds

echo "==== 11. ACTUALIZA E INSTALA FEEDS ===="
./scripts/feeds update -a
./scripts/feeds install -a

echo "==== 12. AÑADE PAQUETES PERSONALIZADOS AL .CONFIG ===="
echo "CONFIG_PACKAGE_luci-app-fakemesh=y" >> .config
echo "CONFIG_PACKAGE_luci-app-autoreboot=y" >> .config
echo "CONFIG_PACKAGE_luci-app-cpu-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-temp-status=y" >> .config
echo "CONFIG_PACKAGE_luci-app-dawn2=y" >> .config
echo "CONFIG_PACKAGE_luci-app-usteer2=y" >> .config

# Solo añade dawn si existe el paquete en feeds
if [ -d "package/feeds/packages/dawn" ]; then
    echo "CONFIG_PACKAGE_dawn=y" >> .config
else
    echo "El paquete dawn no está en feeds/packages, revisa tu feeds.conf.default."
fi

echo "==== 12b. AÑADE PAQUETES WIREGUARD AL .CONFIG (elimina duplicados previos) ===="
sed -i '/CONFIG_PACKAGE_kmod-wireguard/d' .config
sed -i '/CONFIG_PACKAGE_wireguard-tools/d' .config
sed -i '/CONFIG_PACKAGE_luci-proto-wireguard/d' .config
echo "CONFIG_PACKAGE_kmod-wireguard=y" >> .config
echo "CONFIG_PACKAGE_wireguard-tools=y" >> .config
echo "CONFIG_PACKAGE_luci-proto-wireguard=y" >> .config

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

echo "==== 13. VERIFICA PAQUETES EN .CONFIG ===="
grep fakemesh .config      || echo "NO aparece fakemesh en .config"
grep autoreboot .config    || echo "NO aparece autoreboot en .config"
grep cpu-status .config    || echo "NO aparece cpu-status en .config"
grep temp-status .config   || echo "NO aparece temp-status en .config"
grep dawn2 .config         || echo "NO aparece dawn2 en .config"
grep dawn .config          || echo "NO aparece dawn en .config"
grep usteer2 .config       || echo "NO aparece usteer2 en .config"

echo "==== 14. RESUELVE DEPENDENCIAS ===="
make defconfig

echo "==== 15. VERIFICACIÓN FINAL ===="
for pkg in \
  fakemesh autoreboot cpu-status temp-status dawn2 dawn usteer2 wireguard
do
  grep $pkg .config || echo "NO aparece $pkg en .config"
done

grep "CONFIG_PACKAGE_kmod-wireguard=y" .config || echo "ATENCIÓN: kmod-wireguard NO está marcado"
grep "CONFIG_PACKAGE_wireguard-tools=y" .config || echo "ATENCIÓN: wireguard-tools NO está marcado"
grep "CONFIG_PACKAGE_luci-proto-wireguard=y" .config || echo "ATENCIÓN: luci-proto-wireguard NO está marcado"

echo "==== 16. EJECUTA AUTOBUILD ===="
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic-mac80211-mt7988_rfb-mt7996 log_file=make

echo "==== 17. COMPILA ===="
make -j$(nproc)

echo "==== 18. LIMPIEZA FINAL ===="
cd ..
rm -rf tmp_comxwrt
