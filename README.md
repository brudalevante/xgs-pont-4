## Quick Start

**Clone the repository:**

```bash
git clone https://github.com/brudalevante/xgs-pont-4.git
```

**Set the correct permissions:**

```bash
chmod 776 -R xgs-pont-4
```

**Enter the project directory:**

```bash
cd xgs-pont-4
```

> **Before running the builder, please read all comments in the script!**

**To start the build process:**

```bash
./bpi-r4-openwrt-builder.sh
```

---

# xgs-pont-4 (OpenWrt Kernel 6.6.100)  
*(Español abajo)*

---

## English

### About this project

This is my first public OpenWrt work, a result of months of effort and collaboration with the people and projects listed below.  
**The repository compiles OpenWrt with kernel 6.6.100** (even if some branch names mention 6.6.99, all relevant commits up to date are included).

#### What’s solved and included?  
- **No more duplicated ports.**
- **No more “disco” LEDs:** Port LEDs only light up when a cable is connected.
- **Custom patches and enhancements** applied directly to OpenWrt.
- **Support for multi-gigabit speeds:**  
  - **A custom patch has been created within OpenWrt to support 2.5Gb, 5Gb, and 10Gb interface speeds.**
- **Extra configuration:**  
  - Two folders under `config/`: `system` and `network`
  - `my_files/board.json` included and customized
  - Mesh-ready with 6 GHz support (see mesh section below)

You can check my repository or the included images to see all the work and features:  
[https://github.com/brudalevante/xgs-pont-4.git](https://github.com/brudalevante/xgs-pont-4.git)

#### This build features:
- Kernel 6.6.100 (with all patches up to date)
- Advanced LED and port management
- **Multi-gigabit (2.5G, 5G, 10G) port support**
- Custom system and network configs
- Mesh with 6G support (“fakemesh”)
- Board-specific adjustments via board.json
- Many more improvements and tested patches

### How to build

See the included script (`build_xgs-pont-4.sh`) for a step-by-step, reproducible build using your own repositories.  
**Note:** Even if your branch says 6.6.99, it includes all commits up to kernel 6.6.100 for compatibility.

---

## WARNING: BETA VERSION  
This repository and its builds are currently **BETA**.  
It works in my environment, but there may be bugs, missing features, or unexpected behaviors.  
**Use at your own risk** and feel free to report any issues or contribute improvements.

---

## Acknowledgments (English)

Special thanks to **woziwrt**—without your work and patches, this project would not have reached this level.  
Thank you **RafalB82** for the xgs-pon patch for the 8311-was-110, which allows routers to work perfectly with 10G symmetric fiber (up to 8Gbps real).  
Thanks to **GitHub Copilot** for making 6G mesh possible; after months of work, mesh networking is now available on 2G, 5G, and 6G bands!  
All work done within OpenWrt to ensure that port LEDs are only lit when a network cable is connected (and to avoid duplicated ports) is also available for anyone who wants to improve it.

Thanks for all the work so far—there is still much to do, and many ideas to come!

---

### fakemesh introduction (English)
fakemesh is a network topology with a controller (AC), one or more wired APs, and satellites (Agent). It combines wireless Mesh and AC+AP modes. Wired APs connect via Ethernet, satellites via WiFi as STA clients—enabling seamless coverage (including wired links).

**Deployment:** Connect each node to the right network, set its role, Mesh ID, and other parameters. fakemesh simplifies building hybrid networks, improving coverage and reliability.

- **Integrated by default!**

**Device Access After Setup:**  
- Controller: `http://controller.fakemesh/` or `http://ac.fakemesh/`
- AP: `http://{mac}.ap.fakemesh/` or `http://N.ap.fakemesh/`  
  (where {mac} is the AP’s MAC and N is an auto-assigned number)

**Troubleshooting:**  
If an AP loses connection for 3+ minutes, it enters failure mode with a default SSID for reconfiguration:  
- SSID: mesh-brudalevante
- PASSWORD: 12345678

**Basic Components:**  
- Controller (AC): Main router and wireless manager.
- Satellite (Agent): AP connecting by Wi-Fi.
- Wired AP: AP connecting by Ethernet.

**Key Config Parameters:**
- Mesh ID: Must match on all nodes.
- Key: Shared encryption key (leave blank for open).
- Band: 2G, 5G, or 6G; all nodes must match.
- Role: Controller, Satellite, Wired AP.
- Sync Config: Centralized config from controller.
- Access IP address: Management IP for controller.
- Fronthaul Disabled: Prevents this node from acting as uplink for others.
- Band Steer Helper: Choose DAWN or usteer.

**Wireless Management:**  
Manage all wireless (SSIDs, encryption, bandwidth, etc.) from the controller interface.

**Controller in “Bypass” Mode:**  
If the controller is not the gateway or DHCP server, set LAN IP, gateway, and DNS manually. Default is DHCP client. If using static IP, ensure it’s on the same subnet as the gateway for config sync.

---

## Español

### Sobre este proyecto

Este es mi primer trabajo público con OpenWrt, fruto de meses de esfuerzo y colaboración con las personas y proyectos que menciono más abajo.  
**El repositorio compila OpenWrt con kernel 6.6.100** (aunque en los nombres de rama ponga 6.6.99, incluye todos los commits hasta la fecha).

#### ¿Qué incluye y soluciona?
- **Adiós a los puertos duplicados.**
- **Adiós a las luces “de discoteca”:** Los LEDs solo se encienden si hay cable conectado.
- **Parches y mejoras aplicados directamente sobre OpenWrt.**
- **Soporte multigigabit:**  
  - **Se ha creado un parche dentro de OpenWrt para soportar velocidades de 2,5Gb, 5Gb y 10Gb en los puertos.**
- **Configuración extra:**  
  - Dos carpetas bajo `config/`: `system` y `network`
  - Incluido y personalizado `my_files/board.json`
  - Mesh preparado con soporte 6GHz (ver sección mesh abajo)

Puedes ver el repositorio o las imágenes para comprobar todo lo que lleva:  
[https://github.com/brudalevante/xgs-pont-4.git](https://github.com/brudalevante/xgs-pont-4.git)

#### Características de esta build:
- Kernel 6.6.100 (con todos los parches al día)
- Gestión avanzada de LEDs y puertos
- **Soporte multigigabit (2,5G, 5G, 10G) en los puertos**
- Configs system y network personalizadas
- Mesh con soporte para 6G (“fakemesh”)
- Ajustes específicos via board.json
- Muchas más mejoras y parches probados

### Cómo compilar

Consulta el script incluido (`build_xgs-pont-4.sh`) para una compilación paso a paso y reproducible usando tus propios repositorios.  
**Nota:** Aunque la rama ponga 6.6.99, incluye todos los commits necesarios para kernel 6.6.100.

---

## AVISO: VERSIÓN BETA  
Este repositorio y sus builds están en fase **BETA**.  
Funciona en mi entorno, pero puede contener errores, carecer de funciones o comportarse de forma inesperada.  
**Úsalo bajo tu responsabilidad** y no dudes en reportar problemas o proponer mejoras.

---

## Agradecimientos (Español)

Gracias especialmente a **woziwrt**, sin cuyo trabajo y parches este proyecto no habría llegado tan lejos.  
Gracias a **RafalB82** por el parche xgs-pon para el 8311-was-110, con el que los routers funcionan perfecto con fibra directa 10G simétricas (¡hasta 8G reales!).  
Gracias a **GitHub Copilot** por ayudar a hacer posible el mesh en 6G; después de meses de trabajo, la malla funcional está en bandas 2G, 5G y 6G.  
Todo el trabajo realizado dentro de OpenWrt para que los LEDs de los puertos solo se enciendan cuando se conecta un cable de red (y para evitar puertos duplicados) está disponible para quien quiera mejorarlo.

Gracias por todo el trabajo realizado hasta ahora—aún queda mucho por hacer y muchas ideas por delante.

---

### Introducción a fakemesh (Español)
fakemesh es una topología de red formada por un controlador (AC), uno o más AP cableados y satélites (Agent). Combina Mesh inalámbrico y modo AC+AP. Los AP cableados se conectan al controlador por Ethernet, los satélites por Wi-Fi como clientes STA—formando una red de cobertura continua (también con enlaces cableados).

**Despliegue sencillo:** Conecta cada nodo a la red adecuada y configura su rol, Mesh ID y otros parámetros. fakemesh facilita crear una red híbrida, mejorando cobertura y fiabilidad.

- **¡Integrado por defecto!**

**Acceso tras configurar:**  
- Controlador: `http://controller.fakemesh/` o `http://ac.fakemesh/`
- AP: `http://{mac}.ap.fakemesh/` o `http://N.ap.fakemesh/`  
  (donde {mac} es la MAC del AP y N un número autoasignado)

**Resolución de problemas:**  
Si un AP pierde conexión más de 3 minutos, entra en modo fallo con SSID por defecto para reconfiguración:  
- SSID: mesh-brudalevante
- CONTRASEÑA: 12345678

**Componentes básicos:**  
- Controlador (AC): router principal y gestor inalámbrico.
- Satélite (Agent): AP conectado por Wi-Fi.
- AP cableado: AP conectado por Ethernet.

**Parámetros clave:**
- Mesh ID: igual en todos los nodos.
- Clave: contraseña compartida (dejar en blanco para abierta).
- Banda: 2G, 5G o 6G; todos los nodos deben coincidir.
- Rol: controlador, satélite, AP cableado.
- Sync Config: configuración centralizada desde el controlador.
- Dirección IP de acceso: IP de gestión del controlador.
- Desactivar Fronthaul: impide que otros usen este nodo como uplink.
- Band Steer Helper: elige DAWN o usteer.

**Gestión inalámbrica:**  
Gestiona toda la red (SSIDs, cifrado, ancho de banda, etc.) desde la interfaz del controlador.

**Controlador en modo “Bypass”:**  
Si el controlador no es gateway ni servidor DHCP, configura IP LAN, gateway y DNS manualmente. Por defecto es cliente DHCP. Si usas IP fija, asegúrate de que esté en la misma subred que el gateway para sincronizar la configuración.

---

¡Gracias a todos los que han hecho posible este proyecto!
Gracias por todo el trabajo realizado hasta ahora—aún queda mucho por hacer y muchas ideas por delante.
