-- =====================================================================
-- Kaizen · 01_esquema.sql
-- Esquema relacional fragmentado por región (PostgreSQL 16+).
-- Ejecutar como el rol dueño (kaizen_owner) sobre la base "kaizen".
-- IA: asistido (ver bitácora de IA). Revisión: Jael Contreras.
-- =====================================================================
BEGIN;

CREATE SCHEMA IF NOT EXISTS kaizen;
SET search_path = kaizen, pg_temp;

-- ---------------------------------------------------------------------
-- Dominios: una regla, un solo lugar.
-- ---------------------------------------------------------------------
CREATE DOMAIN region_t AS text
    CHECK (VALUE IN ('MX-NORTE', 'MX-CENTRO-SUR', 'LATAM'));

CREATE DOMAIN escala_1_5 AS smallint
    CHECK (VALUE BETWEEN 1 AND 5);

CREATE DOMAIN hmac_hex AS text
    CHECK (VALUE ~ '^[0-9a-f]{64}$');          -- HMAC-SHA256 en hexadecimal

-- ---------------------------------------------------------------------
-- Catálogo común (sin particionar)
-- ---------------------------------------------------------------------
CREATE TABLE categoria (
    id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    nombre  text NOT NULL UNIQUE CHECK (length(nombre) BETWEEN 2 AND 40),
    activa  boolean NOT NULL DEFAULT true
);

-- ---------------------------------------------------------------------
-- usuario: fragmento primario (shard key = region)
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id                        uuid        NOT NULL DEFAULT gen_random_uuid(),
    region                    region_t    NOT NULL,
    nombre                    text        NOT NULL CHECK (length(nombre) BETWEEN 1 AND 80),
    email                     text        NOT NULL CHECK (email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
    password_hash             text        NOT NULL CHECK (password_hash LIKE '$argon2id$%'),
    pais                      char(2)     NOT NULL CHECK (pais ~ '^[A-Z]{2}$'),
    rol                       text        NOT NULL DEFAULT 'usuario' CHECK (rol IN ('usuario', 'admin')),
    fecha_registro            timestamptz NOT NULL DEFAULT now(),
    acepto_aviso_en           timestamptz NOT NULL,
    consentimiento_senales_en timestamptz,
    intentos_fallidos         smallint    NOT NULL DEFAULT 0 CHECK (intentos_fallidos >= 0),
    bloqueado_hasta           timestamptz,
    PRIMARY KEY (region, id)
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- Directorio de fragmentos (sin particionar): correo -> (usuario, región)
-- ---------------------------------------------------------------------
CREATE TABLE directorio_usuarios (
    email_hmac  hmac_hex PRIMARY KEY,
    usuario_id  uuid     NOT NULL UNIQUE,
    region      region_t NOT NULL,
    FOREIGN KEY (region, usuario_id) REFERENCES usuario (region, id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- habito
-- ---------------------------------------------------------------------
CREATE TABLE habito (
    id               uuid          NOT NULL DEFAULT gen_random_uuid(),
    region           region_t      NOT NULL,
    usuario_id       uuid          NOT NULL,
    categoria_id     uuid          NOT NULL REFERENCES categoria (id),
    nombre           text          NOT NULL CHECK (length(nombre) BETWEEN 1 AND 60),
    frecuencia_tipo  text          NOT NULL CHECK (frecuencia_tipo IN ('diaria', 'dias_semana', 'n_por_semana')),
    dias_semana      smallint      CHECK (dias_semana BETWEEN 1 AND 127),   -- bit 0 = lunes ... bit 6 = domingo
    veces_semana     smallint      CHECK (veces_semana BETWEEN 1 AND 7),
    meta             numeric(10,2) NOT NULL CHECK (meta > 0),
    unidad           text          NOT NULL CHECK (length(unidad) BETWEEN 1 AND 20),
    fecha_creacion   timestamptz   NOT NULL DEFAULT now(),
    activo           boolean       NOT NULL DEFAULT true,
    PRIMARY KEY (region, id),
    UNIQUE (region, id, usuario_id),            -- destino de FKs que verifican al dueño
    FOREIGN KEY (region, usuario_id) REFERENCES usuario (region, id) ON DELETE CASCADE,
    CONSTRAINT frecuencia_coherente CHECK (
           (frecuencia_tipo = 'diaria'       AND dias_semana IS NULL     AND veces_semana IS NULL)
        OR (frecuencia_tipo = 'dias_semana'  AND dias_semana IS NOT NULL AND veces_semana IS NULL)
        OR (frecuencia_tipo = 'n_por_semana' AND dias_semana IS NULL     AND veces_semana IS NOT NULL))
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- registro (check-in). El id lo genera el cliente: reenvío idempotente.
-- ---------------------------------------------------------------------
CREATE TABLE registro (
    id             uuid          NOT NULL,
    region         region_t      NOT NULL,
    habito_id      uuid          NOT NULL,
    usuario_id     uuid          NOT NULL,
    fecha          date          NOT NULL,
    cumplido       boolean       NOT NULL,
    valor          numeric(10,2) CHECK (valor >= 0),
    origen         text          NOT NULL CHECK (origen IN ('manual', 'rapido', 'offline')),
    registrado_en  timestamptz   NOT NULL DEFAULT now(),
    PRIMARY KEY (region, id),
    UNIQUE (region, habito_id, fecha),
    -- la FK compuesta garantiza que usuario_id sea el dueño real del hábito
    FOREIGN KEY (region, habito_id, usuario_id)
        REFERENCES habito (region, id, usuario_id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- racha (dato derivado de registro, mantenido por trigger)
-- ---------------------------------------------------------------------
CREATE TABLE racha (
    region         region_t    NOT NULL,
    habito_id      uuid        NOT NULL,
    racha_actual   integer     NOT NULL DEFAULT 0 CHECK (racha_actual >= 0),
    racha_maxima   integer     NOT NULL DEFAULT 0,
    ultima_fecha   date,
    actualizada_en timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (region, habito_id),
    CHECK (racha_maxima >= racha_actual),
    FOREIGN KEY (region, habito_id) REFERENCES habito (region, id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- nivel_habito (F1: escalones de la Escalera). Intervalo [desde, hasta).
-- ---------------------------------------------------------------------
CREATE TABLE nivel_habito (
    id             uuid          NOT NULL DEFAULT gen_random_uuid(),
    region         region_t      NOT NULL,
    habito_id      uuid          NOT NULL,
    nivel          integer       NOT NULL CHECK (nivel >= 1),
    meta_valor     numeric(10,2) NOT NULL CHECK (meta_valor > 0),
    vigente_desde  date          NOT NULL DEFAULT current_date,
    vigente_hasta  date,
    PRIMARY KEY (region, id),
    CHECK (vigente_hasta IS NULL OR vigente_hasta >= vigente_desde),
    FOREIGN KEY (region, habito_id) REFERENCES habito (region, id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- sugerencia_ajuste (F1)
-- ---------------------------------------------------------------------
CREATE TABLE sugerencia_ajuste (
    id                uuid          NOT NULL DEFAULT gen_random_uuid(),
    region            region_t      NOT NULL,
    habito_id         uuid          NOT NULL,
    tipo              text          NOT NULL CHECK (tipo IN ('subir', 'bajar')),
    meta_actual       numeric(10,2) NOT NULL CHECK (meta_actual > 0),
    meta_propuesta    numeric(10,2) NOT NULL CHECK (meta_propuesta > 0),
    cumplimiento_14d  numeric(5,2)  NOT NULL CHECK (cumplimiento_14d BETWEEN 0 AND 100),
    estado            text          NOT NULL DEFAULT 'pendiente'
                                    CHECK (estado IN ('pendiente', 'aceptada', 'rechazada', 'expirada')),
    creada_en         timestamptz   NOT NULL DEFAULT now(),
    resuelta_en       timestamptz,
    PRIMARY KEY (region, id),
    CHECK ((estado = 'pendiente') = (resuelta_en IS NULL)),
    CHECK ((tipo = 'subir' AND meta_propuesta > meta_actual)
        OR (tipo = 'bajar' AND meta_propuesta < meta_actual)),
    FOREIGN KEY (region, habito_id) REFERENCES habito (region, id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- senal_diaria (F2). Requiere consentimiento expreso (trigger).
-- ---------------------------------------------------------------------
CREATE TABLE senal_diaria (
    id          uuid       NOT NULL DEFAULT gen_random_uuid(),
    region      region_t   NOT NULL,
    usuario_id  uuid       NOT NULL,
    fecha       date       NOT NULL,
    animo       escala_1_5 NOT NULL,
    energia     escala_1_5 NOT NULL,
    PRIMARY KEY (region, id),
    UNIQUE (region, usuario_id, fecha),
    FOREIGN KEY (region, usuario_id) REFERENCES usuario (region, id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- capsula (F3). mensaje_cifrado = nonce(12) || texto cifrado || tag(16)
-- ---------------------------------------------------------------------
CREATE TABLE capsula (
    id               uuid        NOT NULL DEFAULT gen_random_uuid(),
    region           region_t    NOT NULL,
    habito_id        uuid        NOT NULL,
    usuario_id       uuid        NOT NULL,
    mensaje_cifrado  bytea       NOT NULL CHECK (octet_length(mensaje_cifrado) BETWEEN 29 AND 4124),
    llave_version    smallint    NOT NULL DEFAULT 1 CHECK (llave_version >= 1),
    tiene_foto       boolean     NOT NULL DEFAULT false,
    racha_objetivo   integer     NOT NULL CHECK (racha_objetivo IN (7, 21, 66)),
    estado           text        NOT NULL DEFAULT 'sellada' CHECK (estado IN ('sellada', 'abierta')),
    creada_en        timestamptz NOT NULL DEFAULT now(),
    abierta_en       timestamptz,
    PRIMARY KEY (region, id),
    CHECK ((estado = 'abierta') = (abierta_en IS NOT NULL)),
    FOREIGN KEY (region, habito_id, usuario_id)
        REFERENCES habito (region, id, usuario_id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- sesion: tokens de renovación (refresh) con rotación y revocación
-- ---------------------------------------------------------------------
CREATE TABLE sesion (
    jti              uuid        NOT NULL,
    region           region_t    NOT NULL,
    usuario_id       uuid        NOT NULL,
    familia          uuid        NOT NULL,       -- detecta reuso de un token ya rotado
    emitida_en       timestamptz NOT NULL DEFAULT now(),
    expira_en        timestamptz NOT NULL,
    revocada_en      timestamptz,
    reemplazada_por  uuid,
    PRIMARY KEY (region, jti),
    CHECK (expira_en > emitida_en),
    FOREIGN KEY (region, usuario_id) REFERENCES usuario (region, id) ON DELETE CASCADE
) PARTITION BY LIST (region);

-- ---------------------------------------------------------------------
-- bitacora_auditoria: particionada por TIEMPO (cambio respecto a la
-- entrega 1). Sin FK a usuario: la bitácora debe sobrevivir a la
-- cancelación de la cuenta (ARCO) y registrar intentos sin usuario.
-- ---------------------------------------------------------------------
CREATE TABLE bitacora_auditoria (
    id          bigint      GENERATED ALWAYS AS IDENTITY,
    fecha       timestamptz NOT NULL DEFAULT now(),
    usuario_id  uuid,
    region      region_t,
    accion      text        NOT NULL CHECK (accion ~ '^[a-z_.]{3,40}$'),
    recurso     text        CHECK (length(recurso) <= 120),
    resultado   text        NOT NULL CHECK (resultado IN ('exito', 'fallo', 'denegado')),
    ip          inet,
    PRIMARY KEY (fecha, id)
) PARTITION BY RANGE (fecha);

-- ---------------------------------------------------------------------
-- Particiones por región (fragmentación horizontal primaria y derivada)
-- ---------------------------------------------------------------------
DO $$
DECLARE
    t text;
    r record;
BEGIN
    FOREACH t IN ARRAY ARRAY['usuario', 'habito', 'registro', 'racha', 'nivel_habito',
                             'sugerencia_ajuste', 'senal_diaria', 'capsula', 'sesion']
    LOOP
        FOR r IN SELECT * FROM (VALUES ('MX-NORTE', 'mx_norte'),
                                       ('MX-CENTRO-SUR', 'mx_centro_sur'),
                                       ('LATAM', 'latam')) AS v(region, sufijo)
        LOOP
            EXECUTE format('CREATE TABLE %I PARTITION OF %I FOR VALUES IN (%L)',
                           t || '_' || r.sufijo, t, r.region);
        END LOOP;
    END LOOP;
END $$;

-- Bitácora: una partición por mes + DEFAULT como red de seguridad.
-- Las siguientes las crea sp_crear_particion_bitacora (04_procedimientos.sql).
DO $$
DECLARE
    mes date;
BEGIN
    FOR mes IN SELECT generate_series(date '2026-11-01', date '2027-06-01', interval '1 month')::date
    LOOP
        EXECUTE format('CREATE TABLE %I PARTITION OF bitacora_auditoria FOR VALUES FROM (%L) TO (%L)',
                       'bitacora_' || to_char(mes, 'YYYY_MM'), mes, (mes + interval '1 month')::date);
    END LOOP;
END $$;
CREATE TABLE bitacora_default PARTITION OF bitacora_auditoria DEFAULT;

-- ---------------------------------------------------------------------
-- Índices (cada uno responde a un patrón de acceso del punto 1.3)
-- ---------------------------------------------------------------------
CREATE INDEX ix_habito_usuario        ON habito (region, usuario_id) WHERE activo;
CREATE INDEX ix_habito_categoria      ON habito (categoria_id);
CREATE INDEX ix_registro_usuario_fecha ON registro (region, usuario_id, fecha DESC);
-- (region, habito_id, fecha) ya lo cubre la restricción UNIQUE
CREATE INDEX ix_registro_registrado_brin ON registro USING brin (registrado_en);  -- extracción incremental (ETL)
CREATE UNIQUE INDEX ux_nivel_vigente  ON nivel_habito (region, habito_id) WHERE vigente_hasta IS NULL;
CREATE INDEX ix_nivel_habito          ON nivel_habito (region, habito_id, vigente_desde DESC);
CREATE UNIQUE INDEX ux_sugerencia_pendiente ON sugerencia_ajuste (region, habito_id) WHERE estado = 'pendiente';
CREATE INDEX ix_capsula_habito        ON capsula (region, habito_id) WHERE estado = 'sellada';
CREATE INDEX ix_sesion_usuario        ON sesion (region, usuario_id) WHERE revocada_en IS NULL;
CREATE INDEX ix_sesion_familia        ON sesion (region, familia);
CREATE INDEX ix_bitacora_usuario      ON bitacora_auditoria (usuario_id, fecha DESC) WHERE usuario_id IS NOT NULL;
CREATE INDEX ix_bitacora_fallos       ON bitacora_auditoria (accion, fecha DESC) WHERE resultado <> 'exito';

COMMENT ON TABLE directorio_usuarios IS 'Directorio de fragmentos: HMAC del correo -> usuario y región (partición).';
COMMENT ON TABLE racha IS 'Dato derivado de registro. Lo mantiene trg_registro_racha_*; reconstruible con sp_reconstruir_rachas.';
COMMENT ON COLUMN habito.dias_semana IS 'Máscara de bits: 1=lun, 2=mar, 4=mié, 8=jue, 16=vie, 32=sáb, 64=dom.';
COMMENT ON COLUMN capsula.mensaje_cifrado IS 'AES-256-GCM: nonce(12) || cifrado || tag(16). La llave vive fuera de la BD.';

COMMIT;
