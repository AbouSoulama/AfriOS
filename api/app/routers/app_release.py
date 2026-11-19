"""Version / téléchargement de l'application Android."""

from fastapi import APIRouter

from app.config import settings

router = APIRouter(prefix="/app", tags=["app"])


@router.get("/latest")
async def latest_app_release():
    """Infos de la dernière APK — utilisées par le site et le check update in-app."""
    return {
        "platform": "android",
        "version_name": settings.mobile_version_name,
        "version_code": settings.mobile_version_code,
        "apk_url": settings.mobile_apk_url,
        "release_notes": settings.mobile_release_notes,
        "force_update": False,
    }
