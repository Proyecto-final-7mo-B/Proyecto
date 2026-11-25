# ADR-013 · Mantener pymongo 4.10.1 aunque pip-audit reporte avisos

- **Estado:** aceptada (24-nov-2026) · **Responsable:** Jesús Ángel Vázquez · **Revisa:** Jael Contreras

## Contexto
MongoDB de la analítica es la versión 4.4.30 (HomeLab). Infraestructura probó `pymongo==4.10.1` contra ella con TLS;
las versiones nuevas del controlador pueden dejar de soportar MongoDB 4.4. `pip-audit` reporta 5 avisos para 4.10.1,
corregidos en 4.18.x.

## Análisis de cada aviso
| Aviso | Qué afecta | ¿Nos aplica? |
|---|---|---|
| PYSEC-2026-4295 | Endpoint KMS de cifrado del lado del cliente (CSFLE) | No: no usamos CSFLE ni KMS |
| PYSEC-2026-4294 | API de GridFS con ids que no son exactos | No: no usamos GridFS |
| PYSEC-2026-4297 | Hosts con `%` en la cadena de conexión | No: la cadena viene de la configuración del servidor, nunca del usuario |
| PYSEC-2026-4296 | Desbordamiento al codificar documentos BSON enormes | Bajo: los documentos los arma el ETL con tamaños acotados |
| CVE-2026-106435 | Lectura fuera de límites al decodificar un Regex BSON truncado | Bajo: solo leemos de nuestro propio servidor por TLS |

## Decisión
Mantener 4.10.1 y omitir esos 5 avisos en `pip-audit` (`.github/workflows/ci.yml`), nombrándolos uno por uno: un aviso
nuevo sigue rompiendo el CI.

## Consecuencias
- Se revisa de nuevo cuando se actualice MongoDB o antes de la entrega final (4-dic-2026).
- Si MongoDB sube a una versión soportada por pymongo ≥ 4.18.3, se actualiza y se quitan las omisiones.