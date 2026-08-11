# Scripts para configurar un VPS

Colección de scripts Bash para preparar un servidor Ubuntu e instalar herramientas habituales de administración y desarrollo. También incluye una configuración opcional de [wg-easy](https://github.com/wg-easy/wg-easy) para administrar WireGuard desde una interfaz web.

## Requisitos

- VPS o servidor con Ubuntu 22.04, 24.04 o una versión LTS posterior.
- Acceso SSH con un usuario que pueda usar `sudo`.
- Conexión a Internet.
- Para `wg-easy`: Docker y Docker Compose instalados y los puertos necesarios permitidos en el firewall y en el proveedor del VPS.

Los scripts modifican paquetes del sistema, la shell predeterminada y archivos de configuración del usuario. Revísalos antes de ejecutarlos en un servidor en producción.

## Instalación rápida

Clona el repositorio y entra en su directorio:

```bash
git clone https://github.com/xlokius/scripts-vps.git
cd scripts-vps
```

Para ejecutar todos los pasos automáticamente:

```bash
sudo ./install_all.sh
```

Este comando ejecuta, en orden:

1. `scripts/ubuntu_server_setup.sh`
2. `scripts/docker_and_compose_install.sh`
3. `scripts/zsh_install.sh`
4. `scripts/zsh_aliases_setup.sh`

Al finalizar puede ser necesario cerrar sesión y volver a entrar, o reiniciar el servidor, para aplicar el cambio de shell y los permisos del grupo `docker`.

## Instalación interactiva

Si prefieres elegir qué instalar, ejecuta:

```bash
sudo ./install_manager.sh
```

El menú permite seleccionar scripts individuales separados por comas, o usar estas opciones:

- `i`: todos los scripts de instalación.
- `p`: todos los scripts de post-instalación.
- `a`: todos los scripts disponibles.
- `q`: salir.

Antes de las opciones, el gestor muestra un panel de estado con el sistema operativo, versión, arquitectura, hostname, IP pública, hora actual y una verificación de conectividad. Si la IP pública no puede consultarse, se mostrará `No disponible` sin interrumpir el menú.

## Qué instala cada script

| Archivo | Función |
| --- | --- |
| `scripts/ubuntu_server_setup.sh` | Instala `git`, `wget`, `bat`, `eza` y `fastfetch`. Puede añadir repositorios externos si el paquete no está disponible en Ubuntu. |
| `scripts/docker_and_compose_install.sh` | Instala Docker Engine, el plugin de Docker Compose y añade el usuario al grupo `docker`. |
| `scripts/zsh_install.sh` | Instala Zsh, Oh My Zsh, `zsh-autosuggestions`, `zsh-syntax-highlighting` y el tema `materialshell`. |
| `scripts/zsh_aliases_setup.sh` | Añade aliases de `eza` y `bat` al `.zshrc` del usuario. |
| `install_manager.sh` | Menú interactivo para ejecutar los scripts anteriores y guardar logs. |
| `install_all.sh` | Ejecuta todo el flujo sin interacción y guarda un log. |

Los logs se guardan en:

```text
/var/log/vps-setup/
```

## Ejecutar un script individual

Todos los scripts de instalación requieren permisos de administrador:

```bash
sudo ./scripts/ubuntu_server_setup.sh
sudo ./scripts/docker_and_compose_install.sh
sudo ./scripts/zsh_install.sh
sudo ./scripts/zsh_aliases_setup.sh
```

Para que `zsh_install.sh` no intente abrir una shell interactiva al ejecutarse dentro de otro proceso:

```bash
sudo NONINTERACTIVE=1 ./scripts/zsh_install.sh
```

## Desplegar wg-easy

1. Entra en el directorio de Compose:

   ```bash
   cd wg-easy
   ```

2. Define la IP pública o el dominio del VPS. `WG_HOST` se obtiene de la variable `MY_IP`:

   ```bash
   export MY_IP="vpn.ejemplo.com"
   ```

3. Revisa `docker-compose.yaml`, especialmente `PASSWORD_HASH`, `WG_HOST` y los puertos publicados.

4. Inicia el servicio:

   ```bash
   docker compose up -d
   docker compose ps
   ```

5. Accede a la interfaz web mediante:

   ```text
   http://IP_O_DOMINIO_DEL_VPS:51821
   ```

WireGuard escucha en `51820/udp` y la interfaz web en `51821/tcp`. El volumen `wg-easy/wg-easy` conserva la configuración de WireGuard aunque el contenedor se recree.

Comandos útiles:

```bash
docker compose logs -f
docker compose restart
docker compose down
```

## Firewall

Si utilizas UFW, permite únicamente los puertos que necesites. Para el despliegue incluido:

```bash
sudo ufw allow 51820/udp
sudo ufw allow 51821/tcp
sudo ufw status
```

Protege el puerto de administración web con las reglas de red de tu proveedor o restringiéndolo a tu IP cuando sea posible.

## Notas y precauciones

- Haz una copia de seguridad de los archivos de configuración antes de ejecutar los scripts en un servidor existente.
- `zsh_install.sh` crea una copia de seguridad del `.zshrc` antes de modificarlo.
- El acceso sin `sudo` a Docker solo estará disponible después de renovar la sesión o ejecutar `newgrp docker`.
- Comprueba los repositorios externos antes de usarlos en entornos sujetos a políticas de seguridad.
- Verifica que la IP pública, el DNS, el firewall y el reenvío IPv4 estén configurados correctamente antes de probar WireGuard.
