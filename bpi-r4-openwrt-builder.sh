#!/bin/bash
set -e

# ===== 1. DEPENDENCIAS DEL SISTEMA =====
# Ubuntu/Debian:
# sudo apt update
# sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev python3-setuptools rsync swig unzip zlib1g-dev file wget libtraceevent-dev systemtap-sdt-dev

# ===== 2. LIMPIEZA Y CLONADO DE REPOS =====
echo "==== 1. LIMPIEZA PREVIA ===="
rm -rf openwrt mtk-openwrt-feeds tmp_comxwrt

echo "==== 2. CLONANDO REPOSITORIOS ===="
git clone --branch main https://github.com/brudalevante/openwrt-6.6.100.git openwrt || true
cd openwrt && git pull && cd -
git clone https://github.com/brudalevante/mtk-openwrt-feeds.git mtk-openwrt-feeds || true
cd mtk-openwrt-feeds && git pull && cd -

# ===== 3. COPIAR REGLAS Y PARCHES (ajusta rutas si es necesario) =====
echo "==== 3. COPIANDO REGLAS Y PARCHES ===="
# Ejemplo: cp my_files/mis_patches/*.patch openwrt/...

# ===== 4A. COPIA PAQUETES PERSONALIZADOS (fakemesh-espejo) =====
echo "==== 4A. CLONANDO Y COPIANDO PAQUETES PERSONALIZADOS ===="
git clone --depth=1 --single-branch --branch main https://github.com/brudalevante/fakemesh-espejo.git tmp_comxwrt
for pkg in luci-app-fakemesh luci-app-autoreboot luci-app-cpu-status luci-app-temp-status luci-app-dawn2 luci-app-usteer2 force-ledtrig-netdev; do
  \cp -rv tmp_comxwrt/$pkg openwrt/package/
done

# ===== 4B. DESACTIVA PERF EN CONFIGS BASE DEL FEED =====
echo "==== 4B. DESACTIVA PERF EN CONFIGS BASE ===="
for cfg in \
  mtk-openwrt-feeds/autobuild/unified/filogic/mac80211/24.10/defconfig \
  mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7988_wifi7_mac80211_mlo/.config \
  mtk-openwrt-feeds/autobuild/autobuild_5.4_mac80211_release/mt7986_mac80211/.config; do
  [ -f "$cfg" ] && sed -i 's/CONFIG_PACKAGE_perf=y/# CONFIG_PACKAGE_perf is not set/' "$cfg"
done

# ===== 5. GENERA feeds.conf PRIORIZANDO TU FEED =====
echo "==== 5. CREANDO feeds.conf PRIORIZANDO TU FEED ===="
cat > openwrt/feeds.conf <<EOF
src-link mtk_openwrt_feed /home/vboxuser/xgs-pont-4/mtk-openwrt-feeds
src-git packages https://git.openwrt.org/feed/packages.git^8098a4ad60845e541473aaa15d60ce104a752036
src-git luci https://git.openwrt.org/project/luci.git^00c4c120dd0e50009c8c75392ebb6c78a1e2a61c
src-git routing https://git.openwrt.org/feed/routing.git^d8f9eab170bb63024596c4133c04a84a7aa8a454
src-git telephony https://git.openwrt.org/feed/telephony.git^2a4541d46199ac96fac214d02c908402831c4dc6
EOF

# ===== 6. ACTUALIZA E INSTALA FEEDS =====
cd openwrt
rm -rf feeds/
./scripts/feeds update -a
./scripts/feeds install -a

# ===== 7. CONFIGURACIÓN: AÑADE PAQUETES PERSONALIZADOS SOLO SI EXISTEN =====
echo "==== 7. AÑADIENDO PAQUETES PERSONALIZADOS AL .CONFIG ===="
custom_pkgs="luci-app-fakemesh luci-app-autoreboot luci-app-cpu-status luci-app-temp-status luci-app-dawn2 luci-app-usteer2 force-ledtrig-netdev kmod-ledtrig-netdev"
for pkg in $custom_pkgs; do
  if grep -qr "Package/$pkg" feeds/; then
    echo "CONFIG_PACKAGE_${pkg}=y" >> .config
  else
    echo "WARNING: $pkg NO EXISTE EN LOS FEEDS"
  fi
done

# ===== 8. LIMPIA CONFIG DE PERF Y HAZ DEFCONFIG =====
sed -i '/CONFIG_PACKAGE_perf=y/d;/# CONFIG_PACKAGE_perf is not set/d' .config
echo "# CONFIG_PACKAGE_perf is not set" >> .config
make defconfig

# ===== 9. VERIFICA QUE APARECEN LOS PAQUETES EN .CONFIG =====
echo "==== 9. VERIFICANDO .CONFIG ===="
for pkg in force-ledtrig-netdev kmod-ledtrig-netdev; do
  if grep "CONFIG_PACKAGE_${pkg}=y" .config; then
    echo "OK: $pkg activado"
  else
    echo "ERROR: $pkg NO está en .config"
  fi
done

# ===== 10. COMPILA OPENWRT =====
echo "==== 10. COMPILANDO OPENWRT ===="
make -j$(nproc)

# ===== 11. LIMPIEZA FINAL =====
cd ..
rm -rf tmp_comxwrt

echo "==== Script finalizado correctamente ===="
