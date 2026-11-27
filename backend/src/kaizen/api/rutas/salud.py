"""GET /salud: ¿la API está viva y alcanza la base de datos?"""

from fastapi import APIRouter, Request, Response

router = APIRouter(tags=["salud"])


@router.get("/salud")
def salud(request: Request, response: Response) -> dict[str, str]:
    base_ok: bool = request.app.state.revisar_base()
    if not base_ok:
        response.status_code = 503
    return {
        "estado": "ok" if base_ok else "degradado",
        "base_de_datos": "ok" if base_ok else "sin conexion",
    }
