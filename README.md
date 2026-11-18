# Rclone para Omarchy

Plugin de barra para Omarchy que muestra el estado de un montaje `rclone`, las transferencias activas y la actividad reciente de archivos. Incluye accesos rápidos a la interfaz web de rclone y a la carpeta montada.

## Características

- Estado del servicio `rclone-onedrive.service`.
- Transferencias activas consultadas mediante la API RC de rclone.
- Actividad local y remota: archivos creados, modificados o eliminados.
- Notificaciones de escritorio para cambios detectados.
- Rutas locales bajo `/OneDrive`.
- Clic sobre la última actividad para abrir su ruta.
- Interfaz web en `http://127.0.0.1:5572`.
- Colores y estados adaptados al tema actual de Omarchy.

## Requisitos

- Omarchy Linux con Omarchy Shell.
- `rclone` instalado.
- Un remoto configurado, por ejemplo `onedrive`.
- `fuse3` para `rclone mount`.
- `inotify-tools` para detectar cambios locales (`inotifywait`).
- `systemd --user` y `notify-send`.

Comprueba las dependencias:

```bash
command -v rclone inotifywait notify-send systemctl
rclone listremotes
```

## Instalación

### 1. Instalar el plugin

```bash
mkdir -p ~/.config/omarchy/plugins
cp -r cipriano.rclone ~/.config/omarchy/plugins/
```

Añade `cipriano.rclone` a la sección `bar.layout.right` de `~/.config/omarchy/shell.json`.

### 2. Instalar el servicio de montaje

Edita `systemd/rclone-onedrive.service` si tu remoto o punto de montaje son diferentes. Después:

```bash
mkdir -p ~/.config/systemd/user ~/.local/bin
cp systemd/rclone-onedrive.service ~/.config/systemd/user/
cp systemd/rclone-activity.service ~/.config/systemd/user/
cp systemd/rclone-remote-activity.service ~/.config/systemd/user/
cp scripts/rclone-activity-watch.sh ~/.local/bin/
cp scripts/rclone-remote-activity-watch.sh ~/.local/bin/
chmod +x ~/.local/bin/rclone-*-watch.sh
systemctl --user daemon-reload
systemctl --user enable --now rclone-onedrive.service
systemctl --user enable --now rclone-activity.service
systemctl --user enable --now rclone-remote-activity.service
```

### 3. Recargar Omarchy

```bash
omarchy restart shell
```

## Configuración

Por defecto usa:

```text
Remoto:       onedrive:
Montaje:      /OneDrive
API RC:       http://127.0.0.1:5572
Registro:     ~/.local/state/rclone/activity.log
```

Para usar otra nube, configura el remoto con `rclone config` y cambia `onedrive:` en el servicio. El botón **Interfaz web** abre la consola de rclone, donde puedes añadir y autorizar otros remotos.

## Uso

- Clic izquierdo o derecho en el icono: abre el panel.
- Clic central: actualiza la información.
- **Interfaz web**: abre la administración web de rclone.
- **Abrir carpeta**: abre `/OneDrive`.
- **Última actividad**: abre la ruta del último archivo detectado.

La detección remota se consulta cada 5 segundos. Las transferencias rápidas pueden no permanecer visibles en la cola, pero los cambios detectados se guardan en el registro y generan una notificación.

## Diagnóstico

```bash
systemctl --user status rclone-onedrive.service
systemctl --user status rclone-activity.service
systemctl --user status rclone-remote-activity.service
findmnt /OneDrive
tail -f ~/.local/state/rclone/activity.log
```

Si el montaje queda desconectado, reinicia el servicio:

```bash
systemctl --user restart rclone-onedrive.service
```

## Estructura

```text
cipriano.rclone/
├── BarWidget.qml
├── Panel.qml
├── manifest.json
├── scripts/
│   ├── rclone-activity-watch.sh
│   └── rclone-remote-activity-watch.sh
└── systemd/
    ├── rclone-onedrive.service
    ├── rclone-activity.service
    └── rclone-remote-activity.service
```

## Seguridad

La API RC escucha solo en `127.0.0.1` y se usa sin autenticación porque no se expone a la red. No publiques tu `rclone.conf`, tokens ni credenciales.

## Licencia

MIT.
