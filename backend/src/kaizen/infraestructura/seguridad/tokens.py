"""Tokens JWT firmados con Ed25519 (EdDSA), contrato v1.4 §2.1.

- Acceso (15 min): sub, region, rol, jti, sid, iat, exp, typ="acceso".
- Renovación (7 días): sub, region, jti (= sesion.jti), fam, iat, exp, typ="renovacion".
La llave privada firma; la pública (derivada) verifica. El kid va en la cabecera para poder rotarla.
"""

import base64
import uuid
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

import jwt
from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey

from kaizen.dominio.excepciones import TokenInvalido

VIDA_ACCESO = timedelta(minutes=15)
VIDA_RENOVACION = timedelta(days=7)
ALGORITMO = "EdDSA"


@dataclass(frozen=True, slots=True)
class ParTokens:
    """Lo que se entrega al iniciar sesión, más los datos para guardar la fila de sesion."""

    acceso: str
    renovacion: str
    jti_sesion: uuid.UUID  # = sesion.jti = claim sid del acceso
    familia: uuid.UUID
    expira_renovacion: datetime
    expira_en: int  # segundos de vida del token de acceso


class EmisorTokens:
    """Firma y verifica los JWT de Kaizen."""

    def __init__(self, llave_privada_b64: str, kid: str) -> None:
        self._privada = Ed25519PrivateKey.from_private_bytes(base64.b64decode(llave_privada_b64))
        self._publica = self._privada.public_key()
        self._kid = kid

    def _firmar(self, claims: dict[str, Any]) -> str:
        return jwt.encode(claims, self._privada, algorithm=ALGORITMO, headers={"kid": self._kid})

    def emitir_par(
        self,
        usuario_id: uuid.UUID,
        region: str,
        rol: str,
        familia: uuid.UUID | None = None,
        ahora: datetime | None = None,
    ) -> ParTokens:
        """Emite acceso + renovación. Sin familia es un login nuevo; con familia, una rotación."""
        ahora = ahora or datetime.now(UTC)
        familia = familia or uuid.uuid4()
        jti_sesion = uuid.uuid4()
        expira_renovacion = ahora + VIDA_RENOVACION
        base = {"sub": str(usuario_id), "region": region, "iat": ahora}
        acceso = self._firmar(
            base
            | {
                "rol": rol,
                "jti": str(uuid.uuid4()),
                "sid": str(jti_sesion),
                "exp": ahora + VIDA_ACCESO,
                "typ": "acceso",
            }
        )
        renovacion = self._firmar(
            base
            | {
                "jti": str(jti_sesion),
                "fam": str(familia),
                "exp": expira_renovacion,
                "typ": "renovacion",
            }
        )
        return ParTokens(
            acceso=acceso,
            renovacion=renovacion,
            jti_sesion=jti_sesion,
            familia=familia,
            expira_renovacion=expira_renovacion,
            expira_en=int(VIDA_ACCESO.total_seconds()),
        )

    def verificar(self, token: str, tipo: str) -> dict[str, Any]:
        """Regresa los claims si el token es válido y del tipo esperado; si no, TokenInvalido."""
        try:
            claims: dict[str, Any] = jwt.decode(
                token,
                self._publica,
                algorithms=[ALGORITMO],  # fijo: evita el ataque de cambiar el algoritmo
                options={"require": ["sub", "region", "jti", "iat", "exp", "typ"]},
            )
        except jwt.PyJWTError as error:
            raise TokenInvalido("Token inválido o vencido") from error
        if claims["typ"] != tipo:
            raise TokenInvalido(f"Se esperaba un token de {tipo}")
        return claims
