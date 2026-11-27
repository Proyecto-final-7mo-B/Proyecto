"""Configuración leída de variables de entorno (KAIZEN_*) o del archivo .env.

En local, .env es una copia del del entorno de Jael (llaves de DESARROLLO).
En producción las mismas variables vienen de /etc/kaizen/api.env en nodo1.
El .env nunca se sube a Git (.gitignore).
"""

from pydantic import SecretStr
from pydantic_settings import BaseSettings, SettingsConfigDict

CONNINFO_LOCAL = (
    "host=localhost port=5432 dbname=kaizen user=kaizen_api "
    "application_name=kaizen-api options='-c search_path=kaizen'"
)


class Configuracion(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="KAIZEN_", env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    db_conninfo: str = CONNINFO_LOCAL  # sin contraseña: va aparte
    db_password: SecretStr
    db_pool_max: int = 10
    email_hmac_key: SecretStr
    capsula_key_v1: SecretStr
    jwt_llave_privada: SecretStr
    jwt_kid: str
    zona_horaria_defecto: str = "America/Mexico_City"
