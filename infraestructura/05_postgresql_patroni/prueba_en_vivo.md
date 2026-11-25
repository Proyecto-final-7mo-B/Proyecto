# Guion de la prueba en vivo: pérdida del primario y partición de red

Para la defensa. En unos 10 minutos se demuestra que, si el primario se pierde, el clúster **elige un nuevo primario
solo**, el nodo caído **se resincroniza** al volver y **no se pierde ninguna escritura confirmada**. Es el mismo
procedimiento que se probó el 22-nov-2026 (resultados al final y en `evidencia_cierre/paso8_failover.txt`).

Todo se maneja desde la laptop con [`prueba_en_vivo.sh`](prueba_en_vivo.sh), que entra por SSH a los nodos.

## Qué se demuestra

| Acto | Qué se hace | Qué debe verse | Probado el 22-nov |
|---|---|---|---|
| 1 · Partición de red (principal) | Se aísla al primario 90 s (todo su tráfico WireGuard) | Los otros dos eligen un primario nuevo en ~30 s; el aislado **se degrada solo**; al volver la red se reincorpora como réplica con `pg_rewind` | 21.7 s sin escribir; 926 de 927 escrituras confirmadas, 926 filas en la base |
| 2 · Primario congelado (si hay tiempo) | Se congelan Patroni y PostgreSQL en el primario | El *watchdog* reinicia la VM: **nunca hay dos primarios** | Reinicio ~22 s tras congelarlo; 0 escrituras confirmadas perdidas |

La idea que hay que explicar: el clúster es **CP**. Durante unos segundos no acepta escrituras (prefiere no escribir a
arriesgar datos), pero **todo lo que respondió "confirmado" sigue en la base**. El contador lo prueba: al final,
confirmados = filas en la base.

## Antes de la defensa (el día anterior)

1. Encender la VPN de la laptop y comprobar SSH a los tres nodos: `./prueba_en_vivo.sh estado`. Revisar que nodo1
   **no** sea el primario (ver "Preparación").
2. Ensayar el acto 1 completo una vez y revisar que el clúster quede sano.
3. Opcional: encender el HomeLab para mostrar el tablero de Grafana "Kaizen · Clúster y HomeLab" (panel de roles de
   Patroni) con el túnel `ssh -N -L 3000:127.0.0.1:3000 fedora-server-vpn`.

## Preparación (2 min antes)

Abrir **tres terminales** en la laptop, en `infraestructura/05_postgresql_patroni/`:

| Terminal | Comando | Para qué |
|---|---|---|
| T1 | `./prueba_en_vivo.sh estado` | Ver quién es el primario antes de empezar |
| T2 | `./prueba_en_vivo.sh observador` | Muestra cada 3 s quién es líder, la réplica síncrona y el *timeline* (corre en nodo1) |
| T3 | `./prueba_en_vivo.sh contador demo1` | Desde nodo1, como la API: escribe una fila cada ~0.2 s durante 4 min y marca cada fallo y reconexión |

El contador corre en **nodo1** porque es el único nodo desde el que `kaizen_api` puede entrar, igual que la API. Se
conecta a los tres nodos y siempre escribe en el que sea primario. Por eso **nodo1 no debe ser el primario** durante
la prueba: si lo es, antes se hace un *switchover* a la réplica síncrona
(`ssh nodo1-proyecto 'sudo kpatronictl switchover kaizen --leader nodo1 --candidate <síncrona>'`). Al 25-nov el
primario es nodo2 y la síncrona nodo3: se aísla nodo2 y debe quedar nodo3 como primario.

Decir en voz alta: *"Tenemos tres nodos. nodoX es el primario y nodoY la réplica síncrona: cada COMMIT espera a que
nodoY lo tenga. El contador está escribiendo; vamos a quitarle la red al primario."*

## Acto 1 · Partición de red

En T1:

```bash
./prueba_en_vivo.sh particion nodoX        # nodoX = el primario actual
```

Qué pasa y qué decir mientras:

| Tiempo | En T2 (observador) / T3 (contador) | Qué explicar |
|---|---|---|
| 0 s | El primario deja de responder | Se cortó todo su tráfico WireGuard: para los demás, el nodo "se perdió" |
| ~10 s | T3: `ESCRITURA FALLIDA (#n, no confirmada)` | Esa escritura **no** se confirmó: el cliente sabe que debe reintentarla |
| ~15 s | (en el aislado) Patroni se degrada solo | Sin etcd no puede renovar su liderazgo: deja de ser primario para no aceptar escrituras que nadie más tendría |
| ~30 s | T2: cambia el líder y el *timeline* sube | Venció el liderazgo (ttl 30 s) y el lado mayoritario eligió a la réplica síncrona, que tiene todo lo confirmado |
| ~30 s | T3: `RECONECTADO a 10.10.0.N tras ~22 s` | El cliente encontró solo al nuevo primario (`target_session_attrs=read-write`) |
| 90 s | Vuelve la red del aislado | La regla se quita sola |
| ~2 min | T2: el antiguo primario aparece como réplica en `streaming` | Se reincorporó con `pg_rewind`: descartó lo que no se había replicado y se sincronizó con el nuevo primario |

Al terminar el contador (4 min) o cuando ya se vea todo:

```bash
./prueba_en_vivo.sh verificar demo1
```

Debe imprimir que las **filas en la base = escrituras confirmadas** del contador, y el clúster con 3 miembros en
`streaming`, lag 0. Decir: *"Cero escrituras confirmadas perdidas; la que falló nunca se confirmó."*

## Acto 2 · Primario congelado (opcional)

Muestra que el *watchdog* impide tener dos primarios. Con el contador corriendo de nuevo
(`./prueba_en_vivo.sh contador demo2`):

```bash
./prueba_en_vivo.sh congelar nodoX         # nodoX = el primario actual
```

Patroni y PostgreSQL quedan congelados (como un servidor colgado). Patroni no alimenta el *watchdog* y el núcleo
**reinicia la VM en ~25 s**, antes de que otro nodo pueda ser elegido; nunca coexisten dos primarios. La VM vuelve sola
en 1-2 min. Al final: `./prueba_en_vivo.sh verificar demo2`.

## Si algo sale mal

| Síntoma | Qué hacer |
|---|---|
| El nodo aislado no vuelve a `streaming` a los 3 min | En ese nodo: `sudo systemctl restart patroni`. Si sigue igual: `sudo kpatronictl reinit kaizen <nodo>` |
| Quedó una regla de `iptables` | `./prueba_en_vivo.sh limpiar nodoX` (quita las reglas de la prueba) |
| No hay réplica síncrona y nadie puede escribir | Es la postura CP (`synchronous_mode_strict`): en cuanto vuelva una réplica, se reanuda. Explicarlo así |
| La terminal SSH al nodo aislado se congela | Es normal: su tráfico WireGuard está cortado 90 s. Usar las otras terminales |
| El HomeLab está apagado | No afecta la prueba (solo no hay Grafana ni plan B) |

## Después

- El primario queda en otro nodo. Si se quiere regresar: `sudo kpatronictl switchover kaizen --leader <actual>
  --candidate <síncrona>` (en modo síncrono solo se puede elegir a la réplica síncrona).
- Las filas de la prueba quedan en `kaizen.bitacora_auditoria` con `recurso` `demo1:…`. La bitácora es inmutable y no
  se borran; se identifican por esa etiqueta.

## Resultados del 22-nov-2026

| Prueba | Tiempo sin escribir | Escrituras confirmadas | Filas en la base | Resultado |
|---|---|---|---|---|
| Caída de Patroni en el primario | 26.7 s | 899 de 900 | 899 | 0 perdidas |
| Primario congelado | ~19 s sin primario | — | 105 | El *watchdog* reinició la VM; nunca hubo dos primarios |
| Partición de red del primario | 21.7 s | 926 de 927 | 926 | Nuevo primario: nodo1; nodo3 se reincorporó con `pg_rewind` |

En cada prueba, la única escritura no confirmada no quedó en la base.
