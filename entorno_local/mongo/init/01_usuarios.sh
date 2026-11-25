#!/usr/bin/env bash
# Kaizen · 01_usuarios.sh (MongoDB 4.4)
# Misma estructura que el HomeLab (infra/homelab/config/mongo/01-usuarios.js):
# base kaizen_analitica, usuarios kaizen_etl (escritura) y kaizen_api (solo lectura),
# 3 colecciones con sus índices únicos. Las contraseñas son las LOCALES de .env.
# Las colecciones quedan vacías: las llena el ETL.
# Nota: la imagen de mongo carga este archivo con "source" dentro de su propio script de arranque,
# por eso no se usa set -u (afectaría a ese script) y el error se maneja con || exit 1.

mongo --quiet --host 127.0.0.1 \
      -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin \
      kaizen_analitica <<EOF || { echo "kaizen: ERROR al inicializar MongoDB" >&2; exit 1; }
db.createUser({ user: "kaizen_etl", pwd: "${KAIZEN_MONGO_ETL_PASSWORD}",
                roles: [{ role: "readWrite", db: "kaizen_analitica" }] });
db.createUser({ user: "kaizen_api", pwd: "${KAIZEN_MONGO_API_PASSWORD}",
                roles: [{ role: "read", db: "kaizen_analitica" }] });
db.createCollection("resumen_diario");
db.createCollection("perspectivas_semanales");
db.createCollection("metricas_globales");
db.resumen_diario.createIndex({ usuario_sdn: 1, fecha: 1 }, { unique: true });
db.perspectivas_semanales.createIndex({ usuario_sdn: 1, semana: 1 }, { unique: true });
db.metricas_globales.createIndex({ fecha: 1, region: 1 }, { unique: true });
print("kaizen: MongoDB inicializado (kaizen_analitica)");
EOF
