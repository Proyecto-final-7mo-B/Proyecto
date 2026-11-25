# Kaizen

Aplicación de hábitos basada en mejora continua: check-ins diarios, rachas, la **Escalera** (ajusta la meta de cada
hábito según el desempeño), el **Laboratorio personal** (asociaciones entre hábitos, ánimo y energía) y las
**cápsulas** (un mensaje para el yo futuro que se abre al alcanzar una racha).
Proyecto Integrador de 7.º semestre, Universidad Autónoma de Aguascalientes.

## Estructura del repositorio

```
backend/          API REST (FastAPI), ETL, reportes y tareas programadas · Python 3.12
app/              Aplicación Flutter: Android, iOS, Linux, Windows, macOS y web
db/               Estructura de la base de datos (PostgreSQL 16) y sus cambios
entorno_local/    Entorno de desarrollo con Docker: PostgreSQL, MongoDB, Mailpit y poblador (ver LEEME.md)
docs/             Contrato de la API y registro de decisiones (ADR)
infraestructura/  Cómo está desplegada la infraestructura (un documento por tecnología)
```

## Arquitectura

```
App Flutter ──HTTPS──▶ Nginx (nodo1) ──▶ API FastAPI (nodo1) ──▶ PostgreSQL 16 + Patroni (nodo1-3, Azure)
                                                    └──────────▶ MongoDB analítica (HomeLab)
ETL nocturno (HomeLab): réplica de PostgreSQL → pandas → seudonimizar → MongoDB
```

Detalle de cada pieza en [`infraestructura/`](infraestructura/).

## Tecnologías

| Capa | Tecnología |
|---|---|
| App | Flutter (MVVM: ViewModel + provider + repositorios), drift (SQLite) |
| Backend | Python 3.12, FastAPI, psycopg 3 (DB-API 2.0), pymongo, pandas, Matplotlib, pytest |
| Base transaccional | PostgreSQL 16 + Patroni + etcd, 3 nodos, fragmentada por región |
| Base analítica | MongoDB 4.4 |
| Infraestructura | Azure (3 VMs), HomeLab con Podman, WireGuard, Nginx, Suricata, pgBackRest |

## Integrantes

| Integrante | Responsabilidad | Carpetas |
|---|---|---|
| Jael Dantez Contreras Estrada | Infraestructura y base de datos distribuida | `infraestructura/`, `db/`, `entorno_local/` |
| Jesús Ángel Vázquez Sánchez | Backend en Python y seguridad de la aplicación | `backend/` |
| Samuel Ignacio Rizo González | Aplicación Flutter y reportes | `app/` |
