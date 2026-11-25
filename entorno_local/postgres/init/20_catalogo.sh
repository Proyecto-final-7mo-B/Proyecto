#!/usr/bin/env bash
# Kaizen · 20_catalogo.sh
# Catálogo inicial de categorías: el mismo que tiene el clúster (8 categorías).
set -eo pipefail
psql -X -q -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname kaizen <<'SQL'
INSERT INTO kaizen.categoria (nombre) VALUES
    ('Aprendizaje'), ('Salud'), ('Ejercicio'), ('Sueño'), ('Finanzas'),
    ('Hidratación'), ('Lectura'), ('Meditación')
ON CONFLICT DO NOTHING;
SQL
echo "kaizen: catálogo de categorías cargado"
