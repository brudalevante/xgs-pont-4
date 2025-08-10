# How to Build (English)

Clone the repository and run the build script:
```sh
git clone https://github.com/brudalevante/xgs-pont-4.git
chmod 776 -R xgs-pont-4
cd xgs-pont-4
# BEFORE RUNNING THE BUILDER, READ ALL COMMENTS IN THE SCRIPT!
./bpi-r4-openwrt-builder.sh
```
**Notes:**
- Use only VERIFIED mainline OpenWrt commits.
- Not all MTK commits on their git are fully functional or compatible with mainline OpenWrt and may require extra patching for a successful build.
- Tested on VMware Fusion, Workstation, and Hyper-V.

---

# Cómo Compilar (Español)

Clona el repositorio y ejecuta el script de compilación:
```sh
git clone https://github.com/brudalevante/xgs-pont-4.git
chmod 776 -R xgs-pont-4
cd xgs-pont-4
# ¡ANTES DE EJECUTAR EL BUILDER, LEE TODOS LOS COMENTARIOS DEL SCRIPT!
./bpi-r4-openwrt-builder.sh
```
**Notas:**
- Usa solo commits VERIFICADOS de OpenWrt mainline.
- No todos los commits de MTK en su git son completamente funcionales ni compatibles con mainline OpenWrt, y pueden requerir parches adicionales para compilar correctamente.
- Probado en VMware Fusion, Workstation y Hyper-V.

---

# About This Repository (English)

Good morning, and apologies—this is my repository in case anyone wants to take a look or make changes.

I compile based on [https://github.com/brudalevante/xgs-pont-4.git](https://github.com/brudalevante/xgs-pont-4.git), but I have made changes, patches, and modifications to OpenWrt to prevent port duplication and to ensure that the LEDs always blink (instead of staying solid), improving the overall operation.

To speed up the compilation process, I created my own OpenWrt build with these patches, and I also use the MTK (MediaTek) repository.  
Inside the `config` folder, you will find the `network` and `system` files, and in `my_files`, the `board.json` file—all of which were necessary to modify OpenWrt and create the adapted patch, so our router wouldn't look like a disco!

---

> **BETA VERSION NOTICE:**  
> This repository and its builds are currently considered **BETA**.  
> While it works in my environment, there may still be bugs, missing features, or unexpected behavior.  
> Please use at your own risk and feel free to report any issues or contribute improvements!

---

# Sobre Este Repositorio (Español)

Este es mi repositorio por si alguien quiere verlo o necesita realizar algún cambio.

Compilo sobre la versión [https://github.com/brudalevante/xgs-pont-4.git](https://github.com/brudalevante/xgs-pont-4.git), pero se han hecho cambios, parches y modificaciones en OpenWrt para evitar la duplicación de puertos y para que los LEDs estén siempre parpadeando (no fijos), mejorando así el funcionamiento.

Para agilizar la compilación, creé mi propio OpenWrt con estos parches y, además, utilizo el repositorio de MTK (MediaTek).  
Dentro de la carpeta `config` encontraréis los archivos `network` y `system` y, en `my_files`, el archivo `board.json`, que fueron necesarios para poder modificar OpenWrt y crear el parche adaptado, evitando que nuestro router pareciera una discoteca.

---

> **AVISO VERSIÓN BETA:**  
> Este repositorio y sus compilaciones están actualmente en **VERSIÓN BETA**.  
> Aunque funciona en mi entorno, puede contener errores, faltan características o presentar comportamientos inesperados.  
> Úsalo bajo tu propia responsabilidad y no dudes en reportar cualquier problema o contribuir con mejoras.

---

---

# Acknowledgments (English)

Special thanks to **woziwrt**—without your work and patches, this project would not have reached this level.  
Thank you **RafalB82** for the xgs-pon patch for the 8311-was-110, which allows my router to work perfectly with 10G symmetric fiber (up to 8Gbps real).  
Thanks to **GitHub Copilot** for making 6G mesh possible; we have worked for over a month and a half, and thanks to that we have mesh on 2G, 5G, and 6G bands!  
You can find my repository at: [https://github.com/brudalevante/xgs-pont-4.git](https://github.com/brudalevante/xgs-pont-4.git) if anyone wants to do more.  
Also, all the work done on patches and configurations in my OpenWrt, so that the LEDs only light up when a cable is connected and ports are not duplicated, is available for anyone who wants to improve it.

---

# Agradecimientos (Español)

Gracias especialmente a **woziwrt**, sin cuyo trabajo y parches este proyecto no habría llegado tan lejos.  
Gracias a **RafalB82** por su parche xgs-pon para el 8311-was-110, con el que mi router funciona perfecto con fibra directa 10 gigas simétricas (he llegado a 8 gigas reales).  
Gracias a **GitHub Copilot** por ayudar a hacer posible el mesh en 6G; llevamos más de un mes y medio trabajando en ello, ¡y gracias a eso tenemos malla funcional en bandas 2G, 5G y 6G!  
Aquí tenéis mi repositorio: [https://github.com/brudalevante/xgs-pont-4.git](https://github.com/brudalevante/xgs-pont-4.git) por si alguien quiere contribuir o experimentar.  
También todo el trabajo realizado en parches y configuraciones dentro de mi OpenWrt para que las luces no estén encendidas constantemente (solo se encienden cuando conectas el cable de red) y para que los puertos no salgan duplicados está disponible para quien quiera mejorarlo.

---

# fakemesh introduction (English)

**fakemesh** is a network topology structure consisting of a `controller (AC)`, one or more `wired APs`, and `satellites (Agent)`. It’s a hybrid network combining `wireless Mesh` and `AC+AP` modes. Wired APs connect to the controller via Ethernet, while satellites connect wirelessly as STA clients, creating a seamless wireless coverage network (which may also include wired links).

Deployment is simple: connect each node to the right network and set its role, Mesh ID, and other parameters. fakemesh makes it easy to build a hybrid network, improving both coverage and reliability.

Currently, fakemesh is integrated by default.

## Device Access After Setup

- Controller: `http://controller.fakemesh/` or `http://ac.fakemesh/`
- AP: `http://{mac}.ap.fakemesh/` or `http://N.ap.fakemesh/`  
  (where `{mac}` is the AP’s MAC and `N` is an auto-assigned number)

Example:
```
http://1.ap.fakemesh/
http://1122334455AB.ap.fakemesh/
```

## Troubleshooting

If an AP loses connection for 3+ minutes, it enters a failure mode with a default SSID for reconfiguration:
```
SSID: mesh-brudalevante
PASSWORD: 12345678
```
The management IP will be the DHCP gateway, e.g., `192.168.16.1` if your PC gets `192.168.16.x`.

## Basic Components

- **Controller (AC):** Main router and wireless manager.
- **Satellite (Agent):** AP connecting by Wi-Fi.
- **Wired AP:** AP connecting by Ethernet.

## Key Configuration Parameters

1. **Mesh ID:** Must be the same on all nodes.
2. **Key:** Shared encryption key (leave blank for open).
3. **Band:** 2G, 5G, or 6G; all nodes must match.
4. **Role:** Controller, Satellite, or Wired AP.
5. **Sync Config:** Centralized config from controller.
6. **Access IP address:** Management IP for controller.
7. **Fronthaul Disabled:** Prevents this node from acting as uplink for others.
8. **Band Steer Helper:** Choose [DAWN](https://github.com/fakemesh/dawn) or [usteer](https://github.com/fakemesh/usteer).

## Wireless Management

Manage all wireless (SSIDs, encryption, bandwidth, etc.) from the controller interface.

## Controller in “Bypass” Mode

If the controller is not the gateway or DHCP server, set its LAN IP, gateway, and DNS manually. Default is DHCP client. If using static IP, ensure it’s on the same subnet as the gateway for config sync.

---

# Introducción a fakemesh (Español)

**fakemesh** es una topología de red formada por un `controlador (AC)`, uno o más `AP cableados` y `satélites (Agent)`. Es una red híbrida que combina los modos `Mesh inalámbrico` y `AC+AP`. Los AP cableados se conectan al controlador mediante Ethernet, mientras que los satélites lo hacen por Wi-Fi como clientes STA, formando una red de cobertura inalámbrica (que también puede incluir enlaces cableados).

El despliegue es sencillo: conecta cada nodo a la red adecuada y configura su rol, Mesh ID y otros parámetros. fakemesh facilita crear una red híbrida, mejorando cobertura y fiabilidad.

Actualmente, fakemesh viene integrado por defecto.

## Acceso a Dispositivos Tras la Configuración

- Controlador: `http://controller.fakemesh/` o `http://ac.fakemesh/`
- AP: `http://{mac}.ap.fakemesh/` o `http://N.ap.fakemesh/`  
  (donde `{mac}` es la MAC del AP y `N` un número asignado automáticamente)

Ejemplo:
```
http://1.ap.fakemesh/
http://1122334455AB.ap.fakemesh/
```

## Resolución de Problemas

Si un AP pierde conexión durante más de 3 minutos, entra en modo fallo y habilita un SSID por defecto para reconfiguración:
```
SSID: mesh-brudalevante
CONTRASEÑA: 12345678
```
La IP de gestión será la puerta de enlace DHCP, por ejemplo, `192.168.16.1` si tu PC obtiene `192.168.16.x`.

## Componentes Básicos

- **Controlador (AC):** Router principal y gestor de la red inalámbrica.
- **Satélite (Agent):** AP conectado por Wi-Fi.
- **AP cableado:** AP conectado por Ethernet.

## Parámetros Clave de Configuración

1. **Mesh ID:** Igual en todos los nodos.
2. **Clave:** Contraseña compartida (dejar en blanco para abierta).
3. **Banda:** 2G, 5G o 6G; todos los nodos deben coincidir.
4. **Rol:** Controlador, Satélite o AP cableado.
5. **Sync Config:** Configuración centralizada desde el controlador.
6. **Dirección IP de acceso:** IP de gestión del controlador.
7. **Desactivar Fronthaul:** Impide que otros usen este nodo como uplink.
8. **Band Steer Helper:** Elige [DAWN](https://github.com/fakemesh/dawn) o [usteer](https://github.com/fakemesh/usteer).

## Gestión Inalámbrica

Gestiona toda la red inalámbrica (SSIDs, cifrado, ancho de banda, etc.) desde la interfaz del controlador.

## Controlador en Modo “Bypass”

Si el controlador no es gateway ni servidor DHCP, configura manualmente IP LAN, gateway y DNS. Por defecto es cliente DHCP. Si usas IP fija, asegúrate de que está en la misma subred que el gateway para sincronizar la configuración.

---

¡Gracias a todos los que han hecho posible este proyecto!
