-- =====================================================================
-- Kaizen · borra TODAS las cuentas sintéticas (@kaizen.test) y sus datos.
-- Usa sp_eliminar_cuenta (cancelación ARCO): borra el usuario, su entrada del directorio y, en cascada,
-- hábitos, check-ins, rachas, niveles, sugerencias, señales, cápsulas y sesiones.
-- La bitácora es de solo inserción (trigger T10): sus eventos se quedan, más uno de 'usuario.cancelacion'
-- por cuenta. Ninguna cuenta real se toca.
-- Uso (en el primario):  ssh nodo2-proyecto 'cd /tmp && sudo -u postgres psql -X -v ON_ERROR_STOP=1 -d kaizen' < limpiar.sql
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL search_path = kaizen, pg_temp;
DO $$
DECLARE r record; n int := 0;
BEGIN
    IF pg_is_in_recovery() THEN
        RAISE EXCEPTION 'Este nodo es una réplica: la limpieza va en el primario';
    END IF;
    FOR r IN SELECT region, id FROM usuario WHERE email LIKE '%@kaizen.test' LOOP
        CALL sp_eliminar_cuenta(r.region, r.id, NULL);
        n := n + 1;
    END LOOP;
    RAISE NOTICE 'cuentas sintéticas eliminadas: %', n;
END $$;
COMMIT;
SELECT (SELECT count(*) FROM kaizen.usuario) AS usuarios_restantes,
       (SELECT count(*) FROM kaizen.registro) AS checkins_restantes;
