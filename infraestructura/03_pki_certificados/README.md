# CA interna y certificados

## Qué hace
Una autoridad certificadora propia firma los certificados de todos los servicios internos. Así cada conexión
interna se cifra con TLS **y** cada lado comprueba que el otro es quien dice ser (mTLS).

## La CA

| | |
|---|---|
| Nombre | `Kaizen Internal CA` |
| Algoritmo | ECDSA P-256 |
| Vigencia | Hasta el 18-nov-2027 |
| Llave privada | **Fuera de línea**: solo en la laptop de administración, cifrada (scrypt + AES-256), con copia en USB. Se borró de los servidores con `shred` |
| Certificado público | `ca.crt`, copiado a cada servicio que necesita verificar |

**Cómo se firma un certificado:** la llave se genera **en el equipo que la va a usar**; solo viaja la solicitud
(CSR) a la laptop, se firma con la CA (pide la frase) y regresa el certificado. Ninguna llave privada sale de su equipo.

## Certificados en uso (ECDSA P-256, 90 días)

| Dónde | CN | Uso | Vence |
|---|---|---|---|
| nodo1-3 `/etc/etcd/pki/` | `nodoN` | Servidor y miembro de etcd | 16-feb-2027 |
| nodo1-3 `/etc/etcd/pki/` | `etcd-admin-nodoN` | `etcdctl` | 16-feb-2027 |
| nodo1-3 `/etc/patroni/pki/` | `nodoN` | PostgreSQL (5432) y API de Patroni (8008). El SAN incluye su IP y `localhost` | 19-feb-2027 |
| nodo1-3 `/etc/patroni/pki/` | `patroni-nodoN` | Cliente: Patroni → etcd y → otros nodos; replicación | 19-feb-2027 |
| HomeLab `/etc/kaizen-homelab/pki/` | `homelab` | Servidor: MongoDB y Grafana | 19-feb-2027 |
| HomeLab `/etc/kaizen-homelab/pki/` | `homelab-cliente` | Cliente: Prometheus/Blackbox → etcd y Patroni; plan B → primario | 19-feb-2027 |
| nodo1 `/etc/kaizen/ca.crt` | (CA) | La API verifica PostgreSQL (`verify-full`) y MongoDB | — |

El certificado **público** de Internet (Let's Encrypt) es aparte: ver [08_nginx_https](../08_nginx_https/).

## Renovación
- Prometheus vigila el vencimiento de cada certificado y alerta cuando faltan 21 días.
- Antes del 16-feb-2027 (etcd) y del 19-feb-2027 (Patroni y HomeLab) hay que emitirlos de nuevo con el mismo
  procedimiento y recargar el servicio (`sudo kpatronictl reload kaizen nodoN`, `systemctl restart etcd`).
- Antes del 18-nov-2027 hay que crear una CA nueva.

## Cómo comprobarlo

```bash
sudo openssl x509 -in /etc/patroni/pki/server.crt -noout -subject -enddate -ext subjectAltName
sudo openssl verify -CAfile /etc/patroni/pki/ca.crt /etc/patroni/pki/server.crt
```
