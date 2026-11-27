"""Kaizen · generador de datos sintéticos para el clúster.

Genera un script SQL que puebla la base `kaizen` con personas inventadas (ningún dato real) repartidas casi en
tercios entre las 3 regiones (MX-NORTE, MX-CENTRO-SUR, LATAM), hasta llegar al número de check-ins pedido
(100 000 por omisión). El script respeta las reglas de la base: región calculada como fn_region, triggers de
rachas y validación, Escalera, consentimiento de señales y cápsulas cifradas.

Usa las MISMAS convenciones que la API, para que los usuarios sintéticos puedan iniciar sesión:
* Correo en el directorio: HMAC-SHA256(KAIZEN_EMAIL_HMAC_KEY, correo.strip().lower()) en hex.
* Contraseña: Argon2id (argon2-cffi, parámetros por defecto).
* Cápsula: AES-256-GCM con KAIZEN_CAPSULA_KEY_V1; nonce(12) || cifrado || tag(16), AAD = id de la cápsula.

El script se genera en la laptop y se carga en el PRIMARIO con cargar.sh. Las llaves solo se leen aquí: en el
SQL quedan huellas, hashes y textos cifrados, nunca las llaves ni la contraseña.

Uso:
    python generar.py --llaves ../../../ssh/kaizen_api/api.env --password-archivo ../../../ssh/kaizen_api/sinteticos.pass

IA: asistido (Claude). Revisión: Jael Contreras.
"""

from __future__ import annotations

import argparse
import hashlib
import hmac
import os
import random
import sys
import unicodedata
import uuid
from collections import Counter
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta, timezone
from decimal import ROUND_HALF_UP, Decimal
from pathlib import Path

from argon2 import PasswordHasher
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# ---------------------------------------------------------------------------
# Catálogos. Las subcategorías, sus unidades y sus rangos científicos los crea la estructura de la base
# (db/cambios/2026-11-27_evidencia_cientifica.sql); aquí solo se usan por clave. Las metas cubren todas las
# zonas de la evidencia (bajo, óptimo, alto y algunas excesivas a propósito) para que la Escalera v2 y el
# panel de indicadores tengan qué mostrar.
# ---------------------------------------------------------------------------
CATALOGO: dict[str, list[tuple[str, str, list[float]]]] = {
    "aerobico_moderado": [("Caminar", "min", [20, 30, 45]), ("Andar en bici", "min", [30, 45, 120]),
                          ("Correr", "km", [3, 5])],
    "vigoroso": [("Correr a buen ritmo", "min", [20, 30, 60])],
    "fuerza": [("Hacer lagartijas", "repeticiones", [20, 30]), ("Entrenar fuerza", "min", [10, 20])],
    "pasos": [("Caminar más pasos", "pasos", [6000, 8000, 10000])],
    "estiramiento": [("Estiramientos", "min", [5, 10])],
    "pausas_activas": [("Pausas activas", "pausas", [4, 8])],
    "hidratacion": [("Tomar agua", "vasos", [6, 8, 10]), ("Tomar agua", "L", [2, 2.5, 5])],
    "sueno": [("Dormir bien", "h", [6, 7, 8, 11])],
    "frutas_verduras": [("Comer fruta", "porciones", [2, 3]), ("Comer verduras", "porciones", [3, 5])],
    "reducir_azucar": [("Menos azúcar", "g", [25, 40, 60])],
    "reducir_alcohol": [("Menos alcohol", "bebidas", [1, 2])],
    "dejar_fumar": [("Fumar menos", "cigarros", [5, 10])],
    "lectura": [("Leer", "páginas", [10, 15, 20]), ("Leer", "min", [15, 30, 45])],
    "estudio": [("Repasar apuntes", "min", [30, 45, 300]), ("Practicar programación", "min", [45, 60])],
    "idiomas": [("Estudiar inglés", "min", [15, 20, 30])],
    "meditacion": [("Meditar", "min", [5, 10, 15, 60]), ("Respiración consciente", "min", [5])],
    "gratitud": [("Diario de gratitud", "registros", [1])],
    "reducir_pantallas": [("Menos redes sociales", "min", [60, 120])],
    "convivencia_social": [("Llamar a alguien querido", "veces", [1])],
    "aire_libre": [("Salir al parque", "min", [20, 30])],
    "ahorro": [("Ahorrar", "pesos", [50, 100])],
    "control_gastos": [("Registrar gastos", "registros", [1])],
}
REDUCIR = {"reducir_azucar", "reducir_alcohol", "dejar_fumar", "reducir_pantallas"}   # la meta es un límite
SEMANALES = {"gratitud", "convivencia_social", "aire_libre"}                            # mejor n por semana
# Casos fijos de la cuenta demo (presentación): óptimo con racha larga, excesivo, bajo y sueño
DEMO = [("aerobico_moderado", "Caminar", "min", 30), ("estudio", "Repasar apuntes", "min", 300),
        ("lectura", "Leer", "páginas", 15), ("sueno", "Dormir bien", "h", 7)]
INTENCIONES = ["Después de desayunar", "Después de lavarme los dientes", "Al llegar a casa", "Antes de dormir",
               "Después de comer", "Al despertar", "Después de la primera clase"]
# Mismas listas que fn_region (db/sql/02_funciones.sql); el SQL generado vuelve a comprobarlo.
REGIONES: dict[str, list[tuple[str, str | None]]] = {
    "MX-NORTE": [("MX", e) for e in ["BCN", "BCS", "SON", "CHH", "COA", "NLE", "TAM", "SIN", "DUR",
                                      "ZAC", "SLP", "NAY", "JAL", "COL", "AGU", "GUA", "QUE", "MIC"]],
    "MX-CENTRO-SUR": [("MX", e) for e in ["CMX", "MEX", "HID", "MOR", "TLA", "PUE", "VER", "GRO",
                                           "OAX", "CHP", "TAB", "CAM", "YUC", "ROO"]],
    "LATAM": [(p, None) for p in ["AR", "BO", "BR", "CL", "CO", "CR", "CU", "DO", "EC", "SV", "GT", "HN",
                                   "NI", "PA", "PY", "PE", "PR", "UY", "VE"]],
}
NOMBRES = ["Ana", "Luis", "María", "Carlos", "Sofía", "Jorge", "Valeria", "Diego", "Fernanda", "Miguel",
           "Camila", "José", "Regina", "Andrés", "Paula", "Emilio", "Ximena", "Raúl", "Daniela", "Iván",
           "Lucía", "Mateo", "Renata", "Santiago", "Mariana", "Sebastián", "Natalia", "Gabriel", "Isabela",
           "Rodrigo", "Andrea", "Héctor", "Julieta", "Tomás", "Carolina", "Adrián", "Elena", "Bruno",
           "Victoria", "Fernando", "Alejandra", "Pablo", "Montserrat", "Ricardo", "Guadalupe", "Óscar"]
APELLIDOS = ["García", "Hernández", "López", "Martínez", "Pérez", "González", "Rodríguez", "Sánchez",
             "Ramírez", "Torres", "Flores", "Rivera", "Gómez", "Díaz", "Morales", "Ortiz", "Vargas", "Castillo",
             "Jiménez", "Ruiz", "Mendoza", "Aguilar", "Medina", "Chávez", "Rojas", "Guerrero", "Delgado",
             "Silva", "Navarro", "Cruz", "Romero", "Herrera", "Peña", "Ríos", "Vega", "Domínguez"]
MENSAJES_CAPSULA = [
    "Si estás leyendo esto, lo lograste. Acuérdate de cómo te sentías el primer día.",
    "Tres semanas seguidas. Ya no es suerte, es costumbre. Sigue así.",
    "Prometiste no rendirte. Cumpliste. Date un gusto hoy.",
    "El yo de hace un mes estaría orgulloso. No sueltes la racha.",
    "Empezaste con poco y mira hasta dónde llegaste. Lo pequeño, todos los días, suma.",
    "Hoy no tienes que ser perfecto, solo constante. Gracias por no soltarlo.",
]
IP_DOCUMENTACION = "203.0.113."      # TEST-NET-3 (RFC 5737): IPs de ejemplo, no reales
DOMINIO = "kaizen.test"              # dominio reservado (RFC 2606): ningún correo es real
ORIGENES = (["manual", "rapido", "offline"], [6, 3, 1])


@dataclass
class Cuenta:
    email: str
    nombre: str
    pais: str
    estado: str | None
    region: str
    rol: str = "usuario"
    constancia: float = 0.6          # probabilidad base de cumplir
    consiente_senales: bool = False
    dias_antiguedad: int = 60        # hace cuántos días se registró
    n_habitos: int = 3
    id: uuid.UUID | None = None
    alta: datetime | None = None
    habitos: list[dict] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Utilidades
# ---------------------------------------------------------------------------
def leer_llaves(ruta: Path) -> dict[str, bytes]:
    """Lee SOLO las dos llaves que se necesitan del archivo .env (formato CLAVE=valor)."""
    buscadas = {"KAIZEN_EMAIL_HMAC_KEY", "KAIZEN_CAPSULA_KEY_V1"}
    llaves: dict[str, bytes] = {}
    for linea in ruta.read_text(encoding="utf-8").splitlines():
        clave, _, valor = linea.strip().partition("=")
        if clave in buscadas:
            valor = valor.strip().strip('"').strip("'")
            try:
                llave = bytes.fromhex(valor)
            except ValueError:
                sys.exit(f"{clave} no está en hexadecimal")
            if len(llave) != 32:
                sys.exit(f"{clave} debe ser de 32 bytes (64 caracteres hex)")
            llaves[clave] = llave
    faltan = buscadas - llaves.keys()
    if faltan:
        sys.exit(f"Faltan en {ruta}: {', '.join(sorted(faltan))}")
    return llaves


def email_hmac(llave: bytes, email: str) -> str:
    return hmac.new(llave, email.strip().lower().encode(), hashlib.sha256).hexdigest()


def sellar_capsula(llave: bytes, capsula_id: uuid.UUID, mensaje: str) -> bytes:
    nonce = os.urandom(12)
    return nonce + AESGCM(llave).encrypt(nonce, mensaje.encode(), capsula_id.bytes)


def dinero(x: float) -> Decimal:
    return Decimal(str(x)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def sin_acentos(texto: str) -> str:
    return unicodedata.normalize("NFKD", texto).encode("ascii", "ignore").decode().lower()


def copy_valor(v: object) -> str:
    """Un valor en el formato de texto de COPY."""
    if v is None:
        return r"\N"
    if isinstance(v, bool):
        return "t" if v else "f"
    if isinstance(v, bytes):
        return r"\\x" + v.hex()
    if isinstance(v, datetime):
        return v.isoformat()
    s = str(v)
    if any(c in s for c in "\t\n\r\\"):
        raise ValueError(f"valor con caracteres de control: {s!r}")
    return s


class Generador:
    def __init__(self, semilla: int, hoy: date, ahora: datetime, dias: int, llaves: dict[str, bytes]):
        self.rnd = random.Random(semilla)
        self.hoy = hoy
        self.ahora = ahora
        self.dias = dias
        self.llave_hmac = llaves["KAIZEN_EMAIL_HMAC_KEY"]
        self.llave_capsula = llaves["KAIZEN_CAPSULA_KEY_V1"]
        self.cuentas: list[Cuenta] = []
        self.registros: list[tuple] = []
        self.correos: Counter[str] = Counter()

    # -- identificadores reproducibles: misma semilla = mismos ids --------------------------------
    def nuevo_uuid(self) -> uuid.UUID:
        return uuid.UUID(int=self.rnd.getrandbits(128), version=4)

    def momento(self, d: date) -> datetime:
        m = datetime.combine(d, time(self.rnd.randint(6, 22), self.rnd.randint(0, 59)), tzinfo=timezone.utc)
        return min(m, self.ahora)

    # -- cuentas ------------------------------------------------------------------------------
    def cuentas_fijas(self) -> list[Cuenta]:
        d = self.dias
        return [
            Cuenta(f"demo@{DOMINIO}", "Daniela Demo", "MX", "JAL", "MX-NORTE", constancia=0.9,
                   consiente_senales=True, dias_antiguedad=d, n_habitos=4),
            Cuenta(f"admin@{DOMINIO}", "Admin Kaizen", "MX", "CMX", "MX-CENTRO-SUR", rol="admin", constancia=0.6,
                   dias_antiguedad=d, n_habitos=2),
            Cuenta(f"latam@{DOMINIO}", "Lucía Latam", "CO", None, "LATAM", constancia=0.75,
                   consiente_senales=True, dias_antiguedad=d, n_habitos=3),
            Cuenta(f"nuevo@{DOMINIO}", "Nico Nuevo", "MX", "PUE", "MX-CENTRO-SUR", constancia=0.5,
                   dias_antiguedad=0, n_habitos=0),
            Cuenta(f"suspendido@{DOMINIO}", "Sergio Suspendido", "MX", "NLE", "MX-NORTE", constancia=0.4,
                   dias_antiguedad=d // 2, n_habitos=2),
        ]

    def cuenta_sintetica(self, region: str) -> Cuenta:
        rnd = self.rnd
        pais, estado = rnd.choice(REGIONES[region])
        nombre, ap1, ap2 = rnd.choice(NOMBRES), rnd.choice(APELLIDOS), rnd.choice(APELLIDOS)
        base = f"{sin_acentos(nombre)}.{sin_acentos(ap1)}"
        self.correos[base] += 1
        return Cuenta(
            email=f"{base}{self.correos[base]}@{DOMINIO}",
            nombre=f"{nombre} {ap1} {ap2}",
            pais=pais, estado=estado, region=region,
            constancia=rnd.betavariate(2.5, 1.8),           # la mayoría constante, algunos no
            consiente_senales=rnd.random() < 0.6,
            dias_antiguedad=rnd.randint(max(self.dias // 3, 15), self.dias),
            n_habitos=rnd.choices([1, 2, 3, 4, 5], weights=[2, 4, 4, 2, 1])[0],
        )

    def agregar(self, c: Cuenta) -> int:
        """Da de alta la cuenta con sus hábitos y check-ins. Devuelve cuántos check-ins generó."""
        rnd = self.rnd
        c.id = self.nuevo_uuid()
        c.alta = self.ahora if c.dias_antiguedad == 0 else self.momento(self.hoy - timedelta(days=c.dias_antiguedad))
        es_demo = c.email == f"demo@{DOMINIO}"
        if es_demo:
            opciones = list(DEMO)
        else:
            opciones = [(sub, nombre, unidad, rnd.choice(metas)) for sub, hs in CATALOGO.items()
                        for nombre, unidad, metas in hs]
            rnd.shuffle(opciones)
        antes = len(self.registros)
        for k, (sub, nombre, unidad, meta) in enumerate(opciones[:c.n_habitos]):
            if es_demo:
                tipo = "diaria"
            elif sub in SEMANALES:
                tipo = "n_por_semana"
            else:
                tipo = rnd.choices(["diaria", "dias_semana", "n_por_semana"], weights=[6, 3, 1])[0]
            antig = c.dias_antiguedad if k == 0 else rnd.randint(min(10, c.dias_antiguedad), c.dias_antiguedad)
            creado = max(self.momento(self.hoy - timedelta(days=antig)), c.alta)
            h = dict(id=self.nuevo_uuid(), subcategoria=sub, nombre=nombre, unidad=unidad, meta=meta,
                     reducir=sub in REDUCIR,
                     prioridad=(1 if k == 0 else 2) if es_demo else rnd.choices([1, 2, 3], weights=[2, 5, 2])[0],
                     intencion=INTENCIONES[k] if es_demo else
                     (rnd.choice(INTENCIONES) if rnd.random() < 0.4 else None),
                     frecuencia_tipo=tipo,
                     dias_semana=rnd.choice([0b0010101, 0b0011111, 0b1100000, 0b0101010])
                     if tipo == "dias_semana" else None,
                     veces_semana=rnd.randint(2, 5) if tipo == "n_por_semana" else None,
                     creado=creado,
                     # el último hábito de demo trae la Escalera apagada; ~15 % del resto también
                     escalera=not (es_demo and k == c.n_habitos - 1) and (es_demo or rnd.random() > 0.15),
                     constancia=min(0.98, max(0.05, c.constancia + rnd.uniform(-0.15, 0.15))))
            c.habitos.append(h)
            # demo: racha larga en el hábito óptimo y 20 días seguidos en "Leer" (la Escalera propone subir)
            self.checkins(c, h, racha_forzada={0: 35, 2: 20}.get(k, 0) if es_demo else 0)
        self.cuentas.append(c)
        return len(self.registros) - antes

    def es_programado(self, h: dict, d: date) -> bool:
        if h["frecuencia_tipo"] == "diaria":
            return True
        if h["frecuencia_tipo"] == "dias_semana":
            return bool(h["dias_semana"] & (1 << d.weekday()))       # lunes = bit 0, igual que en SQL
        return self.rnd.random() < h["veces_semana"] / 7             # n_por_semana: días libres

    def checkins(self, c: Cuenta, h: dict, racha_forzada: int) -> None:
        rnd = self.rnd
        inicio = h["creado"].date()
        # algunos abandonan: dejan de registrar unos días antes de hoy (riesgo de abandono en F2)
        abandono = self.hoy - timedelta(days=rnd.randint(5, 30)) if h["constancia"] < 0.35 and rnd.random() < 0.5 \
            else None
        for n in range((self.hoy - inicio).days + 1):
            d = inicio + timedelta(days=n)
            forzado = racha_forzada and (self.hoy - d).days <= racha_forzada and d < self.hoy
            if not forzado:
                if abandono and d > abandono:
                    break
                if not self.es_programado(h, d):
                    continue
                if rnd.random() > (0.4 if d == self.hoy else 0.88):    # días olvidados; hoy, a medias
                    continue
            semana = (self.hoy - d).days // 7                           # rachas buenas y malas por semana
            p = h["constancia"] + (0.1 if semana % 3 == 0 else -0.05)
            cumplido = True if forzado else rnd.random() < p
            if h["reducir"]:      # límite: cumplir es quedarse por debajo
                valor = dinero(h["meta"] * (rnd.uniform(0.4, 1.0) if cumplido else rnd.uniform(1.05, 1.6)))
            else:
                valor = dinero(h["meta"] * (rnd.uniform(1.0, 1.3) if cumplido else rnd.uniform(0, 0.7)))
            origen = rnd.choices(*ORIGENES)[0]
            self.registros.append((self.nuevo_uuid(), c.region, h["id"], c.id, d, cumplido, valor, origen,
                                   self.momento(d)))


# ---------------------------------------------------------------------------
# Escritura del SQL
# ---------------------------------------------------------------------------
def bloque_copy(out, tabla: str, columnas: str, filas) -> int:
    n = 0
    out.write(f"COPY {tabla} ({columnas}) FROM STDIN;\n")
    for fila in filas:
        out.write("\t".join(copy_valor(v) for v in fila) + "\n")
        n += 1
    out.write("\\.\n\n")
    return n


def main() -> None:
    ap = argparse.ArgumentParser(description="Genera el SQL de datos sintéticos de Kaizen para el clúster.")
    ap.add_argument("--llaves", type=Path, required=True,
                    help="archivo .env con KAIZEN_EMAIL_HMAC_KEY y KAIZEN_CAPSULA_KEY_V1 (las de la API)")
    ap.add_argument("--password-archivo", type=Path, required=True,
                    help="archivo con la contraseña de todas las cuentas sintéticas (no se versiona)")
    ap.add_argument("--registros", type=int, default=100_000, help="check-ins mínimos a generar")
    ap.add_argument("--dias", type=int, default=120, help="días de historial (mínimo 30)")
    ap.add_argument("--semilla", type=int, default=2026, help="misma semilla = mismos datos")
    ap.add_argument("--salida", type=Path, default=Path(__file__).parent / "salida" / "carga_sintetica.sql")
    args = ap.parse_args()
    if args.dias < 30:
        sys.exit("--dias debe ser al menos 30")

    llaves = leer_llaves(args.llaves)
    password = args.password_archivo.read_text(encoding="utf-8").strip()
    if len(password) < 12:
        sys.exit("La contraseña de las cuentas sintéticas debe tener al menos 12 caracteres")

    ahora = datetime.now(timezone.utc).replace(microsecond=0)
    hoy = ahora.date()                                   # la base trabaja en UTC (current_date del servidor)
    g = Generador(args.semilla, hoy, ahora, args.dias, llaves)

    for c in g.cuentas_fijas():
        g.agregar(c)
    regiones = list(REGIONES)
    i = 0
    while len(g.registros) < args.registros:            # en tercios: una cuenta por región, por turnos
        g.agregar(g.cuenta_sintetica(regiones[i % 3]))
        i += 1

    rnd = g.rnd
    ph = PasswordHasher()
    hash_compartido = ph.hash(password)    # los sintéticos comparten hash (Argon2 es lento a propósito)
    fijas = {c.email for c in g.cuentas[:5]}

    args.salida.parent.mkdir(parents=True, exist_ok=True)
    with args.salida.open("w", encoding="utf-8") as out:
        out.write(f"""-- =====================================================================
-- Kaizen · carga de datos sintéticos (generada por db/sinteticos/generar.py)
-- Generada: {ahora.isoformat()} · semilla {args.semilla} · {args.dias} días · {len(g.cuentas)} cuentas
-- Personas inventadas: correos @{DOMINIO} (RFC 2606) e IPs 203.0.113.x (RFC 5737).
-- No contiene llaves ni contraseñas. Se carga en el PRIMARIO con cargar.sh, en UNA transacción.
-- =====================================================================
\\set ON_ERROR_STOP on
\\pset footer off
BEGIN;
SET LOCAL search_path = kaizen, pg_temp;
SET LOCAL TimeZone = 'UTC';              -- la base trabaja en UTC: current_date igual que en el generador

DO $$
BEGIN
    IF pg_is_in_recovery() THEN
        RAISE EXCEPTION 'Este nodo es una réplica: la carga va en el primario (sudo kpatronictl list)';
    END IF;
    IF current_date NOT BETWEEN date '{hoy}' AND date '{hoy}' + 1 THEN
        RAISE EXCEPTION 'El script se generó para el %; vuelve a generarlo hoy', date '{hoy}';
    END IF;
    IF EXISTS (SELECT 1 FROM usuario WHERE email LIKE '%@{DOMINIO}') THEN
        RAISE EXCEPTION 'Ya hay datos sintéticos (@{DOMINIO}); para recargar, primero corre limpiar.sql';
    END IF;
END $$;

\\echo '--- Usuarios'
CREATE TEMP TABLE t_usuario (id uuid, region region_t, nombre text, email text, password_hash text,
    pais char(2), estado text, rol text, alta timestamptz, consentimiento timestamptz) ON COMMIT DROP;
""")
        bloque_copy(out, "t_usuario", "id, region, nombre, email, password_hash, pais, estado, rol, alta, consentimiento",
                    ((c.id, c.region, c.nombre, c.email, ph.hash(password) if c.email in fijas else hash_compartido,
                      c.pais, c.estado, c.rol, c.alta, c.alta if c.consiente_senales else None) for c in g.cuentas))
        out.write("""DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM t_usuario WHERE fn_region(pais, estado) <> region) THEN
        RAISE EXCEPTION 'La región de algún usuario no coincide con fn_region';
    END IF;
END $$;
INSERT INTO usuario (id, region, nombre, email, password_hash, pais, rol, fecha_registro, acepto_aviso_en,
                     consentimiento_senales_en)
SELECT id, region, nombre, email, password_hash, pais, rol, alta, alta, consentimiento FROM t_usuario;

""")
        bloque_copy(out, "directorio_usuarios", "email_hmac, usuario_id, region",
                    ((email_hmac(g.llave_hmac, c.email), c.id, c.region) for c in g.cuentas))

        # Bitácora: altas e inicios de sesión de ejemplo (la bitácora es de solo inserción)
        bitacora = []
        for c in g.cuentas:
            bitacora.append((c.alta, c.id, c.region, "usuario.registro", "exito",
                             IP_DOCUMENTACION + str(rnd.randint(1, 254))))
            for _ in range(rnd.randint(1, 6)):
                d = g.hoy - timedelta(days=rnd.randint(0, c.dias_antiguedad))
                bitacora.append((max(g.momento(d), c.alta), c.id, c.region, "auth.login",
                                 "exito" if rnd.random() < 0.9 else "fallo",
                                 IP_DOCUMENTACION + str(rnd.randint(1, 254))))
        bloque_copy(out, "bitacora_auditoria", "fecha, usuario_id, region, accion, resultado, ip", bitacora)

        out.write("""\\echo '--- Hábitos (el trigger crea su nivel 1 y su racha)'
CREATE TEMP TABLE t_habito (id uuid, region region_t, usuario_id uuid, subcategoria text, nombre text,
    frecuencia_tipo text, dias_semana smallint, veces_semana smallint, meta numeric(10,2), unidad text,
    creado timestamptz, escalera boolean, prioridad smallint, intencion text) ON COMMIT DROP;
""")
        bloque_copy(out, "t_habito", "id, region, usuario_id, subcategoria, nombre, frecuencia_tipo, dias_semana, "
                    "veces_semana, meta, unidad, creado, escalera, prioridad, intencion",
                    ((h["id"], c.region, c.id, h["subcategoria"], h["nombre"], h["frecuencia_tipo"], h["dias_semana"],
                      h["veces_semana"], h["meta"], h["unidad"], h["creado"], h["escalera"], h["prioridad"],
                      h["intencion"])
                     for c in g.cuentas for h in c.habitos))
        out.write("""DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM t_habito t LEFT JOIN subcategoria s ON s.clave = t.subcategoria AND s.activa
                WHERE s.id IS NULL) THEN
        RAISE EXCEPTION 'Falta alguna subcategoría del catálogo: ¿se aplicaron los cambios del 27-nov?';
    END IF;
END $$;
-- La categoría la fija el trigger a partir de la subcategoría; la unidad debe estar permitida (KZ016)
INSERT INTO habito (id, region, usuario_id, subcategoria_id, nombre, frecuencia_tipo, dias_semana, veces_semana,
                    meta, unidad, fecha_creacion, escalera_activa, prioridad, intencion)
SELECT t.id, t.region, t.usuario_id, s.id, t.nombre, t.frecuencia_tipo, t.dias_semana, t.veces_semana,
       t.meta, t.unidad, t.creado, t.escalera, t.prioridad, t.intencion
  FROM t_habito t JOIN subcategoria s ON s.clave = t.subcategoria;

\\echo '--- Check-ins (UN solo INSERT: el trigger de rachas calcula cada hábito una vez)'
CREATE TEMP TABLE t_registro (LIKE registro INCLUDING DEFAULTS) ON COMMIT DROP;
""")
        bloque_copy(out, "t_registro", "id, region, habito_id, usuario_id, fecha, cumplido, valor, origen, "
                    "registrado_en", g.registros)
        out.write("INSERT INTO registro SELECT * FROM t_registro;\n\n\\echo '--- Señales de ánimo y energía'\n")

        senales = []
        for c in g.cuentas:
            if not c.consiente_senales:
                continue
            for n in range(c.dias_antiguedad + 1):
                if rnd.random() < 0.7:
                    base = 2 + 2.5 * c.constancia
                    senales.append((g.nuevo_uuid(), c.region, c.id, g.hoy - timedelta(days=n),
                                    max(1, min(5, round(rnd.gauss(base, 0.8)))),
                                    max(1, min(5, round(rnd.gauss(base - 0.3, 0.9))))))
        bloque_copy(out, "senal_diaria", "id, region, usuario_id, fecha, animo, energia", senales)

        out.write("\\echo '--- Cápsulas (cifradas con AES-256-GCM)'\n")
        capsulas = []
        for c in g.cuentas:
            if not c.habitos:
                continue
            if c.email == f"demo@{DOMINIO}":
                elegidas = [(c.habitos[0], 30, g.hoy - timedelta(days=34)),       # ya se puede abrir
                            (c.habitos[0], 66, g.hoy - timedelta(days=30))]       # todavía no
            elif c.email == f"latam@{DOMINIO}" or rnd.random() < 0.3:
                h = rnd.choice(c.habitos)
                elegidas = [(h, rnd.choice([7, 30, 66]), h["creado"].date() + timedelta(days=rnd.randint(0, 5)))]
            else:
                elegidas = []
            for h, objetivo, creada in elegidas:
                cid = g.nuevo_uuid()
                capsulas.append((cid, c.region, h["id"], c.id,
                                 sellar_capsula(g.llave_capsula, cid, rnd.choice(MENSAJES_CAPSULA)),
                                 1, objetivo, max(g.momento(creada), h["creado"])))
        bloque_copy(out, "capsula", "id, region, habito_id, usuario_id, mensaje_cifrado, llave_version, "
                    "racha_objetivo, creada_en", capsulas)

        out.write(f"""-- Se abren las que ya alcanzaron su racha, salvo las de demo (para probar la apertura desde la app)
DO $$
DECLARE r record; v_msg bytea; v_ver smallint; v_abiertas int := 0;
BEGIN
    FOR r IN SELECT c.region, c.usuario_id, c.id FROM capsula c JOIN usuario u ON u.region = c.region
                AND u.id = c.usuario_id
              WHERE u.email LIKE '%@{DOMINIO}' AND u.email <> 'demo@{DOMINIO}' ORDER BY c.id LOOP
        BEGIN
            CALL sp_abrir_capsula(r.region, r.usuario_id, r.id, v_msg, v_ver);
            v_abiertas := v_abiertas + 1;
        EXCEPTION WHEN SQLSTATE 'KZ005' THEN NULL;        -- racha insuficiente: se queda sellada
        END;
    END LOOP;
    RAISE NOTICE 'cápsulas abiertas: %', v_abiertas;
END $$;

\\echo '--- Escalera: sugerencias del día y algunas respuestas'
CALL sp_generar_sugerencias(NULL, current_date, NULL);
SELECT setseed({(args.semilla % 1000) / 1000});
DO $$
DECLARE r record; v_resueltas int := 0;
BEGIN
    FOR r IN SELECT s.region, h.usuario_id, s.id FROM sugerencia_ajuste s
               JOIN habito h ON h.region = s.region AND h.id = s.habito_id
               JOIN usuario u ON u.region = h.region AND u.id = h.usuario_id
              WHERE s.estado = 'pendiente' AND u.email LIKE '%@{DOMINIO}'
                AND u.email NOT IN ('demo@{DOMINIO}', 'latam@{DOMINIO}')
              ORDER BY s.id LOOP
        IF random() < 0.4 THEN
            CALL sp_responder_sugerencia(r.region, r.usuario_id, r.id, random() < 0.7);
            v_resueltas := v_resueltas + 1;
        END IF;
    END LOOP;
    RAISE NOTICE 'sugerencias respondidas: %', v_resueltas;
END $$;

\\echo '--- Logros semanales (Semana OMS, Ritmo ideal)'
CALL sp_otorgar_logros_semanales(current_date, NULL);

\\echo '--- Cuenta suspendida por el admin y comprobación de rachas'
CALL sp_admin_suspender_usuario('{g.cuentas[1].id}', '{g.cuentas[4].id}', true, 'Cuenta de prueba suspendida', NULL);
DO $$
DECLARE v int;
BEGIN
    CALL sp_reconstruir_rachas(NULL, v);
    IF v <> 0 THEN
        RAISE EXCEPTION '% rachas no coinciden con el recálculo: revisar los triggers', v;
    END IF;
END $$;

COMMIT;
ANALYZE kaizen.usuario, kaizen.directorio_usuarios, kaizen.habito, kaizen.registro, kaizen.racha,
        kaizen.nivel_habito, kaizen.senal_diaria, kaizen.capsula, kaizen.sugerencia_ajuste, kaizen.logro_usuario;

\\echo '--- Filas por tabla y región'
SELECT t AS tabla, region, n AS filas FROM (
    SELECT 'usuario' t, region::text, count(*) n FROM kaizen.usuario GROUP BY 2 UNION ALL
    SELECT 'habito', region::text, count(*) FROM kaizen.habito GROUP BY 2 UNION ALL
    SELECT 'registro', region::text, count(*) FROM kaizen.registro GROUP BY 2 UNION ALL
    SELECT 'senal_diaria', region::text, count(*) FROM kaizen.senal_diaria GROUP BY 2 UNION ALL
    SELECT 'capsula', region::text, count(*) FROM kaizen.capsula GROUP BY 2 UNION ALL
    SELECT 'sugerencia_ajuste', region::text, count(*) FROM kaizen.sugerencia_ajuste GROUP BY 2 UNION ALL
    SELECT 'logro_usuario', region::text, count(*) FROM kaizen.logro_usuario GROUP BY 2) x
ORDER BY 1, 2;

\\echo '--- Hábitos por zona de la evidencia'
SELECT zona, count(*) AS habitos FROM kaizen.v_habito_evidencia GROUP BY 1 ORDER BY 2 DESC;

\\echo '--- Comprobación como kaizen_api (directorio por HMAC y RLS)'
BEGIN;
SET LOCAL search_path = kaizen, pg_temp;
SET LOCAL ROLE kaizen_api;
SELECT (SELECT usuario_id FROM directorio_usuarios
         WHERE email_hmac = '{email_hmac(g.llave_hmac, " Demo@Kaizen.TEST ")}') = '{g.cuentas[0].id}'
       AS "directorio encuentra a demo por su HMAC",
       (SELECT count(*) FROM habito) AS "hábitos visibles sin usuario (RLS: 0)";
SELECT set_config('kaizen.usuario_id', '{g.cuentas[0].id}', true) \\g /dev/null
SELECT count(*) AS "hábitos visibles como demo" FROM habito;
ROLLBACK;
""")

    por_region = Counter(r[1] for r in g.registros)
    print(f"SQL generado: {args.salida} ({args.salida.stat().st_size / 1e6:.1f} MB)")
    print(f"  {len(g.cuentas)} cuentas · {sum(len(c.habitos) for c in g.cuentas)} hábitos · "
          f"{len(g.registros)} check-ins · {len(senales)} señales · {len(capsulas)} cápsulas · "
          f"{len(bitacora)} eventos de bitácora")
    for region in REGIONES:
        print(f"  {region:<14} {sum(1 for c in g.cuentas if c.region == region):>5} cuentas "
              f"{por_region[region]:>7} check-ins")


if __name__ == "__main__":
    main()
