-- =====================================================================
-- Kaizen · 05_vistas.sql
-- Vistas: racha vigente, enmascaramiento para el panel de administrador
-- y agregados con umbral mínimo de usuarios (k-anonimato básico).
-- IA: asistido. Revisión: Jael Contreras.
-- =====================================================================
BEGIN;
SET search_path = kaizen, pg_temp;

-- La racha almacenada se calcula al registrar. Si el usuario deja de
-- registrar, la racha "vigente" cae a 0 en cuanto pasa un día
-- programado sin cumplir, sin necesidad de un proceso nocturno.
-- security_invoker (PG15+): la vista respeta la RLS de quien consulta.
CREATE VIEW v_racha_vigente WITH (security_invoker = true, security_barrier) AS
SELECT r.region, r.habito_id, h.usuario_id,
       CASE
           WHEN h.frecuencia_tipo = 'n_por_semana' THEN r.racha_actual
           WHEN r.ultima_fecha >= fn_dia_programado_anterior(h.frecuencia_tipo, h.dias_semana, current_date)
                THEN r.racha_actual
           ELSE 0
       END AS racha_actual,
       r.racha_maxima,
       r.ultima_fecha
  FROM racha r
  JOIN habito h ON h.region = r.region AND h.id = r.habito_id;

-- Panel de administrador: nunca ve el correo ni el nombre completos.
CREATE VIEW v_usuario_admin WITH (security_barrier) AS
SELECT id, region, pais, rol, fecha_registro,
       left(nombre, 1) || repeat('*', greatest(length(nombre) - 1, 2))          AS nombre_mascara,
       regexp_replace(email, '^(.)[^@]*@.*(\.[^.]+)$', '\1***@***\2')            AS email_mascara,
       (bloqueado_hasta > now())                                                AS bloqueado,
       (consentimiento_senales_en IS NOT NULL)                                  AS consiente_senales
  FROM usuario;

-- Métricas por región y categoría: se omiten grupos con menos de 5
-- usuarios para no exponer a personas identificables (riesgo R13).
CREATE VIEW v_metricas_region AS
SELECT h.region, c.nombre AS categoria,
       count(DISTINCT h.usuario_id)                        AS usuarios,
       count(*)                                            AS habitos,
       round(avg(r.racha_actual), 2)                       AS racha_promedio
  FROM habito h
  JOIN categoria c ON c.id = h.categoria_id
  JOIN racha r     ON r.region = h.region AND r.habito_id = h.id
 WHERE h.activo
 GROUP BY h.region, c.nombre
HAVING count(DISTINCT h.usuario_id) >= 5;

COMMIT;
