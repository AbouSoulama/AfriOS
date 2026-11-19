import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.database import init_db
from app.routers import ai, app_release, auth, business, clients, dashboard, invoices, jobs, payments, products, reminders, sync
from app.services.plan_limits import PlanLimitError


logger = logging.getLogger("afrios")


def _warn_unsafe_config() -> None:
    """Avertit (sans bloquer le démarrage) si la config ressemble à du développement."""
    if settings.otp_dev_mode:
        logger.warning(
            "OTP_DEV_MODE=true : le code OTP est renvoyé dans la réponse API. "
            "À désactiver en production, sinon n'importe qui peut se connecter avec n'importe quel numéro."
        )
    if settings.jwt_secret in {"", "dev-secret"} or len(settings.jwt_secret) < 32:
        logger.warning("JWT_SECRET faible ou par défaut : utilise une valeur aléatoire d'au moins 32 caractères.")
    if settings.jobs_cron_secret in {"", "dev-cron-secret"}:
        logger.warning("JOBS_CRON_SECRET par défaut : change-le avant d'exposer /v1/jobs.")
    if settings.cors_origins == ["*"]:
        logger.warning("CORS_ORIGINS=* : restreins aux origines réelles (site web) en production.")


@asynccontextmanager
async def lifespan(app: FastAPI):
    _warn_unsafe_config()
    await init_db()
    yield


app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



@app.exception_handler(PlanLimitError)
async def plan_limit_handler(_request: Request, exc: PlanLimitError):
    return JSONResponse(status_code=402, content={"detail": exc.message, "code": "plan_limit"})


prefix = settings.api_prefix

app.include_router(auth.router, prefix=prefix)
app.include_router(business.router, prefix=prefix)
app.include_router(clients.router, prefix=prefix)
app.include_router(products.router, prefix=prefix)
app.include_router(invoices.router, prefix=prefix)
app.include_router(payments.router, prefix=prefix)
app.include_router(dashboard.router, prefix=prefix)
app.include_router(ai.router, prefix=prefix)
app.include_router(reminders.router, prefix=prefix)
app.include_router(sync.router, prefix=prefix)
app.include_router(jobs.router, prefix=prefix)
app.include_router(app_release.router, prefix=prefix)


@app.get("/health")
async def health():
    return {"status": "ok", "app": settings.app_name, "version": settings.app_version}
