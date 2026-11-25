-- =====================================================================
-- Kaizen · 07_rls.sql
-- Row-Level Security: segunda barrera contra IDOR (riesgo R2).
-- La API, al iniciar cada transacción, fija el usuario autenticado:
--     SELECT set_config('kaizen.usuario_id', '<sub del JWT>', true);
-- (true = solo para la transacción; seguro con pool de conexiones).
-- Si el código de un endpoint olvida filtrar por dueño, PostgreSQL
-- igual devuelve solo las filas del usuario autenticado.
-- Los procedimientos SECURITY DEFINER (dueño kaizen_owner) no pasan por
-- RLS y por eso validan al dueño explícitamente.
-- IA: asistido. Revisión: Jael Contreras.
-- =====================================================================
BEGIN;
SET search_path = kaizen, pg_temp;

CREATE FUNCTION fn_usuario_actual() RETURNS uuid
LANGUAGE sql STABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$ SELECT nullif(current_setting('kaizen.usuario_id', true), '')::uuid $$;
GRANT EXECUTE ON FUNCTION fn_usuario_actual() TO kaizen_api;

-- Tablas con usuario_id propio
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['habito', 'registro', 'senal_diaria', 'capsula', 'sesion'] LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('CREATE POLICY pol_dueno ON %I TO kaizen_api
                            USING (usuario_id = fn_usuario_actual())
                            WITH CHECK (usuario_id = fn_usuario_actual())', t);
    END LOOP;
END $$;

ALTER TABLE usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_dueno ON usuario TO kaizen_api
    USING (id = fn_usuario_actual()) WITH CHECK (id = fn_usuario_actual());

-- Tablas hijas de habito: visibles si el hábito (ya filtrado por RLS) lo es
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['racha', 'nivel_habito', 'sugerencia_ajuste'] LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
        EXECUTE format('CREATE POLICY pol_dueno ON %1$I TO kaizen_api
                            USING (EXISTS (SELECT 1 FROM habito h
                                            WHERE h.region = %1$I.region AND h.id = %1$I.habito_id))', t);
    END LOOP;
END $$;

-- Lectura analítica y de administración: sin filtro por dueño
-- (sus columnas ya están limitadas por GRANT en 06_roles.sql)
DO $$
DECLARE t text;
BEGIN
    FOREACH t IN ARRAY ARRAY['usuario', 'habito', 'registro', 'racha', 'nivel_habito',
                             'sugerencia_ajuste', 'senal_diaria', 'capsula'] LOOP
        EXECUTE format('CREATE POLICY pol_lectura_global ON %I FOR SELECT
                            TO kaizen_etl, kaizen_admin USING (true)', t);
    END LOOP;
END $$;

COMMIT;
