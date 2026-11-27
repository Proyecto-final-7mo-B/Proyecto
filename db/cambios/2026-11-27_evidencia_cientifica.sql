-- =====================================================================
-- Kaizen · Cambios del 27-nov-2026: respaldo científico
-- Origen: retroalimentación del profesor (26-nov-2026). Cada regla y cada valor
-- se justifican en Evidencias_generales/12_investigacion_cientifica/ (F01…F52).
--
--   1. Catálogo jerárquico: categoría (clave, color, ícono) → subcategoría
--      (sentido aumentar/reducir) → unidades permitidas (factor y paso)
--   2. Referencias científicas por subcategoría (óptimo y máximo)       [doc. 03]
--   3. habito: subcategoría, prioridad e intención "Después de ___"     [doc. 01, 07]
--   4. Evaluación con evidencia: fn_evaluar_meta y v_habito_evidencia
--   5. Escalera v2: tope en el óptimo, baja por exceso, espera tras
--      "Mantener", redondeo por unidad                                 [doc. 02]
--   6. Protector de racha: 1 día fallado por semana no rompe la racha   [doc. 01]
--   7. Cápsulas 7/30/66 (el 21 no tiene sustento)                       [doc. 01]
--   8. Logros                                                            [doc. 05]
--   9. Migración de los hábitos existentes y permisos
--
-- Se ejecuta UNA vez como postgres en el PRIMARIO, en una transacción.
-- Códigos nuevos: KZ016 unidad no permitida para la subcategoría ·
--                 KZ017 subcategoría inactiva.
-- Reversión: 2026-11-27_evidencia_cientifica_revertir.sql
-- IA: asistido (Claude). Revisión: Jael Contreras.
-- =====================================================================
\set ON_ERROR_STOP on
BEGIN;
SET LOCAL ROLE kaizen_owner;
SET LOCAL search_path = kaizen, pg_temp;

-- =====================================================================
-- 1. Catálogo jerárquico
-- =====================================================================
-- Clave estable (sin acentos ni espacios) a partir de un nombre
CREATE FUNCTION fn_clave(p_texto text) RETURNS text
LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$
    SELECT trim(BOTH '_' FROM regexp_replace(
               translate(lower(p_texto), 'áéíóúüñ', 'aeiouun'), '[^a-z0-9]+', '_', 'g'));
$$;

ALTER TABLE categoria
    ADD COLUMN clave  text,
    ADD COLUMN color  text NOT NULL DEFAULT '#1B2A5E' CHECK (color ~ '^#[0-9A-F]{6}$'),
    ADD COLUMN icono  text NOT NULL DEFAULT 'category' CHECK (icono ~ '^[a-z_0-9]{2,40}$'),
    ADD COLUMN orden  smallint NOT NULL DEFAULT 99;

CREATE TABLE subcategoria (
    id            uuid     PRIMARY KEY DEFAULT gen_random_uuid(),
    categoria_id  uuid     NOT NULL REFERENCES categoria (id),
    clave         text     NOT NULL UNIQUE CHECK (clave ~ '^[a-z_0-9]{2,40}$'),
    nombre        text     NOT NULL CHECK (length(nombre) BETWEEN 2 AND 40),
    icono         text     NOT NULL CHECK (icono ~ '^[a-z_0-9]{2,40}$'),
    sentido       text     NOT NULL DEFAULT 'aumentar' CHECK (sentido IN ('aumentar', 'reducir')),
    activa        boolean  NOT NULL DEFAULT true,
    orden         smallint NOT NULL DEFAULT 99
);
CREATE UNIQUE INDEX ux_subcategoria_nombre ON subcategoria (categoria_id, lower(nombre));
COMMENT ON TABLE subcategoria IS
    'Tipo concreto de hábito dentro de una categoría. sentido=reducir: la meta es un límite que se baja poco a poco.';

CREATE TABLE unidad_subcategoria (
    subcategoria_id  uuid          NOT NULL REFERENCES subcategoria (id) ON DELETE CASCADE,
    unidad           text          NOT NULL CHECK (length(unidad) BETWEEN 1 AND 20),
    factor_a_base    numeric(12,6) CHECK (factor_a_base > 0),     -- NULL: no se compara con la referencia
    paso             numeric(10,2) NOT NULL CHECK (paso > 0),     -- redondeo de la Escalera en esta unidad
    minimo           numeric(10,2) NOT NULL CHECK (minimo > 0),   -- límites de captura de la meta
    maximo           numeric(10,2) NOT NULL,
    orden            smallint      NOT NULL DEFAULT 1,
    PRIMARY KEY (subcategoria_id, unidad),
    CHECK (maximo >= minimo)
);
COMMENT ON COLUMN unidad_subcategoria.factor_a_base IS
    'Multiplica la meta para llevarla a la unidad de la referencia (p. ej., vasos de 250 ml → 0.25 L).';

-- =====================================================================
-- 2. Referencias científicas (doc. 03)
-- =====================================================================
CREATE TABLE referencia_cientifica (
    id               uuid          PRIMARY KEY DEFAULT gen_random_uuid(),
    subcategoria_id  uuid          NOT NULL UNIQUE REFERENCES subcategoria (id) ON DELETE CASCADE,
    periodo          text          NOT NULL CHECK (periodo IN ('dia', 'semana')),
    unidad_base      text          NOT NULL,
    optimo_desde     numeric(10,2) NOT NULL CHECK (optimo_desde >= 0),
    optimo_hasta     numeric(10,2) NOT NULL,
    maximo           numeric(10,2),                                -- NULL: sin tope (más no hace daño)
    piso_bajada      numeric(10,2) CHECK (piso_bajada >= 0),       -- la Escalera no baja de aquí por bajo cumplimiento
    cita             text          NOT NULL CHECK (length(cita) BETWEEN 3 AND 120),
    fuentes          text          NOT NULL CHECK (fuentes ~ '^F[0-9]{2}(, F[0-9]{2})*$'),
    url              text          NOT NULL CHECK (url ~ '^https://'),
    confianza        text          NOT NULL CHECK (confianza IN ('alta', 'media', 'baja')),
    nota             text          CHECK (length(nota) <= 300),
    actualizada_en   timestamptz   NOT NULL DEFAULT now(),
    CHECK (optimo_hasta >= optimo_desde),
    CHECK (maximo IS NULL OR maximo >= optimo_hasta),
    CHECK (piso_bajada IS NULL OR piso_bajada <= optimo_hasta)
);
COMMENT ON COLUMN referencia_cientifica.piso_bajada IS
    'Mínimo al que la Escalera puede bajar por bajo cumplimiento (p. ej., sueño 7 h: dormir menos no se recomienda). NULL: un paso.';
COMMENT ON TABLE referencia_cientifica IS
    'Rangos recomendados por la evidencia (Evidencias_generales/12_investigacion_cientifica/03). fuentes = claves F## de fuentes.md.';

-- ---------------------------------------------------------------------
-- Semilla: categorías (las 4 que quedan se renombran o se conservan; Bienestar es nueva)
-- ---------------------------------------------------------------------
UPDATE categoria SET nombre = 'Educación' WHERE nombre = 'Aprendizaje';
INSERT INTO categoria (nombre) VALUES ('Ejercicio'), ('Salud'), ('Educación'), ('Bienestar'), ('Finanzas')
ON CONFLICT DO NOTHING;
UPDATE categoria c SET clave = v.clave, color = v.color, icono = v.icono, orden = v.orden, activa = true
  FROM (VALUES ('Ejercicio', 'ejercicio', '#D9480F', 'fitness_center', 1),
               ('Salud',     'salud',     '#3F7D20', 'favorite',       2),
               ('Educación', 'educacion', '#2563EB', 'school',         3),
               ('Bienestar', 'bienestar', '#0F766E', 'spa',            4),
               ('Finanzas',  'finanzas',  '#92650A', 'savings',        5)) AS v(nombre, clave, color, icono, orden)
 WHERE c.nombre = v.nombre;

INSERT INTO subcategoria (categoria_id, clave, nombre, icono, sentido, orden)
SELECT c.id, v.clave, v.nombre, v.icono, v.sentido, v.orden
  FROM (VALUES
    ('ejercicio', 'aerobico_moderado',  'Aeróbico moderado',  'directions_bike',     'aumentar', 1),
    ('ejercicio', 'vigoroso',           'Vigoroso',           'directions_run',      'aumentar', 2),
    ('ejercicio', 'fuerza',             'Fuerza',             'fitness_center',      'aumentar', 3),
    ('ejercicio', 'pasos',              'Pasos',              'directions_walk',     'aumentar', 4),
    ('ejercicio', 'estiramiento',       'Estiramiento',       'accessibility_new',   'aumentar', 5),
    ('ejercicio', 'pausas_activas',     'Pausas activas',     'timer',               'aumentar', 6),
    ('salud',     'hidratacion',        'Hidratación',        'water_drop',          'aumentar', 1),
    ('salud',     'sueno',              'Sueño',              'bedtime',             'aumentar', 2),
    ('salud',     'frutas_verduras',    'Frutas y verduras',  'eco',                 'aumentar', 3),
    ('salud',     'reducir_azucar',     'Reducir azúcar',     'cookie',              'reducir',  4),
    ('salud',     'reducir_alcohol',    'Reducir alcohol',    'no_drinks',           'reducir',  5),
    ('salud',     'dejar_fumar',        'Dejar de fumar',     'smoke_free',          'reducir',  6),
    ('educacion', 'lectura',            'Lectura',            'menu_book',           'aumentar', 1),
    ('educacion', 'estudio',            'Estudio',            'edit_note',           'aumentar', 2),
    ('educacion', 'idiomas',            'Idiomas',            'translate',           'aumentar', 3),
    ('bienestar', 'meditacion',         'Meditación',         'self_improvement',    'aumentar', 1),
    ('bienestar', 'gratitud',           'Gratitud',           'volunteer_activism',  'aumentar', 2),
    ('bienestar', 'reducir_pantallas',  'Reducir pantallas',  'phonelink_off',       'reducir',  3),
    ('bienestar', 'convivencia_social', 'Convivencia social', 'groups',              'aumentar', 4),
    ('bienestar', 'aire_libre',         'Aire libre',         'park',                'aumentar', 5),
    ('finanzas',  'ahorro',             'Ahorro',             'savings',             'aumentar', 1),
    ('finanzas',  'control_gastos',     'Control de gastos',  'receipt_long',        'aumentar', 2)
  ) AS v(categoria, clave, nombre, icono, sentido, orden)
  JOIN categoria c ON c.clave = v.categoria;

-- Unidades: (subcategoría, unidad, factor a la base, paso, mínimo, máximo, orden)
INSERT INTO unidad_subcategoria (subcategoria_id, unidad, factor_a_base, paso, minimo, maximo, orden)
SELECT s.id, v.unidad, v.factor, v.paso, v.minimo, v.maximo, v.orden
  FROM (VALUES
    ('aerobico_moderado', 'min',          1,         5,    1,    1440,    1),
    ('aerobico_moderado', 'h',            60,        0.25, 0.25, 24,      2),
    ('aerobico_moderado', 'km',           NULL,      0.5,  0.5,  200,     3),
    ('vigoroso',          'min',          1,         5,    1,    1440,    1),
    ('vigoroso',          'km',           NULL,      0.5,  0.5,  200,     2),
    ('fuerza',            'min',          1,         5,    1,    600,     1),
    ('fuerza',            'repeticiones', NULL,      1,    1,    2000,    2),
    ('pasos',             'pasos',        1,         500,  500,  60000,   1),
    ('estiramiento',      'min',          1,         1,    1,    600,     1),
    ('pausas_activas',    'pausas',       1,         1,    1,    48,      1),
    ('hidratacion',       'L',            1,         0.25, 0.25, 10,      1),
    ('hidratacion',       'vasos',        0.25,      1,    1,    40,      2),
    ('hidratacion',       'ml',           0.001,     250,  250,  10000,   3),
    ('sueno',             'h',            1,         0.25, 1,    16,      1),
    ('sueno',             'min',          0.016667,  15,   60,   960,     2),
    ('frutas_verduras',   'porciones',    1,         1,    1,    20,      1),
    ('frutas_verduras',   'g',            0.0125,    50,   50,   2000,    2),
    ('reducir_azucar',    'g',            1,         5,    1,    500,     1),
    ('reducir_azucar',    'cucharaditas', 4,         1,    1,    100,     2),
    ('reducir_alcohol',   'bebidas',      1,         1,    1,    100,     1),
    ('dejar_fumar',       'cigarros',     1,         1,    1,    100,     1),
    ('lectura',           'min',          1,         5,    1,    1440,    1),
    ('lectura',           'páginas',      1.25,      1,    1,    1000,    2),
    ('estudio',           'min',          1,         5,    1,    1440,    1),
    ('estudio',           'h',            60,        0.25, 0.25, 24,      2),
    ('idiomas',           'min',          1,         5,    1,    1440,    1),
    ('meditacion',        'min',          1,         1,    1,    600,     1),
    ('gratitud',          'registros',    1,         1,    1,    21,      1),
    ('reducir_pantallas', 'min',          1,         5,    5,    1440,    1),
    ('reducir_pantallas', 'h',            60,        0.25, 0.25, 24,      2),
    ('convivencia_social','veces',        1,         1,    1,    21,      1),
    ('convivencia_social','min',          1,         15,   15,   1440,    2),
    ('aire_libre',        'min',          1,         10,   10,   1440,    1),
    ('aire_libre',        'h',            60,        0.25, 0.25, 24,      2),
    ('ahorro',            'pesos',        1,         10,   10,   1000000, 1),
    ('control_gastos',    'registros',    1,         1,    1,    50,      1),
    ('control_gastos',    'veces',        1,         1,    1,    50,      2)
  ) AS v(sub, unidad, factor, paso, minimo, maximo, orden)
  JOIN subcategoria s ON s.clave = v.sub;

-- Referencias (valores y fuentes de 03_rangos_por_subcategoria.md)
INSERT INTO referencia_cientifica (subcategoria_id, periodo, unidad_base, optimo_desde, optimo_hasta, maximo,
                                   cita, fuentes, url, confianza, nota)
SELECT s.id, v.periodo, v.base, v.od, v.oh, v.mx, v.cita, v.fuentes, v.url, v.conf, v.nota
  FROM (VALUES
    ('aerobico_moderado', 'semana', 'min', 150, 300, 600, 'OMS 2020: 150–300 min/semana; Lee 2022: sin beneficio extra después de 600',
     'F11, F12, F13', 'https://doi.org/10.1136/bjsports-2020-102955', 'alta',
     'De 300 a 600 ya no hace falta subir; arriba de 600 (≈85 min/día) no hay beneficio adicional.'),
    ('vigoroso', 'semana', 'min', 75, 150, 300, 'OMS 2020: 75–150 min/semana; Lee 2022: sin beneficio extra después de 300',
     'F11, F12', 'https://doi.org/10.1161/CIRCULATIONAHA.121.058162', 'alta',
     'Arriba de 300 min/semana: días de descanso y supervisión profesional.'),
    ('fuerza', 'semana', 'min', 30, 60, NULL, 'OMS 2020: ≥2 días/semana; Momma 2022: máximo beneficio en 30–60 min/semana',
     'F11, F14', 'https://pubmed.ncbi.nlm.nih.gov/35228201/', 'baja',
     'Curva en J: con más de 60 min/semana el beneficio adicional es incierto.'),
    ('pasos', 'dia', 'pasos', 8000, 10000, NULL, 'Paluch 2022: el beneficio se estabiliza en 8,000–10,000 pasos/día',
     'F15', 'https://doi.org/10.1016/S2468-2667(21)00302-9', 'alta',
     'Para 60 años o más el beneficio se estabiliza en 6,000–8,000.'),
    ('estiramiento', 'semana', 'min', 20, 70, NULL, 'ACSM 2011: 60 s por ejercicio en cada grupo muscular, ≥2 días/semana',
     'F16', 'https://doi.org/10.1249/MSS.0b013e318213fefb', 'media', 'Hacerlo a diario es lo más eficaz.'),
    ('pausas_activas', 'dia', 'pausas', 8, 16, NULL, 'OMS 2020: reducir el sedentarismo; Dunstan 2012: pausas frecuentes',
     'F11, F17', 'https://pubmed.ncbi.nlm.nih.gov/22374636/', 'baja',
     'Una pausa cada 30–60 min en una jornada de 8 h.'),
    ('hidratacion', 'dia', 'L', 1.5, 3.0, 4.0, 'EFSA 2010 y NASEM 2004: 1.5–3 L de bebidas al día',
     'F20, F21, F22', 'https://doi.org/10.2903/j.efsa.2010.1459', 'media',
     'No bebas más de 1 L por hora (riesgo de hiponatremia). Con calor o ejercicio intenso se necesita más.'),
    ('sueno', 'dia', 'h', 7, 9, 10, 'AASM/SRS 2015 y NSF 2015: adultos 7–9 h',
     'F18, F19', 'https://pubmed.ncbi.nlm.nih.gov/25979105/', 'alta',
     'Mayores de 65: 7–8 h. Dormir más de 10 h de forma habitual no se recomienda en adultos.'),
    ('frutas_verduras', 'dia', 'porciones', 5, 10, NULL, 'OMS: ≥400 g/día; Aune 2017: beneficio hasta 800 g/día',
     'F23, F24', 'https://doi.org/10.1093/ije/dyw319', 'alta', 'Una porción ≈ 80 g; no cuentan papa ni otros tubérculos.'),
    ('reducir_azucar', 'dia', 'g', 0, 25, 50, 'OMS: azúcares libres < 10 % de la energía (≈50 g), ideal < 5 % (≈25 g)',
     'F23', 'https://www.who.int/news-room/fact-sheets/detail/healthy-diet', 'alta', NULL),
    ('reducir_alcohol', 'semana', 'bebidas', 0, 2, 6, 'OMS 2023: ningún nivel es seguro; Canadá 2023: 1–2 por semana riesgo bajo',
     'F25, F26', 'https://ccsa.ca/canadas-guidance-alcohol-and-health-final-report', 'media',
     '3–6 bebidas por semana: riesgo moderado; 7 o más: riesgo cada vez más alto.'),
    ('dejar_fumar', 'dia', 'cigarros', 0, 0, NULL, 'Hackshaw 2018: no hay un nivel seguro de tabaco',
     'F27', 'https://doi.org/10.1136/bmj.j5855', 'alta', 'La meta final es dejarlo; la Escalera baja el límite poco a poco.'),
    ('lectura', 'semana', 'min', 210, 420, NULL, 'Bavishi 2016: beneficio mayor con más de 3.5 h/semana (≈30 min/día)',
     'F28, F29', 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5105607', 'baja',
     'Asociación observacional. Páginas → minutos con 238 palabras/min (Brysbaert 2019).'),
    ('estudio', 'dia', 'min', 30, 180, 240, 'Ericsson 1993: ≈4 h/día de práctica deliberada como máximo; Cepeda 2006: repartir',
     'F30, F31', 'https://doi.org/10.1037/0033-295X.100.3.363', 'baja', 'Mejor en bloques repartidos que todo seguido.'),
    ('idiomas', 'dia', 'min', 15, 60, 240, 'Cepeda 2006: práctica espaciada; Ericsson 1993: tope de ≈4 h/día',
     'F30, F31', 'https://doi.org/10.1037/0033-2909.132.3.354', 'baja', 'Rango práctico: no hay estudios de dosis diaria.'),
    ('meditacion', 'dia', 'min', 10, 20, 45, 'Strohmaier 2020: más minutos no mejoran el ánimo; MBSR ≈45 min/día',
     'F32, F33, F34', 'https://doi.org/10.1007/s12671-020-01319-4', 'media',
     'Si notas malestar al meditar, haz una pausa (Britton 2021).'),
    ('gratitud', 'semana', 'registros', 1, 3, NULL, 'Emmons 2003; Lyubomirsky 2005: 1 vez por semana funcionó mejor que 3',
     'F35, F36', 'https://doi.org/10.1037/0022-3514.84.2.377', 'baja', 'Repetirlo demasiado desgasta el efecto.'),
    ('aire_libre', 'semana', 'min', 120, 300, NULL, 'White 2019: beneficio desde 120 min/semana, máximo en 200–300',
     'F39', 'https://doi.org/10.1038/s41598-019-44097-3', 'media', 'Se puede repartir en varias salidas.')
  ) AS v(sub, periodo, base, od, oh, mx, cita, fuentes, url, conf, nota)
  JOIN subcategoria s ON s.clave = v.sub;

-- Pisos de bajada: bajar la meta por debajo de esto contradice la evidencia
UPDATE referencia_cientifica r SET piso_bajada = v.piso
  FROM (VALUES ('sueno', 7), ('hidratacion', 1.5)) AS v(sub, piso)
  JOIN subcategoria s ON s.clave = v.sub
 WHERE r.subcategoria_id = s.id;

-- =====================================================================
-- 3. habito: subcategoría, prioridad e intención
-- =====================================================================
ALTER TABLE habito
    ADD COLUMN subcategoria_id uuid REFERENCES subcategoria (id),
    ADD COLUMN prioridad       smallint NOT NULL DEFAULT 2 CHECK (prioridad BETWEEN 1 AND 3),
    ADD COLUMN intencion       text CHECK (length(intencion) BETWEEN 1 AND 120);
COMMENT ON COLUMN habito.prioridad IS '1 alta, 2 media, 3 baja. Hoy ordena los pendientes por prioridad y nombre (doc. 07).';
COMMENT ON COLUMN habito.intencion IS 'Señal del contexto "Después de ___" (intención de implementación, F04).';

-- ---------------------------------------------------------------------
-- Migración de los hábitos existentes (todos sintéticos o de prueba)
-- ---------------------------------------------------------------------
UPDATE habito SET unidad = CASE lower(unidad) WHEN 'minutos' THEN 'min' WHEN 'minuto' THEN 'min'
                                              WHEN 'horas' THEN 'h' WHEN 'hora' THEN 'h'
                                              WHEN 'litros' THEN 'L' WHEN 'l' THEN 'L'
                                              WHEN 'paginas' THEN 'páginas' WHEN 'pagina' THEN 'páginas'
                                              ELSE unidad END
 WHERE lower(unidad) IN ('minutos', 'minuto', 'horas', 'hora', 'litros', 'l', 'paginas', 'pagina');

WITH mapa AS (
    SELECT h.region, h.id,
           CASE c.nombre
               WHEN 'Educación'   THEN CASE WHEN h.nombre ~* 'ingl|idioma|franc|alem|japon|portug' THEN 'idiomas'
                                            ELSE 'estudio' END
               WHEN 'Lectura'     THEN 'lectura'
               WHEN 'Hidratación' THEN 'hidratacion'
               WHEN 'Sueño'       THEN 'sueno'
               WHEN 'Meditación'  THEN 'meditacion'
               WHEN 'Ejercicio'   THEN CASE WHEN h.nombre ~* 'estir'                        THEN 'estiramiento'
                                            WHEN h.nombre ~* 'lagart|fuerza|pesas|sentadill' THEN 'fuerza'
                                            WHEN h.nombre ~* 'pasos'                        THEN 'pasos'
                                            ELSE 'aerobico_moderado' END
               WHEN 'Salud'       THEN 'frutas_verduras'
               WHEN 'Finanzas'    THEN CASE WHEN h.nombre ~* 'gasto' THEN 'control_gastos' ELSE 'ahorro' END
           END AS sub
      FROM habito h JOIN categoria c ON c.id = h.categoria_id
)
UPDATE habito h SET subcategoria_id = s.id, categoria_id = s.categoria_id
  FROM mapa m JOIN subcategoria s ON s.clave = m.sub
 WHERE h.region = m.region AND h.id = m.id;

-- Categorías creadas por un admin (fuera del catálogo): reciben clave y una subcategoría "General"
UPDATE categoria SET clave = fn_clave(nombre) WHERE clave IS NULL
   AND nombre NOT IN ('Lectura', 'Hidratación', 'Sueño', 'Meditación');
INSERT INTO subcategoria (categoria_id, clave, nombre, icono)
SELECT c.id, left(c.clave, 30) || '_general', 'General', 'category'
  FROM categoria c
 WHERE c.clave IS NOT NULL AND NOT EXISTS (SELECT 1 FROM subcategoria s WHERE s.categoria_id = c.id);
UPDATE habito h SET subcategoria_id = s.id
  FROM subcategoria s
 WHERE h.subcategoria_id IS NULL AND s.categoria_id = h.categoria_id AND s.nombre = 'General';
INSERT INTO unidad_subcategoria (subcategoria_id, unidad, factor_a_base, paso, minimo, maximo)
SELECT DISTINCT s.id, h.unidad, NULL::numeric, 1, 0.01, 1000000
  FROM habito h JOIN subcategoria s ON s.id = h.subcategoria_id AND s.nombre = 'General'
ON CONFLICT DO NOTHING;

-- Las 4 categorías que pasaron a ser subcategorías ya no tienen hábitos: se eliminan
DELETE FROM categoria WHERE nombre IN ('Lectura', 'Hidratación', 'Sueño', 'Meditación');

ALTER TABLE categoria ALTER COLUMN clave SET NOT NULL,
                      ADD CONSTRAINT categoria_clave_key UNIQUE (clave),
                      ADD CONSTRAINT categoria_clave_formato CHECK (clave ~ '^[a-z_0-9]{2,40}$');
ALTER TABLE habito ALTER COLUMN subcategoria_id SET NOT NULL;
CREATE INDEX ix_habito_subcategoria ON habito (subcategoria_id);

-- ---------------------------------------------------------------------
-- Guardia: la subcategoría manda (fija la categoría), debe estar activa y la
-- unidad debe ser una de las permitidas. Se llama "a_" para correr ANTES de
-- trg_habito_categoria_activa (los BEFORE se disparan en orden alfabético).
-- Los hábitos migrados conservan su unidad aunque no esté en la lista.
-- ---------------------------------------------------------------------
CREATE FUNCTION tg_habito_subcategoria() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    s record;
    u record;
BEGIN
    IF NEW.subcategoria_id IS NULL THEN
        RAISE EXCEPTION 'La subcategoría es obligatoria' USING ERRCODE = 'KZ011';
    END IF;
    SELECT categoria_id, activa INTO s FROM subcategoria WHERE id = NEW.subcategoria_id;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Subcategoría no encontrada' USING ERRCODE = 'KZ011';
    END IF;

    IF TG_OP = 'INSERT' OR NEW.subcategoria_id <> OLD.subcategoria_id THEN
        IF NOT s.activa THEN
            RAISE EXCEPTION 'La subcategoría no está disponible' USING ERRCODE = 'KZ017';
        END IF;
        IF TG_OP = 'INSERT' AND NEW.categoria_id IS NOT NULL AND NEW.categoria_id <> s.categoria_id THEN
            RAISE EXCEPTION 'La categoría no corresponde a la subcategoría' USING ERRCODE = 'KZ011';
        END IF;
        NEW.categoria_id := s.categoria_id;
    ELSIF NEW.categoria_id <> OLD.categoria_id THEN
        RAISE EXCEPTION 'Para cambiar la categoría, cambia la subcategoría' USING ERRCODE = 'KZ011';
    END IF;

    IF TG_OP = 'INSERT' OR NEW.subcategoria_id <> OLD.subcategoria_id OR NEW.unidad <> OLD.unidad THEN
        SELECT minimo, maximo INTO u FROM unidad_subcategoria
         WHERE subcategoria_id = NEW.subcategoria_id AND unidad = NEW.unidad;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'La unidad "%" no está permitida para esta subcategoría', NEW.unidad
                  USING ERRCODE = 'KZ016';
        END IF;
        IF TG_OP = 'INSERT' AND NEW.meta NOT BETWEEN u.minimo AND u.maximo THEN
            RAISE EXCEPTION 'La meta debe estar entre % y % %', u.minimo, u.maximo, NEW.unidad
                  USING ERRCODE = 'KZ011';
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_habito_a_subcategoria BEFORE INSERT OR UPDATE OF subcategoria_id, categoria_id, unidad ON habito
    FOR EACH ROW EXECUTE FUNCTION tg_habito_subcategoria();

-- =====================================================================
-- 4. Evaluación con evidencia
-- =====================================================================
CREATE FUNCTION fn_sesiones_semana(p_tipo text, p_dias smallint, p_veces smallint) RETURNS numeric
LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$
    SELECT CASE p_tipo
        WHEN 'diaria'      THEN 7
        WHEN 'dias_semana' THEN (SELECT count(*) FROM generate_series(0, 6) b WHERE (p_dias & (1 << b)) <> 0)
        ELSE p_veces
    END::numeric;
$$;

CREATE FUNCTION fn_redondear_paso(p_valor numeric, p_paso numeric, p_modo text DEFAULT 'cerca') RETURNS numeric
LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = kaizen, pg_temp
AS $$
    SELECT round(CASE p_modo WHEN 'abajo'  THEN floor(p_valor / p_paso)
                             WHEN 'arriba' THEN ceil(p_valor / p_paso)
                             ELSE round(p_valor / p_paso) END * p_paso, 2);
$$;

-- Evalúa una meta (sirve antes de crear el hábito y para los existentes).
-- Los rangos se devuelven en la unidad del hábito y por sesión (por día programado).
CREATE FUNCTION fn_evaluar_meta(p_subcategoria uuid, p_unidad text, p_meta numeric,
                                p_tipo text, p_dias smallint, p_veces smallint)
RETURNS TABLE (zona text, sentido text, volumen numeric, unidad_base text, periodo text,
               optimo_desde numeric, optimo_hasta numeric, maximo numeric, meta_sugerida numeric,
               paso numeric, piso numeric, referencia_id uuid, cita text, fuentes text, url text, confianza text, nota text)
LANGUAGE plpgsql STABLE
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    s  record;
    u  record;
    r  record;
    k  numeric;
BEGIN
    SELECT sc.sentido INTO s FROM subcategoria sc WHERE sc.id = p_subcategoria;
    SELECT us.factor_a_base, us.paso INTO u FROM unidad_subcategoria us
     WHERE us.subcategoria_id = p_subcategoria AND us.unidad = p_unidad;
    SELECT rc.* INTO r FROM referencia_cientifica rc WHERE rc.subcategoria_id = p_subcategoria;

    sentido := s.sentido;
    paso    := coalesce(u.paso, 0.01);
    IF r.id IS NULL OR u.factor_a_base IS NULL OR p_meta IS NULL THEN
        zona := 'sin_referencia';
        RETURN NEXT;
        RETURN;
    END IF;

    k := u.factor_a_base * CASE WHEN r.periodo = 'semana' THEN fn_sesiones_semana(p_tipo, p_dias, p_veces) ELSE 1 END;
    volumen       := round(p_meta * k, 2);
    unidad_base   := r.unidad_base;
    periodo       := r.periodo;
    optimo_desde  := round(r.optimo_desde / k, 2);
    optimo_hasta  := round(r.optimo_hasta / k, 2);
    maximo        := round(r.maximo / k, 2);
    piso          := fn_redondear_paso(r.piso_bajada / k, paso, 'arriba');
    referencia_id := r.id;
    cita := r.cita; fuentes := r.fuentes; url := r.url; confianza := r.confianza; nota := r.nota;

    IF s.sentido = 'aumentar' AND p_meta * k < r.optimo_desde THEN
        zona := 'bajo';
        meta_sugerida := fn_redondear_paso(r.optimo_desde / k, paso, 'arriba');          -- "hacia X"
    ELSIF p_meta * k <= r.optimo_hasta THEN
        zona := 'optimo';
    ELSIF r.maximo IS NULL OR p_meta * k <= r.maximo THEN
        zona := 'alto';
        IF s.sentido = 'reducir' THEN
            meta_sugerida := greatest(fn_redondear_paso(r.optimo_hasta / k, paso, 'abajo'), paso);
        END IF;
    ELSE
        zona := 'excesivo';
        meta_sugerida := greatest(fn_redondear_paso(r.maximo / k, paso, 'abajo'), paso);
    END IF;
    RETURN NEXT;
END;
$$;

CREATE VIEW v_habito_evidencia WITH (security_invoker = true, security_barrier) AS
SELECT h.region, h.id AS habito_id, h.usuario_id, e.*
  FROM habito h
 CROSS JOIN LATERAL fn_evaluar_meta(h.subcategoria_id, h.unidad, h.meta,
                                    h.frecuencia_tipo, h.dias_semana, h.veces_semana) e;
COMMENT ON VIEW v_habito_evidencia IS
    'Zona del hábito según la evidencia: bajo, optimo, alto, excesivo o sin_referencia (doc. 02 y 03).';

-- =====================================================================
-- 5. Escalera v2 (doc. 02)
-- =====================================================================
ALTER TABLE sugerencia_ajuste
    ADD COLUMN motivo text NOT NULL DEFAULT 'cumplimiento'
        CHECK (motivo IN ('cumplimiento', 'cumplimiento_alto', 'cumplimiento_bajo', 'excede_maximo')),
    ADD COLUMN referencia_id uuid REFERENCES referencia_cientifica (id) ON DELETE SET NULL,
    ALTER COLUMN cumplimiento_14d DROP NOT NULL;        -- excede_maximo se propone antes de tener 14 días
COMMENT ON COLUMN sugerencia_ajuste.motivo IS
    'cumplimiento: regla anterior al 27-nov · cumplimiento_alto/_bajo: 14 días ≥85 % / <50 % · excede_maximo: arriba del tope científico.';

CREATE OR REPLACE PROCEDURE sp_generar_sugerencias(
    p_region region_t DEFAULT NULL,
    p_hoy    date     DEFAULT current_date,
    INOUT p_creadas integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    c_umbral_subir CONSTANT numeric := 85;
    c_umbral_bajar CONSTANT numeric := 50;
    c_subir        CONSTANT numeric := 1.10;   -- convención (F07); el tope sí tiene respaldo (F08)
    c_tope         CONSTANT numeric := 1.30;   -- ≤ +30 % por paso (F08)
    c_bajar        CONSTANT numeric := 0.85;
    c_relajar      CONSTANT numeric := 1.15;   -- reducir: subir el límite cuando no se cumple
    c_espera       CONSTANT integer := 7;      -- días tras "Mantener"
    c              record;
    v_pct          numeric;
    v_tipo         text;
    v_prop         numeric;
    v_motivo       text;
    v_lim          numeric;
BEGIN
    p_creadas := 0;
    FOR c IN
        SELECT h.region, h.id, h.meta, n.vigente_desde, e.*
          FROM habito h
          JOIN nivel_habito n ON n.region = h.region AND n.habito_id = h.id AND n.vigente_hasta IS NULL
         CROSS JOIN LATERAL fn_evaluar_meta(h.subcategoria_id, h.unidad, h.meta,
                                            h.frecuencia_tipo, h.dias_semana, h.veces_semana) e
         WHERE h.activo AND h.escalera_activa
           AND (p_region IS NULL OR h.region = p_region)
           AND NOT EXISTS (SELECT 1 FROM sugerencia_ajuste s
                            WHERE s.region = h.region AND s.habito_id = h.id
                              AND (s.estado = 'pendiente'
                                   OR (s.estado = 'rechazada' AND s.resuelta_en >= p_hoy - c_espera)))
    LOOP
        v_tipo := NULL;
        v_pct  := fn_cumplimiento(c.region, c.id, 14, p_hoy - 1);

        IF c.sentido = 'aumentar' AND c.zona = 'excesivo' THEN
            -- Arriba del máximo: se propone bajar al tope sin esperar los 14 días
            v_tipo := 'bajar'; v_prop := c.meta_sugerida; v_motivo := 'excede_maximo';

        ELSIF c.vigente_desde <= p_hoy - 14 AND v_pct IS NOT NULL THEN
            IF c.sentido = 'aumentar' THEN
                IF v_pct >= c_umbral_subir AND c.zona IN ('bajo', 'sin_referencia') THEN
                    v_prop := fn_redondear_paso(c.meta * c_subir, c.paso);
                    v_lim  := fn_redondear_paso(c.meta * c_tope, c.paso, 'abajo');
                    v_prop := least(greatest(v_prop, c.meta + c.paso),             -- al menos un paso
                                    greatest(v_lim, c.meta + c.paso));             -- ≤ +30 % salvo un solo paso
                    IF c.zona = 'bajo' THEN                                        -- techo: el óptimo
                        v_prop := least(v_prop, fn_redondear_paso(c.optimo_hasta, c.paso, 'abajo'));
                    END IF;
                    IF v_prop > c.meta THEN v_tipo := 'subir'; v_motivo := 'cumplimiento_alto'; END IF;
                ELSIF v_pct < c_umbral_bajar THEN
                    v_prop := least(fn_redondear_paso(c.meta * c_bajar, c.paso), c.meta - c.paso);
                    v_prop := greatest(v_prop, c.paso, c.piso);                    -- algo es mejor que nada (F11),
                                                                                   -- salvo donde menos no se recomienda
                    IF v_prop < c.meta THEN v_tipo := 'bajar'; v_motivo := 'cumplimiento_bajo'; END IF;
                END IF;
            ELSE  -- reducir: la meta es un límite
                IF v_pct >= c_umbral_subir AND c.zona <> 'optimo' THEN
                    v_prop := least(fn_redondear_paso(c.meta * (2 - c_subir), c.paso), c.meta - c.paso);
                    IF c.optimo_hasta IS NOT NULL THEN
                        v_prop := greatest(v_prop, fn_redondear_paso(c.optimo_hasta, c.paso, 'arriba'));
                    END IF;
                    v_prop := greatest(v_prop, c.paso);
                    IF v_prop < c.meta THEN v_tipo := 'bajar'; v_motivo := 'cumplimiento_alto'; END IF;
                ELSIF v_pct < c_umbral_bajar THEN
                    v_prop := greatest(fn_redondear_paso(c.meta * c_relajar, c.paso), c.meta + c.paso);
                    IF c.maximo IS NOT NULL THEN
                        v_prop := least(v_prop, fn_redondear_paso(c.maximo, c.paso, 'abajo'));
                    END IF;
                    IF v_prop > c.meta THEN v_tipo := 'subir'; v_motivo := 'cumplimiento_bajo'; END IF;
                END IF;
            END IF;
        END IF;

        IF v_tipo IS NOT NULL AND v_prop > 0
           AND ((v_tipo = 'subir' AND v_prop > c.meta) OR (v_tipo = 'bajar' AND v_prop < c.meta)) THEN
            INSERT INTO sugerencia_ajuste (region, habito_id, tipo, meta_actual, meta_propuesta,
                                           cumplimiento_14d, motivo, referencia_id)
            VALUES (c.region, c.id, v_tipo, c.meta, v_prop, v_pct, v_motivo, c.referencia_id);
            p_creadas := p_creadas + 1;
        END IF;
    END LOOP;
END;
$$;

-- =====================================================================
-- 6. Protector de racha (doc. 01): 1 día programado fallado por semana ISO
-- no rompe la racha (ese día no suma); el segundo de la misma semana sí.
-- p_hasta permite contar como fallados los días sin registro hasta ayer.
-- =====================================================================
ALTER TABLE racha ADD COLUMN ultimo_protegido date;
COMMENT ON COLUMN racha.ultimo_protegido IS 'Último día fallado que el protector perdonó (1 por semana ISO).';

DROP FUNCTION fn_rachas(region_t, uuid, date);
CREATE FUNCTION fn_rachas(p_region region_t, p_habito uuid, p_desde date DEFAULT NULL, p_hasta date DEFAULT NULL,
                          OUT racha_actual integer, OUT racha_maxima integer, OUT ultima_fecha date,
                          OUT ultimo_protegido date)
LANGUAGE plpgsql STABLE
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    h          record;
    d          record;
    v_ini      date;
    v_fin      date;
    v_semana   date;                -- semana ISO en la que ya se usó el protector
BEGIN
    racha_actual := 0; racha_maxima := 0; ultima_fecha := NULL; ultimo_protegido := NULL;

    SELECT frecuencia_tipo, dias_semana INTO h
      FROM habito WHERE region = p_region AND id = p_habito;
    IF NOT FOUND THEN
        RETURN;
    END IF;

    SELECT min(fecha), max(fecha) INTO v_ini, v_fin
      FROM registro WHERE region = p_region AND habito_id = p_habito
       AND (p_desde IS NULL OR fecha >= p_desde);
    IF v_ini IS NULL THEN
        RETURN;
    END IF;
    v_fin := greatest(v_fin, p_hasta);

    FOR d IN
        SELECT s.dia::date AS dia, r.cumplido
          FROM generate_series(v_ini, v_fin, interval '1 day') AS s(dia)
          LEFT JOIN registro r
                 ON r.region = p_region AND r.habito_id = p_habito AND r.fecha = s.dia::date
         ORDER BY s.dia
    LOOP
        IF h.frecuencia_tipo = 'n_por_semana' THEN
            CONTINUE WHEN d.cumplido IS NULL;
        ELSIF NOT fn_dia_programado(h.frecuencia_tipo, h.dias_semana, d.dia) THEN
            CONTINUE;
        END IF;

        IF coalesce(d.cumplido, false) THEN
            racha_actual := racha_actual + 1;
            racha_maxima := greatest(racha_maxima, racha_actual);
            ultima_fecha := d.dia;
        ELSIF racha_actual > 0 AND v_semana IS DISTINCT FROM date_trunc('week', d.dia)::date THEN
            v_semana := date_trunc('week', d.dia)::date;          -- protector de esta semana
            ultimo_protegido := d.dia;
        ELSE
            racha_actual := 0;
        END IF;
    END LOOP;
END;
$$;
COMMENT ON FUNCTION fn_rachas(region_t, uuid, date, date) IS
    'Racha con protector (1 falla por semana ISO). Espejo en backend/src/kaizen/dominio/reglas/rachas.py.';

CREATE OR REPLACE FUNCTION tg_registro_racha() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    INSERT INTO racha AS ra (region, habito_id, racha_actual, racha_maxima, ultima_fecha, ultimo_protegido, actualizada_en)
    SELECT a.region, a.habito_id, c.racha_actual, c.racha_maxima, c.ultima_fecha, c.ultimo_protegido, now()
      FROM (SELECT DISTINCT region, habito_id FROM cambios) a
      JOIN habito h ON h.region = a.region AND h.id = a.habito_id
      CROSS JOIN LATERAL fn_rachas(a.region, a.habito_id) c
    ON CONFLICT (region, habito_id) DO UPDATE
       SET racha_actual     = EXCLUDED.racha_actual,
           racha_maxima     = EXCLUDED.racha_maxima,
           ultima_fecha     = EXCLUDED.ultima_fecha,
           ultimo_protegido = EXCLUDED.ultimo_protegido,
           actualizada_en   = EXCLUDED.actualizada_en;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_reconstruir_rachas(
    p_region region_t DEFAULT NULL,
    INOUT p_corregidas integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    WITH calc AS (
        SELECT h.region, h.id AS habito_id, c.*
          FROM habito h CROSS JOIN LATERAL fn_rachas(h.region, h.id) c
         WHERE p_region IS NULL OR h.region = p_region
    ), upd AS (
        INSERT INTO racha AS ra (region, habito_id, racha_actual, racha_maxima, ultima_fecha, ultimo_protegido)
        SELECT region, habito_id, racha_actual, racha_maxima, ultima_fecha, ultimo_protegido FROM calc
        ON CONFLICT (region, habito_id) DO UPDATE
           SET racha_actual = EXCLUDED.racha_actual,
               racha_maxima = EXCLUDED.racha_maxima,
               ultima_fecha = EXCLUDED.ultima_fecha,
               ultimo_protegido = EXCLUDED.ultimo_protegido,
               actualizada_en = now()
         WHERE (ra.racha_actual, ra.racha_maxima, ra.ultima_fecha, ra.ultimo_protegido)
               IS DISTINCT FROM (EXCLUDED.racha_actual, EXCLUDED.racha_maxima, EXCLUDED.ultima_fecha,
                                 EXCLUDED.ultimo_protegido)
        RETURNING 1
    )
    SELECT count(*) INTO p_corregidas FROM upd;
END;
$$;

-- Racha vigente: si ya pasó un día programado sin registro, se recalcula hasta
-- ayer para aplicar el protector (solo en ese caso, para no recorrer la historia).
CREATE OR REPLACE VIEW v_racha_vigente WITH (security_invoker = true, security_barrier) AS
SELECT r.region, r.habito_id, h.usuario_id,
       CASE WHEN x.al_dia THEN r.racha_actual ELSE f.racha_actual END AS racha_actual,
       r.racha_maxima,
       r.ultima_fecha,
       coalesce(CASE WHEN x.al_dia THEN r.ultimo_protegido ELSE f.ultimo_protegido END
                >= date_trunc('week', current_date)::date, false) AS protector_usado_semana
  FROM racha r
  JOIN habito h ON h.region = r.region AND h.id = r.habito_id
 CROSS JOIN LATERAL (SELECT h.frecuencia_tipo = 'n_por_semana' OR r.ultima_fecha IS NULL
                            OR r.ultima_fecha >= fn_dia_programado_anterior(h.frecuencia_tipo, h.dias_semana, current_date)
                            AS al_dia) x
  LEFT JOIN LATERAL (SELECT c.racha_actual, c.ultimo_protegido
                       FROM fn_rachas(r.region, r.habito_id, NULL, current_date - 1) c
                      WHERE NOT x.al_dia) f ON true;

-- =====================================================================
-- 7. Cápsulas 7/30/66
-- =====================================================================
DO $$
DECLARE v_nombre text;
BEGIN
    SELECT conname INTO v_nombre FROM pg_constraint
     WHERE conrelid = 'kaizen.capsula'::regclass AND contype = 'c'
       AND pg_get_constraintdef(oid) LIKE '%racha_objetivo%';
    EXECUTE format('ALTER TABLE capsula DROP CONSTRAINT %I', v_nombre);
END $$;
-- Las selladas con 21 (todas sintéticas) pasan a 30. La guardia T7 impide cambiar el
-- objetivo, así que se apaga solo para esta actualización.
ALTER TABLE capsula DISABLE TRIGGER trg_capsula_guardia;
UPDATE capsula SET racha_objetivo = 30 WHERE racha_objetivo = 21;
ALTER TABLE capsula ENABLE TRIGGER trg_capsula_guardia;
ALTER TABLE capsula ADD CONSTRAINT capsula_racha_objetivo_check CHECK (racha_objetivo IN (7, 30, 66));

-- =====================================================================
-- 8. Logros (doc. 05)
-- =====================================================================
CREATE TABLE logro (
    clave        text     PRIMARY KEY CHECK (clave ~ '^[a-z_0-9]{3,30}$'),
    nombre       text     NOT NULL CHECK (length(nombre) BETWEEN 3 AND 40),
    descripcion  text     NOT NULL CHECK (length(descripcion) BETWEEN 3 AND 160),
    icono        text     NOT NULL CHECK (icono ~ '^[a-z_0-9]{2,40}$'),
    tipo         text     NOT NULL CHECK (tipo IN ('racha', 'evento', 'semanal')),
    objetivo     integer  NOT NULL DEFAULT 1 CHECK (objetivo >= 1),
    porque       text     NOT NULL CHECK (length(porque) BETWEEN 3 AND 300),
    fuentes      text     CHECK (fuentes ~ '^F[0-9]{2}(, F[0-9]{2})*$'),
    orden        smallint NOT NULL DEFAULT 99,
    activo       boolean  NOT NULL DEFAULT true
);

INSERT INTO logro (clave, nombre, descripcion, icono, tipo, objetivo, porque, fuentes, orden) VALUES
 ('racha_7', 'Primera semana', 'Llega a 7 días seguidos en un hábito', 'local_fire_department', 'racha', 7,
  'El día 7 es el primer hito con datos de retención', 'F47', 1),
 ('racha_30', 'Un mes', 'Llega a 30 días seguidos en un hábito', 'whatshot', 'racha', 30,
  'Un mes de constancia; acerca a la mediana de formación', 'F01, F02', 2),
 ('habito_formado', 'Hábito formado', 'Llega a 66 días seguidos: la mediana científica para formar un hábito',
  'workspace_premium', 'racha', 66, 'Mediana de los estudios que midieron la formación de hábitos (no 21 días)', 'F01, F02', 3),
 ('racha_100', 'Centenario', 'Llega a 100 días seguidos en un hábito', 'military_tech', 'racha', 100,
  'Hito de calendario para celebrar una constancia larga', 'F47', 4),
 ('primer_micro_paso', 'Primer micro-paso', 'Acepta tu primera subida de la Escalera', 'stairs', 'evento', 1,
  'Mejorar poco a poco es la idea de Kaizen: metas retadoras pero alcanzables', 'F06', 5),
 ('ritmo_ideal', 'Ritmo ideal', 'Mantén un hábito 4 semanas dentro del rango que recomienda la evidencia', 'verified',
  'semanal', 1, 'Premia lo recomendado, no "más es mejor"', 'F11, F12', 6),
 ('semana_oms', 'Semana OMS', 'Junta 150 min de actividad moderada en una semana (o el equivalente vigoroso)',
  'directions_run', 'semanal', 1, 'Recomendación de la OMS para adultos', 'F11', 7),
 ('racha_salvada', 'Racha salvada', 'El protector cuidó tu racha después de un tropiezo', 'shield', 'evento', 1,
  'Fallar un día no echa a perder el hábito; reparar la racha reduce el abandono', 'F01, F09', 8),
 ('capsula_abierta', 'Cápsula abierta', 'Abre una Cápsula Kaizen', 'hourglass_bottom', 'evento', 1,
  'Recompensa personal por la constancia (F3)', NULL, 9),
 ('plan_si_entonces', 'Plan si-entonces', 'Escribe tu primera intención "Después de ___"', 'route', 'evento', 1,
  'Las intenciones de implementación tienen d = 0.65', 'F04', 10);

CREATE TABLE logro_usuario (
    region       region_t    NOT NULL,
    usuario_id   uuid        NOT NULL,
    logro_clave  text        NOT NULL REFERENCES logro (clave),
    habito_id    uuid,                                   -- hábito con el que se obtuvo (si aplica)
    obtenido_en  timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (region, usuario_id, logro_clave),       -- cada logro se obtiene una sola vez
    FOREIGN KEY (region, usuario_id) REFERENCES usuario (region, id) ON DELETE CASCADE
) PARTITION BY LIST (region);
CREATE TABLE logro_usuario_mx_norte      PARTITION OF logro_usuario FOR VALUES IN ('MX-NORTE');
CREATE TABLE logro_usuario_mx_centro_sur PARTITION OF logro_usuario FOR VALUES IN ('MX-CENTRO-SUR');
CREATE TABLE logro_usuario_latam         PARTITION OF logro_usuario FOR VALUES IN ('LATAM');

CREATE FUNCTION fn_otorgar_logro(p_region region_t, p_usuario uuid, p_clave text, p_habito uuid DEFAULT NULL)
RETURNS void
LANGUAGE sql VOLATILE
SET search_path = kaizen, pg_temp
AS $$
    INSERT INTO logro_usuario (region, usuario_id, logro_clave, habito_id)
    SELECT p_region, p_usuario, p_clave, p_habito FROM logro WHERE clave = p_clave AND activo
    ON CONFLICT DO NOTHING;
$$;

CREATE FUNCTION tg_racha_logros() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_usuario uuid;
    l         record;
BEGIN
    IF TG_OP = 'UPDATE' AND NEW.racha_maxima <= OLD.racha_maxima
       AND NEW.ultimo_protegido IS NOT DISTINCT FROM OLD.ultimo_protegido THEN
        RETURN NULL;
    END IF;
    SELECT usuario_id INTO v_usuario FROM habito WHERE region = NEW.region AND id = NEW.habito_id;
    IF NOT FOUND THEN
        RETURN NULL;
    END IF;
    FOR l IN SELECT clave FROM logro WHERE tipo = 'racha' AND activo AND objetivo <= NEW.racha_maxima LOOP
        PERFORM fn_otorgar_logro(NEW.region, v_usuario, l.clave, NEW.habito_id);
    END LOOP;
    IF NEW.ultimo_protegido IS NOT NULL AND NEW.racha_actual > 0
       AND (TG_OP = 'INSERT' OR NEW.ultimo_protegido IS DISTINCT FROM OLD.ultimo_protegido) THEN
        PERFORM fn_otorgar_logro(NEW.region, v_usuario, 'racha_salvada', NEW.habito_id);
    END IF;
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_racha_logros AFTER INSERT OR UPDATE ON racha
    FOR EACH ROW EXECUTE FUNCTION tg_racha_logros();

CREATE FUNCTION tg_sugerencia_logro() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    PERFORM fn_otorgar_logro(NEW.region, h.usuario_id, 'primer_micro_paso', NEW.habito_id)
       FROM habito h WHERE h.region = NEW.region AND h.id = NEW.habito_id;
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_sugerencia_logro AFTER UPDATE OF estado ON sugerencia_ajuste
    FOR EACH ROW WHEN (OLD.estado = 'pendiente' AND NEW.estado = 'aceptada' AND NEW.tipo = 'subir')
    EXECUTE FUNCTION tg_sugerencia_logro();

CREATE FUNCTION tg_capsula_logro() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    PERFORM fn_otorgar_logro(NEW.region, NEW.usuario_id, 'capsula_abierta', NEW.habito_id);
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_capsula_logro AFTER UPDATE OF estado ON capsula
    FOR EACH ROW WHEN (OLD.estado = 'sellada' AND NEW.estado = 'abierta')
    EXECUTE FUNCTION tg_capsula_logro();

CREATE FUNCTION tg_habito_logro_intencion() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
BEGIN
    PERFORM fn_otorgar_logro(NEW.region, NEW.usuario_id, 'plan_si_entonces', NEW.id);
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_habito_logro_intencion_ins AFTER INSERT ON habito
    FOR EACH ROW WHEN (NEW.intencion IS NOT NULL) EXECUTE FUNCTION tg_habito_logro_intencion();
CREATE TRIGGER trg_habito_logro_intencion_upd AFTER UPDATE OF intencion ON habito
    FOR EACH ROW WHEN (NEW.intencion IS NOT NULL AND OLD.intencion IS NULL) EXECUTE FUNCTION tg_habito_logro_intencion();

-- Logros semanales: corre los lunes (kaizen_tareas) sobre la semana ISO anterior
CREATE PROCEDURE sp_otorgar_logros_semanales(
    p_hoy date DEFAULT current_date,
    INOUT p_otorgados integer DEFAULT 0)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_lunes   date := date_trunc('week', p_hoy)::date - 7;
    v_domingo date := date_trunc('week', p_hoy)::date - 1;
    v_antes   integer;
BEGIN
    SELECT count(*) INTO v_antes FROM logro_usuario;

    -- Semana OMS: 150 min moderados (1 min vigoroso = 2 moderados, OMS 2020)
    PERFORM fn_otorgar_logro(t.region, t.usuario_id, 'semana_oms', NULL)
       FROM (SELECT h.region, h.usuario_id
               FROM registro r
               JOIN habito h ON h.region = r.region AND h.id = r.habito_id
               JOIN subcategoria s ON s.id = h.subcategoria_id AND s.clave IN ('aerobico_moderado', 'vigoroso')
               JOIN unidad_subcategoria u ON u.subcategoria_id = h.subcategoria_id AND u.unidad = h.unidad
              WHERE r.cumplido AND r.fecha BETWEEN v_lunes AND v_domingo AND u.factor_a_base IS NOT NULL
              GROUP BY h.region, h.usuario_id
             HAVING sum(coalesce(r.valor, h.meta) * u.factor_a_base
                        * CASE s.clave WHEN 'vigoroso' THEN 2 ELSE 1 END) >= 150) t;

    -- Ritmo ideal: meta en el óptimo, sin cambio de nivel y ≥ 85 % de cumplimiento en 4 semanas
    PERFORM fn_otorgar_logro(h.region, h.usuario_id, 'ritmo_ideal', h.id)
       FROM habito h
       JOIN nivel_habito n ON n.region = h.region AND n.habito_id = h.id AND n.vigente_hasta IS NULL
      CROSS JOIN LATERAL fn_evaluar_meta(h.subcategoria_id, h.unidad, h.meta,
                                         h.frecuencia_tipo, h.dias_semana, h.veces_semana) e
      WHERE h.activo AND e.zona = 'optimo' AND n.vigente_desde <= v_domingo - 27
        AND fn_cumplimiento(h.region, h.id, 28, v_domingo) >= 85;

    SELECT count(*) - v_antes INTO p_otorgados FROM logro_usuario;
    PERFORM fn_auditar(NULL, NULL, 'tareas.logros', p_otorgados || ' logros', 'exito');
END;
$$;

-- Logros del usuario actual con su progreso (la API la llama; respeta la RLS)
CREATE FUNCTION fn_logros_usuario(p_region region_t, p_usuario uuid)
RETURNS TABLE (clave text, nombre text, descripcion text, icono text, tipo text, objetivo integer,
               porque text, fuentes text, obtenido boolean, obtenido_en timestamptz, habito_id uuid,
               progreso integer)
LANGUAGE sql STABLE
SET search_path = kaizen, pg_temp
AS $$
    SELECT l.clave, l.nombre, l.descripcion, l.icono, l.tipo, l.objetivo, l.porque, l.fuentes,
           lu.logro_clave IS NOT NULL, lu.obtenido_en, lu.habito_id,
           CASE WHEN lu.logro_clave IS NOT NULL THEN l.objetivo
                WHEN l.tipo = 'racha' THEN least(l.objetivo,
                     coalesce((SELECT max(r.racha_maxima) FROM racha r
                                 JOIN habito h ON h.region = r.region AND h.id = r.habito_id
                                WHERE r.region = p_region AND h.usuario_id = p_usuario), 0))
                ELSE 0 END
      FROM logro l
      LEFT JOIN logro_usuario lu ON lu.region = p_region AND lu.usuario_id = p_usuario
                                AND lu.logro_clave = l.clave
     WHERE l.activo
     ORDER BY l.orden;
$$;

-- Las rachas guardadas se recalculan con el protector; después, los hábitos que ya
-- tenían rachas reciben sus logros
CALL sp_reconstruir_rachas(NULL, NULL);
INSERT INTO logro_usuario (region, usuario_id, logro_clave, habito_id, obtenido_en)
SELECT DISTINCT ON (h.region, h.usuario_id, l.clave) h.region, h.usuario_id, l.clave, h.id, now()
  FROM racha r
  JOIN habito h ON h.region = r.region AND h.id = r.habito_id
  JOIN logro l ON l.tipo = 'racha' AND l.objetivo <= r.racha_maxima
 ORDER BY h.region, h.usuario_id, l.clave, r.racha_maxima DESC
ON CONFLICT DO NOTHING;

-- =====================================================================
-- 9. Administración del catálogo (subcategorías y referencias)
-- =====================================================================
CREATE PROCEDURE sp_admin_crear_subcategoria(
    p_admin      uuid,
    p_categoria  uuid,
    p_nombre     text,
    p_sentido    text,
    p_unidades   text[],
    p_ip         inet DEFAULT NULL,
    INOUT p_id   uuid DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
    v_cat text;
    v_u   text;
BEGIN
    IF p_nombre IS NULL OR length(btrim(p_nombre)) NOT BETWEEN 2 AND 40 THEN
        RAISE EXCEPTION 'El nombre debe tener de 2 a 40 caracteres' USING ERRCODE = 'KZ011';
    END IF;
    IF p_sentido NOT IN ('aumentar', 'reducir') OR coalesce(cardinality(p_unidades), 0) = 0 THEN
        RAISE EXCEPTION 'Sentido (aumentar/reducir) y al menos una unidad son obligatorios' USING ERRCODE = 'KZ011';
    END IF;
    SELECT clave INTO v_cat FROM categoria WHERE id = p_categoria;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Categoría no encontrada' USING ERRCODE = 'KZ004';
    END IF;
    BEGIN
        INSERT INTO subcategoria (categoria_id, clave, nombre, icono, sentido)
        VALUES (p_categoria, left(fn_clave(p_nombre), 40), btrim(p_nombre), 'category', p_sentido)
        RETURNING id INTO p_id;
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una subcategoría con ese nombre' USING ERRCODE = 'KZ013';
    END;
    FOREACH v_u IN ARRAY p_unidades LOOP
        IF length(btrim(v_u)) NOT BETWEEN 1 AND 20 THEN
            RAISE EXCEPTION 'Unidad inválida: %', v_u USING ERRCODE = 'KZ011';
        END IF;
        INSERT INTO unidad_subcategoria (subcategoria_id, unidad, factor_a_base, paso, minimo, maximo)
        VALUES (p_id, btrim(v_u), NULL, 1, 1, 1000000) ON CONFLICT DO NOTHING;
    END LOOP;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.subcategoria_crear', 'subcategoria/' || p_id, 'exito', p_ip);
END;
$$;

CREATE PROCEDURE sp_admin_actualizar_subcategoria(
    p_admin   uuid,
    p_id      uuid,
    p_nombre  text    DEFAULT NULL,
    p_activa  boolean DEFAULT NULL,
    p_ip      inet    DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
BEGIN
    IF p_nombre IS NOT NULL AND length(btrim(p_nombre)) NOT BETWEEN 2 AND 40 THEN
        RAISE EXCEPTION 'El nombre debe tener de 2 a 40 caracteres' USING ERRCODE = 'KZ011';
    END IF;
    BEGIN
        UPDATE subcategoria SET nombre = coalesce(btrim(p_nombre), nombre), activa = coalesce(p_activa, activa)
         WHERE id = p_id;
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una subcategoría con ese nombre' USING ERRCODE = 'KZ013';
    END;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Subcategoría no encontrada' USING ERRCODE = 'KZ004';
    END IF;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.subcategoria_editar', 'subcategoria/' || p_id, 'exito', p_ip);
END;
$$;

-- Alta o cambio de la referencia de una subcategoría (exige cita y fuente)
CREATE PROCEDURE sp_admin_guardar_referencia(
    p_admin         uuid,
    p_subcategoria  uuid,
    p_periodo       text,
    p_unidad_base   text,
    p_optimo_desde  numeric,
    p_optimo_hasta  numeric,
    p_maximo        numeric,
    p_cita          text,
    p_fuentes       text,
    p_url           text,
    p_confianza     text,
    p_nota          text DEFAULT NULL,
    p_ip            inet DEFAULT NULL,
    p_piso          numeric DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
BEGIN
    IF NOT EXISTS (SELECT 1 FROM unidad_subcategoria
                    WHERE subcategoria_id = p_subcategoria AND unidad = p_unidad_base AND factor_a_base = 1) THEN
        RAISE EXCEPTION 'La unidad base debe ser una unidad de la subcategoría con factor 1' USING ERRCODE = 'KZ011';
    END IF;
    BEGIN
        INSERT INTO referencia_cientifica (subcategoria_id, periodo, unidad_base, optimo_desde, optimo_hasta, maximo,
                                           piso_bajada, cita, fuentes, url, confianza, nota)
        VALUES (p_subcategoria, p_periodo, p_unidad_base, p_optimo_desde, p_optimo_hasta, p_maximo,
                p_piso, p_cita, p_fuentes, p_url, p_confianza, p_nota)
        ON CONFLICT (subcategoria_id) DO UPDATE
           SET periodo = EXCLUDED.periodo, unidad_base = EXCLUDED.unidad_base,
               optimo_desde = EXCLUDED.optimo_desde, optimo_hasta = EXCLUDED.optimo_hasta,
               maximo = EXCLUDED.maximo, piso_bajada = EXCLUDED.piso_bajada, cita = EXCLUDED.cita, fuentes = EXCLUDED.fuentes, url = EXCLUDED.url,
               confianza = EXCLUDED.confianza, nota = EXCLUDED.nota, actualizada_en = now();
    EXCEPTION WHEN check_violation THEN
        RAISE EXCEPTION 'Referencia inválida (rangos, cita, fuentes F##, url https o confianza)' USING ERRCODE = 'KZ011';
    END;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.referencia_guardar', 'subcategoria/' || p_subcategoria,
                       'exito', p_ip);
END;
$$;

-- Una categoría creada por el admin necesita clave (las subcategorías se agregan aparte)
CREATE OR REPLACE PROCEDURE sp_admin_crear_categoria(
    p_admin   uuid,
    p_nombre  text,
    p_ip      inet DEFAULT NULL,
    INOUT p_id uuid DEFAULT NULL)
LANGUAGE plpgsql SECURITY DEFINER
SET search_path = kaizen, pg_temp
AS $$
DECLARE
    v_region_admin region_t := fn_verificar_admin(p_admin);
BEGIN
    IF p_nombre IS NULL OR length(btrim(p_nombre)) NOT BETWEEN 2 AND 40 THEN
        RAISE EXCEPTION 'El nombre debe tener de 2 a 40 caracteres' USING ERRCODE = 'KZ011';
    END IF;
    BEGIN
        INSERT INTO categoria (nombre, clave) VALUES (btrim(p_nombre), left(fn_clave(p_nombre), 40)) RETURNING id INTO p_id;
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Ya existe una categoría con ese nombre' USING ERRCODE = 'KZ013';
    END;
    PERFORM fn_auditar(p_admin, v_region_admin, 'admin.categoria_crear', 'categoria/' || p_id, 'exito', p_ip);
END;
$$;

-- Métricas por categoría: se agrega la clave al final (las columnas anteriores no cambian)
CREATE OR REPLACE VIEW v_metricas_region AS
SELECT h.region, c.nombre AS categoria,
       count(DISTINCT h.usuario_id)                        AS usuarios,
       count(*)                                            AS habitos,
       round(avg(r.racha_actual), 2)                       AS racha_promedio,
       c.clave                                             AS categoria_clave
  FROM habito h
  JOIN categoria c ON c.id = h.categoria_id
  JOIN racha r     ON r.region = h.region AND r.habito_id = h.id
 WHERE h.activo
 GROUP BY h.region, c.nombre, c.clave
HAVING count(DISTINCT h.usuario_id) >= 5;

-- =====================================================================
-- 10. Seguridad: RLS y permisos
-- =====================================================================
ALTER TABLE logro_usuario ENABLE ROW LEVEL SECURITY;
CREATE POLICY pol_dueno ON logro_usuario TO kaizen_api
    USING (usuario_id = fn_usuario_actual()) WITH CHECK (usuario_id = fn_usuario_actual());
CREATE POLICY pol_lectura_global ON logro_usuario FOR SELECT TO kaizen_etl, kaizen_admin USING (true);

REVOKE ALL ON FUNCTION fn_clave(text), fn_sesiones_semana(text, smallint, smallint),
                       fn_redondear_paso(numeric, numeric, text),
                       fn_evaluar_meta(uuid, text, numeric, text, smallint, smallint),
                       fn_rachas(region_t, uuid, date, date),
                       fn_otorgar_logro(region_t, uuid, text, uuid), fn_logros_usuario(region_t, uuid),
                       tg_habito_subcategoria(), tg_racha_logros(), tg_sugerencia_logro(), tg_capsula_logro(),
                       tg_habito_logro_intencion() FROM PUBLIC;
REVOKE ALL ON PROCEDURE sp_otorgar_logros_semanales, sp_admin_crear_subcategoria, sp_admin_actualizar_subcategoria,
                        sp_admin_guardar_referencia FROM PUBLIC;

-- kaizen_api
GRANT SELECT ON subcategoria, unidad_subcategoria, referencia_cientifica, logro, logro_usuario,
                v_habito_evidencia TO kaizen_api;
GRANT INSERT (subcategoria_id, prioridad, intencion), UPDATE (subcategoria_id, prioridad, intencion)
      ON habito TO kaizen_api;
GRANT EXECUTE ON FUNCTION fn_rachas(region_t, uuid, date, date), fn_sesiones_semana(text, smallint, smallint),
                          fn_redondear_paso(numeric, numeric, text),
                          fn_evaluar_meta(uuid, text, numeric, text, smallint, smallint),
                          fn_logros_usuario(region_t, uuid) TO kaizen_api;
GRANT EXECUTE ON PROCEDURE sp_admin_crear_subcategoria, sp_admin_actualizar_subcategoria,
                           sp_admin_guardar_referencia TO kaizen_api;

-- kaizen_etl (solo lectura)
GRANT SELECT ON subcategoria, unidad_subcategoria, referencia_cientifica, logro, logro_usuario,
                v_habito_evidencia TO kaizen_etl;
GRANT EXECUTE ON FUNCTION fn_rachas(region_t, uuid, date, date), fn_sesiones_semana(text, smallint, smallint),
                          fn_redondear_paso(numeric, numeric, text),
                          fn_evaluar_meta(uuid, text, numeric, text, smallint, smallint) TO kaizen_etl;

-- kaizen_admin (personas) y kaizen_tareas (tareas programadas)
GRANT SELECT ON subcategoria, unidad_subcategoria, referencia_cientifica, logro, logro_usuario,
                v_habito_evidencia TO kaizen_admin;
GRANT EXECUTE ON FUNCTION fn_rachas(region_t, uuid, date, date),
                          fn_evaluar_meta(uuid, text, numeric, text, smallint, smallint) TO kaizen_admin;
GRANT EXECUTE ON PROCEDURE sp_otorgar_logros_semanales TO kaizen_tareas, kaizen_admin;

COMMIT;
