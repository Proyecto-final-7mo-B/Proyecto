"""Kaizen · poblador de la base LOCAL.

Llena la base de desarrollo con datos sintéticos que respetan las reglas de la base
(fragmentos por región, triggers de rachas y validación, Escalera, consentimiento de
señales y cápsulas cifradas). Usa las MISMAS convenciones que debe seguir la API:

* Correo en el directorio: HMAC-SHA256(KAIZEN_EMAIL_HMAC_KEY, correo.strip().lower()) en hex.
* Contraseña: Argon2id (argon2-cffi, parámetros por defecto).
* Cápsula: AES-256-GCM con KAIZEN_CAPSULA_KEY_V1; se guarda nonce(12) || cifrado || tag(16),
  con el id de la cápsula (16 bytes) como datos asociados (AAD). llave_version = 1.

Solo para desarrollo local: se niega a correr si KAIZEN_ENTORNO no es "local".
IA: asistido (Claude). Revisión pendiente: Jael Contreras / Jesus Vazquez.
"""

from __future__ import annotations

import argparse
import hashlib
import hmac
import os
import random
import sys
import uuid
from dataclasses import dataclass, field
from datetime import date, datetime, time, timedelta, timezone
from decimal import ROUND_HALF_UP, Decimal

import psycopg
from argon2 import PasswordHasher
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# ---------------------------------------------------------------------------
# Catálogos
# ---------------------------------------------------------------------------
# Las 8 categorías las crea la estructura de la base (catálogo inicial); aquí solo se usan.
CATALOGO: dict[str, list[tuple[str, str, int]]] = {
    "Aprendizaje": [("Estudiar inglés", "minutos", 20), ("Practicar programación", "minutos", 45)],
    "Salud": [("Comer fruta", "porciones", 2), ("Tomar vitaminas", "tomas", 1)],
    "Ejercicio": [("Caminar", "minutos", 30), ("Correr", "km", 3), ("Hacer lagartijas", "repeticiones", 20)],
    "Sueño": [("Dormir 7 horas", "horas", 7)],
    "Finanzas": [("Ahorrar", "pesos", 50), ("Registrar gastos", "veces", 1)],
    "Hidratación": [("Tomar agua", "vasos", 8)],
    "Lectura": [("Leer", "páginas", 15)],
    "Meditación": [("Meditar", "minutos", 10)],
}
ESTADOS_NORTE = ["BCN", "SON", "CHH", "NLE", "JAL", "AGU", "GUA", "QUE", "SIN", "COA"]
ESTADOS_CENTRO_SUR = ["CMX", "MEX", "PUE", "VER", "OAX", "YUC", "HID", "MOR"]
PAISES_LATAM = ["CO", "AR", "CL", "PE", "EC", "UY", "GT", "CR"]
NOMBRES = ["Ana", "Luis", "María", "Carlos", "Sofía", "Jorge", "Valeria", "Diego", "Fernanda", "Miguel",
           "Camila", "José", "Regina", "Andrés", "Paula", "Emilio", "Ximena", "Raúl", "Daniela", "Iván"]
APELLIDOS = ["García", "Hernández", "López", "Martínez", "Pérez", "González", "Rodríguez", "Sánchez",
             "Ramírez", "Torres", "Flores", "Rivera", "Gómez", "Díaz", "Morales", "Ortiz"]
MENSAJES_CAPSULA = [
    "Si estás leyendo esto, lo lograste. Acuérdate de cómo te sentías el primer día.",
    "Tres semanas seguidas. Ya no es suerte, es costumbre. Sigue así.",
    "Prometiste no rendirte. Cumpliste. Date un gusto hoy.",
    "El yo de hace un mes estaría orgulloso. No sueltes la racha.",
]
IP_DOCUMENTACION = "203.0.113."      # TEST-NET-3 (RFC 5737): IPs de ejemplo, no reales


@dataclass
class Cuenta:
    email: str
    nombre: str
    pais: str
    estado: str | None
    rol: str = "usuario"
    constancia: float = 0.6          # probabilidad base de cumplir
    consiente_senales: bool = False
    dias_antiguedad: int = 60        # hace cuántos días se registró
    n_habitos: int = 3
    id: uuid.UUID = field(default_factory=uuid.uuid4)
    region: str = ""
    habitos: list[dict] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Utilidades criptográficas (mismas convenciones que la API)
# ---------------------------------------------------------------------------
def llave_hex(nombre: str) -> bytes:
    valor = os.environ.get(nombre, "")
    try:
        llave = bytes.fromhex(valor)
    except ValueError:
        sys.exit(f"{nombre} debe ser hexadecimal (64 caracteres)")
    if len(llave) != 32:
        sys.exit(f"{nombre} debe medir 32 bytes (64 caracteres hex); mide {len(llave)}")
    return llave


def email_hmac(llave: bytes, email: str) -> str:
    return hmac.new(llave, email.strip().lower().encode(), hashlib.sha256).hexdigest()


def sellar_capsula(llave: bytes, capsula_id: uuid.UUID, mensaje: str) -> bytes:
    nonce = os.urandom(12)
    return nonce + AESGCM(llave).encrypt(nonce, mensaje.encode(), capsula_id.bytes)


def dinero(x: float) -> Decimal:
    return Decimal(str(x)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


# ---------------------------------------------------------------------------
# Generación
# ---------------------------------------------------------------------------
def cuentas_fijas(dias: int) -> list[Cuenta]:
    return [
        Cuenta("demo@kaizen.test", "Daniela Demo", "MX", "JAL", constancia=0.9,
               consiente_senales=True, dias_antiguedad=dias, n_habitos=4),
        Cuenta("admin@kaizen.test", "Admin Kaizen", "MX", "CMX", rol="admin", constancia=0.6,
               dias_antiguedad=dias, n_habitos=2),
        Cuenta("latam@kaizen.test", "Lucía Latam", "CO", None, constancia=0.75,
               consiente_senales=True, dias_antiguedad=dias, n_habitos=3),
        Cuenta("nuevo@kaizen.test", "Nico Nuevo", "MX", "PUE", constancia=0.5,
               dias_antiguedad=0, n_habitos=0),
        Cuenta("suspendido@kaizen.test", "Sergio Suspendido", "MX", "NLE", constancia=0.4,
               dias_antiguedad=dias // 2, n_habitos=2),
    ]


def cuentas_sinteticas(n: int, dias: int, rnd: random.Random) -> list[Cuenta]:
    cuentas = []
    for i in range(1, n + 1):
        r = rnd.random()
        if r < 0.35:
            pais, estado = "MX", rnd.choice(ESTADOS_NORTE)
        elif r < 0.90:
            pais, estado = "MX", rnd.choice(ESTADOS_CENTRO_SUR)
        else:
            pais, estado = rnd.choice(PAISES_LATAM), None
        cuentas.append(Cuenta(
            email=f"usuario{i:03d}@kaizen.test",
            nombre=f"{rnd.choice(NOMBRES)} {rnd.choice(APELLIDOS)}",
            pais=pais, estado=estado,
            constancia=rnd.betavariate(2.5, 1.8),          # la mayoría constante, algunos no
            consiente_senales=rnd.random() < 0.6,
            dias_antiguedad=rnd.randint(max(dias // 3, 15), dias),
            n_habitos=rnd.choices([1, 2, 3, 4, 5], weights=[2, 4, 4, 2, 1])[0],
        ))
    return cuentas


def es_programado(h: dict, d: date, rnd: random.Random) -> bool:
    if h["frecuencia_tipo"] == "diaria":
        return True
    if h["frecuencia_tipo"] == "dias_semana":
        return bool(h["dias_semana"] & (1 << d.weekday()))       # lunes = bit 0, igual que en SQL
    return rnd.random() < h["veces_semana"] / 7                   # n_por_semana: días libres


def momento(d: date, rnd: random.Random) -> datetime:
    return datetime.combine(d, time(rnd.randint(6, 22), rnd.randint(0, 59)), tzinfo=timezone.utc)


def main() -> None:
    ap = argparse.ArgumentParser(description="Pobla la base LOCAL de Kaizen con datos sintéticos.")
    ap.add_argument("--usuarios", type=int, default=40, help="usuarios sintéticos además de las 4 cuentas fijas")
    ap.add_argument("--dias", type=int, default=90, help="días de historial (mínimo 30)")
    ap.add_argument("--semilla", type=int, default=2026, help="semilla: misma semilla = mismos datos")
    args = ap.parse_args()
    if args.dias < 30:
        sys.exit("--dias debe ser al menos 30 (la Escalera necesita 14 días de historial)")

    if os.environ.get("KAIZEN_ENTORNO") != "local":
        sys.exit("Este script solo corre en el entorno local (KAIZEN_ENTORNO=local). Nunca contra el clúster.")

    llave_hmac = llave_hex("KAIZEN_EMAIL_HMAC_KEY")
    llave_capsula = llave_hex("KAIZEN_CAPSULA_KEY_V1")
    password = os.environ.get("KAIZEN_DEMO_PASSWORD") or sys.exit("Falta KAIZEN_DEMO_PASSWORD")
    rnd = random.Random(args.semilla)

    conninfo = dict(host=os.environ.get("PGHOST", "localhost"), port=os.environ.get("PGPORT", "5432"),
                    dbname="kaizen", user=os.environ.get("POSTGRES_USER", "postgres"),
                    password=os.environ.get("POSTGRES_PASSWORD"), application_name="kaizen-poblador")

    with psycopg.connect(**conninfo) as conn:
        cur = conn.cursor()
        cur.execute("SET search_path = kaizen, pg_temp")
        if cur.execute("SELECT count(*) FROM usuario").fetchone()[0]:
            sys.exit("La base ya tiene usuarios. Para empezar de cero: docker compose down -v && docker compose up -d")
        hoy: date = cur.execute("SELECT current_date").fetchone()[0]      # la fecha del servidor (UTC)

        # --- Categorías (las crea la estructura; se comprueba que estén) -------
        categorias = dict(cur.execute("SELECT nombre, id FROM categoria WHERE activa").fetchall())
        faltan = set(CATALOGO) - set(categorias)
        if faltan:
            sys.exit(f"Faltan categorías en la base: {', '.join(sorted(faltan))}. ¿Se cargó la estructura nueva?")

        # --- Usuarios y directorio -----------------------------------------
        cuentas = cuentas_fijas(args.dias) + cuentas_sinteticas(args.usuarios, args.dias, rnd)
        ph = PasswordHasher()
        hash_compartido = ph.hash(password)       # los sintéticos comparten hash (Argon2 es lento a propósito)
        print(f"Creando {len(cuentas)} usuarios…")
        for i, c in enumerate(cuentas):
            c.region = cur.execute("SELECT fn_region(%s, %s)", (c.pais, c.estado)).fetchone()[0]
            alta = momento(hoy - timedelta(days=c.dias_antiguedad), rnd)
            if c.dias_antiguedad == 0:
                alta = datetime.now(timezone.utc)
            cur.execute(
                """INSERT INTO usuario (id, region, nombre, email, password_hash, pais, rol,
                                        fecha_registro, acepto_aviso_en, consentimiento_senales_en)
                   VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                (c.id, c.region, c.nombre, c.email.lower(), ph.hash(password) if i < 5 else hash_compartido,
                 c.pais, c.rol, alta, alta, alta if c.consiente_senales else None))
            cur.execute("INSERT INTO directorio_usuarios (email_hmac, usuario_id, region) VALUES (%s, %s, %s)",
                        (email_hmac(llave_hmac, c.email), c.id, c.region))
            cur.execute("SELECT fn_auditar(%s, %s, 'usuario.registro', NULL, 'exito', %s)",
                        (c.id, c.region, IP_DOCUMENTACION + str(rnd.randint(1, 254))))

        # --- Hábitos (el trigger crea su nivel 1 y su fila de racha) ---------
        for c in cuentas:
            opciones = [(cat, *h) for cat, hs in CATALOGO.items() for h in hs]
            rnd.shuffle(opciones)
            for k, (cat, nombre, unidad, meta) in enumerate(opciones[:c.n_habitos]):
                tipo = "diaria" if c.email == "demo@kaizen.test" and k == 0 else \
                    rnd.choices(["diaria", "dias_semana", "n_por_semana"], weights=[6, 3, 1])[0]
                antig = c.dias_antiguedad if k == 0 else rnd.randint(min(10, c.dias_antiguedad), c.dias_antiguedad)
                h = dict(id=uuid.uuid4(), categoria=cat, nombre=nombre, unidad=unidad, meta=meta,
                         frecuencia_tipo=tipo,
                         dias_semana=rnd.choice([0b0010101, 0b0011111, 0b1100000, 0b0101010])
                         if tipo == "dias_semana" else None,
                         veces_semana=rnd.randint(2, 5) if tipo == "n_por_semana" else None,
                         creado=momento(hoy - timedelta(days=antig), rnd),
                         # el último hábito de demo trae la Escalera apagada; ~15 % del resto también
                         escalera=not (c.email == "demo@kaizen.test" and k == c.n_habitos - 1)
                         and (c.email == "demo@kaizen.test" or rnd.random() > 0.15),
                         constancia=min(0.98, max(0.05, c.constancia + rnd.uniform(-0.15, 0.15))))
                c.habitos.append(h)
                cur.execute(
                    """INSERT INTO habito (id, region, usuario_id, categoria_id, nombre, frecuencia_tipo,
                                           dias_semana, veces_semana, meta, unidad, fecha_creacion, escalera_activa)
                       VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)""",
                    (h["id"], c.region, c.id, categorias[cat], nombre, tipo, h["dias_semana"],
                     h["veces_semana"], meta, unidad, h["creado"], h["escalera"]))

        # --- Check-ins: COPY a una tabla temporal y UN solo INSERT ------------
        # (el trigger de rachas es por sentencia: calcula cada hábito una sola vez)
        print("Generando check-ins…")
        cur.execute("CREATE TEMP TABLE tmp_registro (LIKE registro INCLUDING DEFAULTS) ON COMMIT DROP")
        n_reg = 0
        with cur.copy("COPY tmp_registro (id, region, habito_id, usuario_id, fecha, cumplido, valor, origen,"
                      " registrado_en) FROM STDIN") as copy:
            for c in cuentas:
                for k, h in enumerate(c.habitos):
                    inicio = h["creado"].date()
                    # demo: el primer hábito trae 25 días seguidos cumplidos (para probar la cápsula de 21)
                    racha_forzada = 25 if c.email == "demo@kaizen.test" and k == 0 else 0
                    for n in range((hoy - inicio).days + 1):
                        d = inicio + timedelta(days=n)
                        forzado = racha_forzada and (hoy - d).days <= racha_forzada and d < hoy
                        if not forzado:
                            if not es_programado(h, d, rnd):
                                continue
                            if rnd.random() > (0.4 if d == hoy else 0.88):   # días olvidados; hoy, a medias
                                continue
                        semana = (hoy - d).days // 7                          # rachas buenas y malas por semana
                        p = h["constancia"] + (0.1 if semana % 3 == 0 else -0.05)
                        cumplido = True if forzado else rnd.random() < p
                        valor = dinero(h["meta"] * (rnd.uniform(1.0, 1.3) if cumplido else rnd.uniform(0, 0.7)))
                        origen = rnd.choices(["manual", "rapido", "offline"], weights=[6, 3, 1])[0]
                        registrado = momento(d, rnd)
                        if registrado > datetime.now(timezone.utc):
                            registrado = datetime.now(timezone.utc)
                        copy.write_row((uuid.uuid4(), c.region, h["id"], c.id, d, cumplido, valor, origen,
                                        registrado))
                        n_reg += 1
        cur.execute("INSERT INTO registro SELECT * FROM tmp_registro")
        print(f"  {n_reg} check-ins")

        # --- Señales de ánimo y energía (solo con consentimiento) -------------
        filas = []
        for c in cuentas:
            if not c.consiente_senales:
                continue
            for n in range(c.dias_antiguedad + 1):
                d = hoy - timedelta(days=n)
                if rnd.random() < 0.7:
                    base = 2 + 2.5 * c.constancia
                    filas.append((c.region, c.id, d,
                                  max(1, min(5, round(rnd.gauss(base, 0.8)))),
                                  max(1, min(5, round(rnd.gauss(base - 0.3, 0.9))))))
        cur.executemany("INSERT INTO senal_diaria (region, usuario_id, fecha, animo, energia)"
                        " VALUES (%s, %s, %s, %s, %s)", filas)
        print(f"  {len(filas)} señales diarias")

        # --- Cápsulas (cifradas con AES-256-GCM) ------------------------------
        capsulas = []
        for c in cuentas:
            if not c.habitos:
                continue
            if c.email == "demo@kaizen.test":
                elegidas = [(c.habitos[0], 21, hoy - timedelta(days=30)),          # ya se puede abrir
                            (c.habitos[0], 66, hoy - timedelta(days=30))]          # todavía no
            elif c.email == "latam@kaizen.test" or rnd.random() < 0.3:
                h = rnd.choice(c.habitos)
                elegidas = [(h, rnd.choice([7, 21, 66]), h["creado"].date() + timedelta(days=rnd.randint(0, 5)))]
            else:
                elegidas = []
            for h, objetivo, creada in elegidas:
                cid = uuid.uuid4()
                capsulas.append((c, cid))
                cur.execute(
                    """INSERT INTO capsula (id, region, habito_id, usuario_id, mensaje_cifrado, llave_version,
                                            racha_objetivo, creada_en)
                       VALUES (%s, %s, %s, %s, %s, 1, %s, %s)""",
                    (cid, c.region, h["id"], c.id, sellar_capsula(llave_capsula, cid, rnd.choice(MENSAJES_CAPSULA)),
                     objetivo, momento(creada, rnd)))
        # Abrir las que ya cumplieron, salvo las de demo (para probar la apertura desde la API)
        abiertas = 0
        for c, cid in capsulas:
            if c.email == "demo@kaizen.test":
                continue
            try:
                with conn.transaction():
                    cur.execute("CALL sp_abrir_capsula(%s, %s, %s, NULL, NULL)", (c.region, c.id, cid))
                abiertas += 1
            except psycopg.Error as e:
                if e.sqlstate != "KZ005":           # KZ005 = racha insuficiente: se queda sellada
                    raise
        print(f"  {len(capsulas)} cápsulas ({abiertas} abiertas)")

        # --- Escalera: sugerencias y respuestas -------------------------------
        creadas = cur.execute("CALL sp_generar_sugerencias(NULL, current_date, NULL)").fetchone()[0]
        pendientes = cur.execute(
            """SELECT s.region, h.usuario_id, s.id FROM sugerencia_ajuste s
                 JOIN habito h ON h.region = s.region AND h.id = s.habito_id
                 JOIN usuario u ON u.region = h.region AND u.id = h.usuario_id
                WHERE s.estado = 'pendiente' AND u.email NOT IN ('demo@kaizen.test', 'latam@kaizen.test')
                ORDER BY s.id""").fetchall()
        resueltas = 0
        for region, usuario_id, sid in pendientes:
            if rnd.random() < 0.4:
                cur.execute("CALL sp_responder_sugerencia(%s, %s, %s, %s)",
                            (region, usuario_id, sid, rnd.random() < 0.7))
                resueltas += 1
        print(f"  {creadas} sugerencias de la Escalera ({resueltas} respondidas)")

        # --- Bitácora: inicios de sesión de ejemplo ---------------------------
        filas = []
        for c in cuentas:
            for _ in range(rnd.randint(1, 6)):
                d = hoy - timedelta(days=rnd.randint(0, c.dias_antiguedad))
                ok = rnd.random() < 0.9
                filas.append((min(momento(d, rnd), datetime.now(timezone.utc)), c.id, c.region, "auth.login",
                              "exito" if ok else "fallo", IP_DOCUMENTACION + str(rnd.randint(1, 254))))
        cur.executemany("INSERT INTO bitacora_auditoria (fecha, usuario_id, region, accion, resultado, ip)"
                        " VALUES (%s, %s, %s, %s, %s, %s)", filas)

        # --- Cuenta suspendida por el admin (B5) --------------------------------
        cur.execute("CALL sp_admin_suspender_usuario(%s, %s, true, %s, NULL)",
                    (cuentas[1].id, cuentas[4].id, "Cuenta de prueba suspendida"))

        corregidas = cur.execute("CALL sp_reconstruir_rachas(NULL, NULL)").fetchone()[0]
        if corregidas:
            sys.exit(f"ERROR: {corregidas} rachas no coinciden con el recálculo; revisar los triggers")
        cur.execute("ANALYZE")
        conn.commit()

        # --- Resumen -----------------------------------------------------------
        print("\nFilas por tabla y región:")
        for fila in cur.execute(
                """SELECT t, coalesce(region, '-'), n FROM (
                     SELECT 'usuario' t, region, count(*) n FROM usuario GROUP BY 2 UNION ALL
                     SELECT 'habito', region, count(*) FROM habito GROUP BY 2 UNION ALL
                     SELECT 'registro', region, count(*) FROM registro GROUP BY 2 UNION ALL
                     SELECT 'senal_diaria', region, count(*) FROM senal_diaria GROUP BY 2 UNION ALL
                     SELECT 'capsula', region, count(*) FROM capsula GROUP BY 2 UNION ALL
                     SELECT 'sugerencia_ajuste', region, count(*) FROM sugerencia_ajuste GROUP BY 2) x
                   ORDER BY 1, 2"""):
            print(f"  {fila[0]:<18} {fila[1]:<14} {fila[2]:>7}")

    # --- Prueba como la API: kaizen_api + RLS ---------------------------------
    demo = cuentas[0]
    with psycopg.connect(**{**conninfo, "user": "kaizen_api", "password": os.environ.get("KAIZEN_DB_PASSWORD")}) as api:
        api.execute("SET search_path = kaizen")
        fila = api.execute("SELECT usuario_id, region FROM directorio_usuarios WHERE email_hmac = %s",
                           (email_hmac(llave_hmac, "Demo@Kaizen.test "),)).fetchone()
        assert fila and fila[0] == demo.id, "el directorio no encontró a demo por su HMAC"
        sin_usuario = api.execute("SELECT count(*) FROM habito").fetchone()[0]
        with api.transaction():
            api.execute("SELECT set_config('kaizen.usuario_id', %s, true)", (str(demo.id),))
            con_usuario = api.execute("SELECT count(*) FROM habito").fetchone()[0]
        print(f"\nComprobación como kaizen_api: directorio por HMAC OK · hábitos visibles sin set_config = "
              f"{sin_usuario} (RLS falla cerrada) · con el usuario demo = {con_usuario}")

    print(f"""
Listo. Cuentas de prueba (contraseña: la de KAIZEN_DEMO_PASSWORD en .env):
  demo@kaizen.test    {cuentas[0].region:<14} 4 hábitos (uno con la Escalera apagada), racha de 25 días,
                                     cápsula de 21 lista para abrir, señales
  admin@kaizen.test   {cuentas[1].region:<14} rol admin
  latam@kaizen.test   {cuentas[2].region:<14} región LATAM, con sugerencias pendientes
  nuevo@kaizen.test   {cuentas[3].region:<14} recién registrado, sin hábitos
  suspendido@kaizen.test {cuentas[4].region:<11} suspendido por el admin: el login debe rechazarlo
  usuario001…{args.usuarios:03d}@kaizen.test  usuarios sintéticos en las 3 regiones""")


if __name__ == "__main__":
    main()
