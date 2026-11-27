"""Esquemas de /auth (contrato v1.4, §5 y §6.1)."""

from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

PATRON_CORREO = r"^[^@\s]+@[^@\s]+\.[^@\s]+$"  # el mismo CHECK que usuario.email


class Estricto(BaseModel):
    model_config = ConfigDict(extra="forbid")


class SolicitudLogin(Estricto):
    email: str = Field(max_length=254, pattern=PATRON_CORREO)
    contrasena: str = Field(min_length=1, max_length=128)


class UsuarioResumen(Estricto):
    id: UUID
    nombre: str
    rol: Literal["usuario", "admin"]
    region: str


class RespuestaTokens(Estricto):
    token_acceso: str
    token_renovacion: str
    tipo: Literal["Bearer"] = "Bearer"
    expira_en: int
    usuario: UsuarioResumen
